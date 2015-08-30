package mdDog::Doc;

use strict; no strict "subs";
use parent mdDog;
use Text::Markdown::MdDog qw/markdown paragraph_html paragraph_raw alter_paragraph paragraphs/;
use File::Basename;
use File::Copy;
use MYUTIL;
use SQL;
use model::Docinfo;
use model::DocGroup;

sub init {
    my ($self, $fid) = @_;
    die ("不正な呼び出しです")  unless( $fid );

    my $workdir = "$self->{repodir}/" . $fid;
    $self->{git}     = GitCtrl->new($workdir);
    $self->{outline} = OutlineCtrl->new($workdir);
    $self->{fid} = $fid;

    $self->SUPER::init;
}

# @summary 権限チェック
#
sub check_auths {
    my ($self)  = @_;

    if( $self->{userinfo} ){
        my $sth = $self->{dbh}->prepare(SQL::auth_info);
        $sth->execute($self->{fid}, $self->{userinfo}->{uid});
        if( my $row = $sth->fetchrow_hashref() ){
            $self->{userinfo}->set_docACL($row, $self->{userinfo}->{uid});
        }
        $sth->finish();
    }

    foreach (@_) {
        return if( $_ =~ m/all/ );
        return if( $_ =~ m/is_edit/    && $self->{userinfo}->is_Editable  );
        return if ( $_ =~ m/is_owned/  && $self->{userinfo}->is_Owned     );
        return if ( $_ =~ m/is_approve/ && $self->{userinfo}->is_Approval );
        return if ( $_ =~ m/is_admin/  && $self->{userinfo}->is_Admin     );
    }
=pod
    if ( $fid ){
        print "Location: doc_history.cgi?fid=${fid}\n\n";
    } else {
        print "Location: index.cgi\n\n";
    }
    exit();
=cut
}

# @summary ドキュメント情報を取得してテンプレートにセット
#
sub set_document_info {
    my ($self) = @_;

    my $logs  = $self->{git}->get_shared_logs();

    my $sth = $self->{dbh}->prepare(SQL::document_info);
    $sth->execute($self->{fid});
    my $row = $sth->fetchrow_hashref();

    my $docinfo = mdDog::model::Docinfo->new();
    $docinfo->set_row($row);
    $docinfo->{file_size}       = -s $self->{repodir} . "/$self->{fid}/$row->{file_name}";
    $docinfo->{last_updated_at} = $logs->[0]->format_datetime;

    do{
        if( $row->{group_name} ){
            push @{$docinfo->{groups}}, mdDog::model::DocGroup->new(
                gid  => $row->{gid},
                name => $row->{group_name}
            );
        }
    }while( $row = $sth->fetchrow_hashref() );
    $sth->finish();

    if( $self->{userinfo} ){
        $docinfo->{is_owned}    = $self->{userinfo}->is_Owned;
        $docinfo->{is_approval} = $self->{userinfo}->is_Approval;
        $docinfo->{is_editable} = $self->{userinfo}->is_Editable;
    }
    return $docinfo;
}

# @summary ドキュメントのログを取得
#
sub set_document_log(){
    my $self    = shift;
    my $gitctrl = $self->{git};
    my $tmpl    = $self->{t};

    #共有リポジトリ(master)
#    $tmpl->{sharedlist} = $gitctrl->get_shared_logs();
    return $gitctrl->get_shared_logs();
}


# @summary ユーザーのバッファの状態を取得してテンプレートにセット
#
sub set_buffer_info {
    my ($self) = @_;
    return 0 unless( $self->{userinfo} );

    my $is_live = 0;
    my $gitctrl = $self->{git};

    # check whether current repository has been older than master
    my $shared_logs = $gitctrl->get_shared_logs('raw');
    my $latest_rev;
    if( $shared_logs ){
        $latest_rev = $shared_logs->[0]->{rev};
    }
    if($gitctrl->is_exist_user_branch($self->{userinfo}->{uid})){
        my $user_root = $gitctrl->get_branch_root($self->{userinfo}->{uid});
        $is_live = $latest_rev =~ m/^${user_root}[0-9a-z]+/ ?1:0;
    }else{
        $is_live = 1;
    }

    # check exist of temporary buffer
    if($self->{git}->is_exist_user_branch($self->{userinfo}->{uid}, 'tmp')
      && $self->{git}->is_updated_buffer($self->{userinfo}->{uid})){
        push @{$self->{t}->{message}->{buffered}}, "Buffered";
    }
    return $is_live;
}

# @summary MDドキュメントの編集バッファをフィックスする
# query: comment
#
sub fix_md_buffer {
    my ($self, $comment) = @_;
    unless($self->{userinfo} && $comment){
        push @{$self->{t}->{message}->{error}},
            "コメントがないためコミット失敗しました";
        return 0;
    }

    my $gitctrl = $self->{git};
    my $author  = $self->_get_author($self->{userinfo}->{uid});
    my $ret = $gitctrl->fix_tmp($self->{userinfo}->{uid}, $author, $comment);
    unless($ret){
        push @{$self->{t}->{message}->{error}},
            "編集バッファのコミットに失敗しました";
        return 0;
    }
    push @{$self->{t}->{message}->{info}}, "コミットしました";
    push(@{$self->{t}->{message}->{info}}, $gitctrl->{info})
        if($gitctrl->{info});

    $self->{git}->attach_info($self->{userinfo}->{uid});
    $self->{outline}->init();
    $self->{git}->restruct_info($self->{userinfo}->{uid});
    $self->{outline}->save();
    $self->{git}->commit_info($self->{outline}->{filename}, $author);
    $self->{git}->detach_local();

    return 1;
}

# @summary 編集バッファを削除
#
sub reset_buffer {
    my ($self) = @_;
    unless( $self->{userinfo} ){
        push @{$self->{t}->{message}->{error}}, "不正なアクセスです";
        return 0;
    }

    my $gitctrl = $self->{git};
    return $gitctrl->reset_buffer($self->{userinfo}->{uid});
}

# @summary
#  - MDドキュメントをアウトライン用整形してテンプレートにセットする
#  - またドキュメントの情報もテンプレートにセットする
#
sub set_master_outline{
    my ($self) = @_;

    $self->_set_filename($self->{fid});
    my $filepath = "$self->{repodir}/$self->{fid}/$self->{filename}";
    my $gitctrl  = $self->{git};

    my $loglist = $gitctrl->get_shared_logs(undef, "DESC");

    #ドキュメントの読み込み
    $gitctrl->attach_local();
    $gitctrl->checkout_version();
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

    return ($loglist, \@contents, $docs);
}

# @summary ログインユーザー自身の編集バッファのログの取得
#
sub set_my_log {
    my ($self) = @_;
    return 0 unless( $self->{userinfo} );  # NULL CHECK

    my @userary;
    my $latest_rev = undef;
    my $gitctrl    = $self->{git};

    #共有リポジトリ(master)
    $self->{t}->{sharedlist} = $gitctrl->get_shared_logs();

    if($gitctrl->is_exist_user_branch($self->{userinfo}->{uid})){
        return $gitctrl->get_user_logs($self->{userinfo}->{uid});
    }
}

# @summary ドキュメントの生データをテンプレートにセットする
#
sub set_buffer_raw{
    my ($self) = @_;
    return unless( $self->{userinfo} );

    my $document = $self->_get_user_document($self->{userinfo}->{uid},
                                             $self->{fid});
    return $document;
}

# @summary 渡されたドキュメントの内容で編集バッファを上書きする
# @query fid
# @query document
#
sub update_md_buffer {
    my ($self) = @_;
    return 0 unless( $self->{userinfo} );

    unless( $self->_set_filename($self->{fid}) ){
        push @{$self->{t}->{message}->{error}}, "指定のファイルが見つかりません";
        return 0;
    }
    my $filepath = "$self->{repodir}/$self->{fid}/$self->{filename}";
    my $document = $self->qParam('document');
    $document    =~ s#<div>\n##g;
    $document    =~ s#</div>\n##g;
    $document    =~ s/\r\n/\n/g;

    $self->{git}->attach_local_tmp($self->{userinfo}->{uid}, 1);

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
    my ($self) = @_;
    my $gitctrl  = $self->{git};

    $self->_set_filename($self->{fid});
    my $filepath = "$self->{repodir}/$self->{fid}/$self->{filename}";

    # taking a info from MASTER
    $gitctrl->attach_local(undef);
    my ($doc_master, $pos) = MYUTIL::_fread($filepath);
    my $list_master;
    foreach(split(/\n/, $doc_master)){
        push @$list_master, $_;
    }
    $gitctrl->detach_local();

    # takeing a info from MINE including 'diff'
    $gitctrl->attach_local($self->{userinfo}->{uid});
    my ($doc_user, $pos2) = MYUTIL::_fread($filepath);
    my $list_user;
    foreach(split(/\n/, $doc_user)){
        push @$list_user, $_;
    }
    my $diff = $gitctrl->get_diff($self->{filename}, 'master', 'HEAD');
    $gitctrl->detach_local();

    return ($list_master, $list_user, $diff);

#    $self->{t}->{doc_master} = $list_master;
#    $self->{t}->{doc_mine}   = $list_user;
#    $self->{t}->{diff}       = $diff;
}

# @summary ユーザーのブランチにアップロードしたファイルをコミットする
# query: uploadfile
#
sub upload_file {
    my ($self, $hF) = @_;
    return 0 unless( $self->{userinfo} ); # NULL CHECK
    unless($hF){
        push @{$self->{t}->{message}->{error}}, "ファイルがアップロードできませんでした";
        return 0;
    }

    my $filename = basename($hF);
    my $author   = $self->_get_author($self->{userinfo}->{uid});
    my $row      = $self->{teng}->single('docx_infos',
                          {file_name => $filename, is_used => 1});
    if( !$row || $row->id != $self->{fid} ){
        push @{$self->{t}->{message}->{error}},
            "違うファイルがアップロードされたため更新されませんでした";
        close($hF);
        return 0;
    }

    $self->{git}->attach_local_tmp($self->{userinfo}->{uid}, 1);

    my $tmppath  = $self->{q}->tmpFileName($hF);
    my $filepath = $self->{repodir}. "/$self->{fid}/$filename";
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
