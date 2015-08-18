package mdDog::Doc;

use strict; no strict "subs";
use parent mdDog;
use Text::Markdown::MdDog qw/markdown paragraph_html paragraph_raw alter_paragraph paragraphs/;
use MYUTIL;
use SQL;

# @summary ドキュメント情報を取得してテンプレートにセット
#
sub set_document_info {
    my $self = shift;

    my $fid   = $self->qParam('fid');
    my $uid   = $self->{s}->param('login');
    my $user  = $self->qParam('user');
    my $ver   = $self->qParam('revision');
    return unless($fid);        # NULL CHECK
    my @logs  = $self->{git}->get_shared_logs();

    my $sth = $self->{dbh}->prepare(SQL::document_info);
    $sth->execute($fid);
    my $row = $sth->fetchrow_hashref();
    my $docinfo = {
        doc_name        => $row->{doc_name},
        file_name       => $row->{file_name},
        created_at      => MYUTIL::format_date2($row->{created_at}),
        created_by      => $row->{nic_name},
        file_size       => MYUTIL::num_unit(-s $self->{repodir} . "/${fid}/$row->{file_name}"),
        is_public       => $row->{is_public},
        is_owned        => $row->{created_by} == $self->{s}->param('login')?1:0,
        last_updated_at => ${logs}[0][0]->{attr}->{date},
    };

    do{
        push @{$docinfo->{groups}}, $row->{group_name}
            if( $row->{group_name} );
    }while( $row = $sth->fetchrow_hashref() );
    $sth->finish();

    if( $uid ){
        $docinfo->{is_approve}  = $self->{user}->{is_approve};
        $docinfo->{is_editable} = $self->{user}->{is_edit};
    }
    $docinfo->{fid}      = $fid;
    $docinfo->{user}     = $user;
    $docinfo->{revision} = $ver if($ver);

    $self->{t} = {%{$self->{t}}, %$docinfo};
}

# @summary ドキュメントのログを取得
#
sub set_document_log(){
    my $self    = shift;
    my $gitctrl = $self->{git};
    my $tmpl    = $self->{t};

    #共有リポジトリ(master)
    $tmpl->{sharedlist} = $gitctrl->get_shared_logs();
}


# @summary ユーザーのバッファの状態を取得してテンプレートにセット
#
sub set_buffer_info {
    my $self    = shift;
    my $fid     = $self->qParam('fid');
    my $uid     = $self->{s}->param("login");
    my $gitctrl = $self->{git};

    return 0 unless( $fid && $uid );

    # check whether current repository has been older than master
    my $shared_logs = $gitctrl->get_shared_logs('raw');
    my $latest_rev;
    if( $shared_logs ){
        $latest_rev = $shared_logs->[0]->{id};
    }
    if($gitctrl->is_exist_user_branch($uid)){
        my $user_root = $gitctrl->get_branch_root($uid);
        $self->{t}->{is_live} = $latest_rev =~ m/^${user_root}[0-9a-z]+/ ?1:0;
    }else{
        $self->{t}->{is_live} = 1;
    }

    # check exist of temporary buffer
    if($self->{git}->is_exist_user_branch($uid, {tmp=>1})
      && $self->{git}->is_updated_buffer($uid)){
        push @{$self->{t}->{message}->{buffered}}, "Buffered";
    }
}

# @summary MDドキュメントの編集バッファをフィックスする
# query1: login
# query2: fid
# query3: comment
#
sub fix_md_buffer {
    my $self    = shift;

    my $gitctrl = $self->{git};
    my $uid     = $self->{s}->param("login");
    my $fid     = $self->qParam('fid');
    my $author  = $self->_get_author($uid);
    my $comment = $self->qParam('comment');
    unless($uid && $fid && $comment){
        push @{$self->{t}->{message}->{error}},
            "コメントがないためコミット失敗しました";
        return 0;
    }

    my $ret = $gitctrl->fix_tmp($uid, $author, $comment);
    unless($ret){
        push @{$self->{t}->{message}->{error}},
            "編集バッファのコミットに失敗しました";
        return 0;
    }
    push @{$self->{t}->{message}->{info}}, "コミットしました";
    push(@{$self->{t}->{message}->{info}}, $gitctrl->{info})
        if($gitctrl->{info});

    $self->{git}->attach_info($uid);
    $self->{outline}->init();
    $self->{git}->restruct_info($uid);
    $self->{outline}->save();
    $self->{git}->commit_info($self->{outline}->{filename}, $author);
    $self->{git}->detach_local();

    return 1;
}

# @summary 編集バッファを削除
#
sub reset_buffer {
    my $self    = shift;

    my $gitctrl = $self->{git};
    my $uid     = $self->{s}->param("login");
    my $fid     = $self->qParam('fid');
    unless( $uid && $fid ){
        push @{$self->{t}->{message}->{error}}, "不正なアクセスです";
        return 0;
    }
    return $gitctrl->reset_buffer($uid);
}

# @summary
#  - MDドキュメントをアウトライン用整形してテンプレートにセットする
#  - またドキュメントの情報もテンプレートにセットする
#
sub set_master_outline{
    my $self = shift;

    my $fid  = $self->qParam('fid');
    return unless($fid);  # NULL CHECK

    $self->_set_filename($fid);
    my $filepath = "$self->{repodir}/${fid}/$self->{filename}";
    my $user     = undef;
    my $revision = undef;
    my $gitctrl  = $self->{git};

    #MDファイルの更新履歴の整形
    $self->{t}->{loglist} = $gitctrl->get_shared_logs(undef, "DESC");

    #ドキュメントの読み込み
    $gitctrl->attach_local($user);
    $gitctrl->checkout_version($revision);
    my ($data, $pos) = MYUTIL::_fread($filepath);
    $gitctrl->detach_local();

    my @contents;

    $gitctrl->attach_info();
    $self->{outline}->init();
    my $divides = $self->{outline}->get_divides();
    $gitctrl->detach_local();
    my $rawdata = paragraphs($data);

    my ($i, $j) = (0, 0);
    my $docs;
    my $dat = undef;
    for ( @$rawdata ) {
        if ($divides) {
            #改ページ
            if (@$divides[$i] == $j) {
                push @$docs, $dat;
                $dat = undef;
                $i++;
            }
        }

        my $line = markdown($_);
        $line =~ s#^<([a-z1-9]+)>#<$1 id="document${j}">#;
        $line =~ s#"plugin/image_viewer\.cgi\?(.*)"#"plugin/image_viewer.cgi?master=1&$1" #g;
        $dat .= $line;

        #目次の生成
        if ( $line =~ m/<h1.*>/) {
            $line =~ s#<h1.*>(.*)</h1>#$1#;
            push @contents, {level => 1, line => $line, num => $j};
        } elsif ( $line =~ m/<h2.*>/ ) {
            $line =~ s#<h2.*>(.*)</h2>#$1#;
            push @contents, {level => 2, line => $line, num => $j};
        } elsif ( $line =~ m/<h3.*>/ ) {
            $line =~ s#<h3.*>(.*)</h3>#$1#;
            push @contents, {level => 3, line => $line, num => $j};
        }

        $j++;
    }

    if ($dat ne "") {
        push @$docs, $dat;
    }

    $self->{t}->{revision} = $revision;
    $self->{t}->{contents} = \@contents;
    $self->{t}->{docs}     = $docs;
}

# @summary ログインユーザー自身の編集バッファのログの取得
#
sub set_my_log {
    my $self = shift;

    my $fid  = $self->qParam("fid");
    my $uid  = $self->{s}->param("login");
    return 0 unless($fid && $uid);  # NULL CHECK

    my @userary;
    my $latest_rev = undef;
    my $gitctrl    = $self->{git};

    #共有リポジトリ(master)
    $self->{t}->{sharedlist} = $gitctrl->get_shared_logs();

    if($gitctrl->is_exist_user_branch($uid)){
        $self->{t}->{loglist} = $gitctrl->get_user_logs($uid);
    }
}

# @summary ドキュメントの生データをテンプレートにセットする
#
sub set_buffer_raw{
    my $self     = shift;

    my $uid      = $self->{s}->param("login");
    return unless($uid);
    my $fid      = $self->qParam('fid');
    my $document = $self->_get_user_document($uid, $fid);
    $self->{t}->{document} = $document;
}

# @summary 渡されたドキュメントの内容で編集バッファを上書きする
# @query fid
# @query document
#
sub update_md_buffer {
    my $self = shift;

    my $uid  = $self->{s}->param("login");
    my $fid  = $self->qParam('fid');
    return 0 unless($uid && $fid);

    unless( $self->_set_filename($fid) ){
        push @{$self->{t}->{message}->{error}}, "指定のファイルが見つかりません";
        return 0;
    }
    my $filepath = "$self->{repodir}/${fid}/$self->{filename}";
    my $document = $self->qParam('document');
    $document    =~ s#<div>\n##g;
    $document    =~ s#</div>\n##g;
    $document    =~ s/\r\n/\n/g;

    $self->{git}->attach_local_tmp($uid, 1);

    #ファイル書き込み
    open my $hF, '>', $filepath || die "failed to read ${filepath}";
    syswrite $hF, $document;
    close $hF;

    my $author = $self->_get_author($self->{s}->param('login'));
    $self->{git}->commit($self->{filename}, $author, "temp saved");
    $self->{git}->detach_local();
    push @{$self->{t}->{message}->{info}}, "編集内容を保存しました";
    return 1;
}

# @summary 差異のある２つのリポジトリの情報をテンプレートにセットする
#
sub set_merge_view {
    my $self     = shift;

    my $uid      = $self->{s}->param("login");
    my $fid      = $self->qParam("fid");
    my $gitctrl  = $self->{git};

    $self->_set_filename($fid);
    my $filepath = "$self->{repodir}/${fid}/$self->{filename}";

    # taking a info from MASTER
    $gitctrl->attach_local(undef);
    my ($doc_master, $pos) = MYUTIL::_fread($filepath);
    my $list_master;
    foreach(split(/\n/, $doc_master)){
        push @$list_master, $_;
    }
    $gitctrl->detach_local();

    # takeing a info from MINE including 'diff'
    $gitctrl->attach_local($uid);
    my ($doc_user, $pos2) = MYUTIL::_fread($filepath);
    my $list_user;
    foreach(split(/\n/, $doc_user)){
        push @$list_user, $_;
    }
    my $diff = $gitctrl->get_diff($self->{filename}, 'master', 'HEAD');
    $gitctrl->detach_local();

    $self->{t}->{doc_master} = $list_master;
    $self->{t}->{doc_mine}   = $list_user;
    $self->{t}->{diff}       = $diff;
}

# @summary ユーザーのブランチにアップロードしたファイルをコミットする
# query1: fid
# query2: login
# query3: uploadfile
#
sub upload_file {
    my $self = shift;

    my $fid    = $self->qParam('fid');
    my $uid    = $self->{s}->param("login");
    return 0 unless($fid && $uid); # NULL CHECK

    my $author = $self->_get_author($uid);
    my $hF     = $self->{q}->upload('uploadfile');
    unless($hF){
        push @{$self->{t}->{message}->{error}}, "ファイルがアップロードできませんでした";
        return 0;
    }
    my $filename = basename($hF);

    my $sql_check = "select id from docx_infos where file_name = '$filename' and is_used = true;";
    my @ary_check = $self->{dbh}->selectrow_array($sql_check);
    if(!@ary_check || $ary_check[0] != $fid){
        push @{$self->{t}->{message}->{error}}, "違うファイルがアップロードされたため更新されませんでした";
        close($hF);
        return 0;
    }

    $self->{git}->attach_local_tmp($uid, 1);

    my $tmppath  = $self->{q}->tmpFileName($hF);
    my $filepath = $self->{repodir}. "/$fid/$filename";
    move ($tmppath, $filepath) || die "Upload Error!. $filepath";
    close($hF);

    if(!$self->{git}->commit($filename, $author, "rewrite by an uploaded file")){
        push @{$self->{t}->{message}->{info}}, "ファイルに変更がないため更新されませんでした";
    }
    $self->{git}->detach_local();
    push @{$self->{t}->{message}->{info}}, "アップロードしたファイルで上書きしました";
    return 1;
}



1;
