package mdDog;

# --------------------------------------------------------------------
# @Author Yoshiaki Hori
# @copyright 2014 Yoshiaki Hori gm2bv2001@gmail.com
#
# This file is part of mdDog.
#
# mdDog is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# mdDog is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------

use strict; no strict "subs";
use parent APPBASE;
use Git::Wrapper;
use Data::Dumper;
use File::Copy;
use File::Basename;
use File::Path;
use Date::Manip;
use Text::Markdown::MdDog qw/markdown paragraph_html paragraph_raw alter_paragraph paragraphs/;
use NKF;
use Cwd;
use Image::Magick;
use JSON;
use MYUTIL;
use mdDog::GitCtrl;
use mdDog::OutlineCtrl;
use SQL;
use Data::Dumper;

use constant THUMBNAIL_SIZE => 150;

# constructor
#
sub new {
    my $pkg   = shift;
    my $base  = $pkg->SUPER::new(@_);

    my $hash  = {
        repo_prefix => "user_",
        git         => undef,
        outline     => undef,
    };
    @{$base}{keys %{$hash}} = values %{$hash};

    return bless $base, $pkg;
}

# @summary call at first
#
sub setup_config {
    my $self = shift;

    if($self->qParam('fid')){
        my $workdir = "$self->{repodir}/" . $self->qParam('fid');
        $self->{git}     = GitCtrl->new($workdir);
        $self->{outline} = OutlineCtrl->new($workdir);
    }

    if( join(' ', $self->{q}->param()) =~ m/.*page.*/ ){
        $self->add_cookie('INDEXPAGE', $self->qParam('page'), "+ 2hour");
    }
    if( join(' ', $self->{q}->param()) =~ m/.*style.*/ ){
        $self->add_cookie('INDEXSTYLE', $self->qParam('style'), "+ 2hour");
    }

    if( join(' ', $self->{q}->param()) =~ m/.*group.*/ ){
        $self->add_cookie('INDEXGROUP', $self->qParam('group'), "+ 2hour");
    }

    $self->SUPER::setup_config();
}

# @summary
#
sub set_outline_buffer{
    my $self = shift;

    my $uid = $self->{s}->param("login");
    return unless($uid);

    $self->{git}->attach_info($uid);
    $self->{outline}->init();
    $self->{git}->detach_local();

    my $divides = $self->{outline}->get_divides();
    $self->{t}->{divides} = $divides;
}

# @summary ログイン処理
#
sub login {
    my $self = shift;

    if( $self->qParam('login') ){
        my $account  = $self->qParam('account');
        my $password = $self->qParam('password');

        my $sth = $self->{dbh}->prepare(SQL::user_login);
        $sth->execute($account, $password);
        if( my $row = $sth->fetchrow_hashref() ){
            $self->{s}->param("login", $row->{id});
        }
        $sth->finish();
    }

    #ログアウト処理
    if($self->qParam('logout')){
        $self->{s}->clear("login");
        $self->{s}->close;
        $self->{s}->delete;
    }

    my $id = $self->{s}->param("login");
    if( $id ){
        my $sth = $self->{dbh}->prepare(SQL::user_info);
        $sth->execute($id);
        my $ha = $sth->fetchrow_hashref();
        $self->{user} = {
          account     => $ha->{account},
          mail        => $ha->{mail},
          nic_name    => $ha->{nic_name},
          is_admin    => $ha->{may_admin},
        };
        $sth->finish();
        return 1;
    }
    return 0;
}


# @summary 出力処理
#
sub print_page {
    my $self = shift;

    if($self->{s}->param("login")){
        $self->{t}->{login}      = $self->{s}->param("login");
    }
    if($self->{user}){ #ユーザー情報をセット
        $self->{t}->{account}    = $self->{user}->{account};
        $self->{t}->{nic_name}   = $self->{user}->{nic_name};
        $self->{t}->{mail}       = $self->{user}->{mail};
        $self->{t}->{is_admin}   = $self->{user}->{is_admin};
    }

    $self->SUPER::print_page();
}

# @summary 
#
sub change_profile{
    my $self = shift;
    my $uid  = $self->{s}->param('login');

    my $account     = $self->qParam('account');
    my $mail        = $self->qParam('mail');
    my $nic_name    = $self->qParam('nic_name');
    my $password    = $self->qParam('password');
    my $re_password = $self->qParam('re_password');

    if( length $password == 0 ){
        push @{$self->{t}->{message}->{error}}, "パスワードが入力されていません";
        return 0;
    }

    if( $password ne $re_password ){
        push @{$self->{t}->{message}->{error}}, "再入力されたパスワードが一致しません";
        return 0;
    }
    unless( $account && $nic_name && $mail ){
        push @{$self->{t}->{message}->{error}}, "入力が不足しています";
        return 0;
    }

    my $sth = $self->{dbh}->prepare(SQL::user_info_update);
    $sth->execute($account, $nic_name, $mail, $password, $uid);
    $self->dbCommit();
    return 1;
}

# @summary
#  - ユーザーが編集・承認を行なうページへのログインを行なう
#  - 条件を満たさないと適宜ページにリダイレクトする
#
sub login_user_document {
  my $self = shift;

  my $fid = $self->qParam('fid');
  unless($fid) {
      print "Location: index.cgi\n\n";
      exit();
  }
  unless($self->login()){
      print "Location: doc_history.cgi?fid=${fid}\n\n";
      exit();
  }

  return 1;
}

# @summary 権限チェック
#
sub check_auths {
    my $self  = shift;
    my $fid   = $self->qParam('fid');
    my $uid   = $self->{s}->param('login');

    if( $uid ){
      my $sth = $self->{dbh}->prepare(SQL::auth_info);
      $sth->execute($fid, $uid);
      if( my $row = $sth->fetchrow_hashref() ){
            $self->{user}->{is_approve} = $row->{may_approve};
            $self->{user}->{is_edit}    = $row->{may_edit};
            $self->{user}->{is_owned}   = $row->{created_by} == $uid?1:0;
      }
      $sth->finish();
    }

    foreach (@_) {
      if ( $_ =~ m/all/ ) {
        return;
      }
      if ( $_ =~ m/is_edit/    && $self->{user}->{is_edit}    ) {
        return;
      }
      if ( $_ =~ m/is_owned/   && $self->{user}->{is_owned}   ) {
        return;
      }
      if ( $_ =~ m/is_approve/ && $self->{user}->{is_approve} ) {
        return;
      }
      if ( $_ =~ m/is_admin/   && $self->{user}->{is_admin}   ) {
        return;
      }
    }
    if ( $fid ){
      print "Location: doc_history.cgi?fid=${fid}\n\n";
    } else {
      print "Location: index.cgi\n\n";
    }
    exit();
}

# @summary 登録されたドキュメント一覧の取得してテンプレートにセット
#
sub listup_documents {
    my ($self) = @_;

    my $uid    = $self->{s}->param("login");
    my $page   = $self->param_or_cookie("index", "page");
    my $style  = $self->param_or_cookie("index", "style");
    my $group  = $self->param_or_cookie("index", "group");
    my $offset = $page * $self->{paging_top};

    my ($sql, $sql_cnt);
    my @infos;


    if( $uid ){
        $sql = SQL::list_for_index($uid, $style, $offset, $self->{paging_top}, $group);
        $sql_cnt = SQL::document_list($uid, $style, $group);
    }else{
        #ログインなし
        $sql = SQL::list_for_index_without_login($offset, $self->{paging_top}, $group);
        $sql_cnt = SQL::document_list_without_login($group);
    }

    my $ary = $self->{dbh}->selectall_arrayref($sql, +{Slice => {}})
       || $self->errorMessage("DB:Error",1);
    if( @$ary ){
      my $prev_info = undef;
        foreach( @$ary ) {
            my @logs = GitCtrl->new("$self->{repodir}/$_->{id}")->get_shared_logs();
            if( $prev_info && $prev_info->{id} eq $_->{id} ){
                push @{$prev_info->{groups}}, $_->{group_title};
                next;
            }

            my $info = {
                id              => $_->{id},
                doc_name        => $_->{doc_name},
                file_name       => $_->{file_name},
                is_used         => $_->{is_used},
                created_at      => MYUTIL::format_date2($_->{created_at}),
                deleted_at      => !$_->{deleted_at}?undef:MYUTIL::format_date2($_->{deleted_at}),
                created_by      => $_->{nic_name},
                file_size       => MYUTIL::num_unit(-s $self->{repodir} . "/$_->{id}/$_->{file_name}"),
                last_updated_at => ${logs}[0][0]->{attr}->{date},
                is_editable     => $_->{may_edit}?1:0,
                is_approve      => $_->{may_approve}?1:0,
                is_public       => $_->{is_public},
                is_owned        => $uid && $_->{created_by}==${uid}?1:0,
            };
            if( $_->{group_title} ){
                push @{$info->{groups}}, $_->{group_title};
            }
            push @infos, $info;
            $prev_info = $info;
        }
        $self->{t}->{infos} = \@infos;
    }
    my $cnt = $self->{dbh}->selectall_arrayref($sql_cnt)
        || $self->viewAccident("DB:Error", 1);
    my $pages = @$cnt / $self->{paging_top};
    my $paging;
    for( my $i = 0; $i < $pages; $i++ ){
        push @$paging, $i;
    }

    $self->{t}->{document_count} = @$cnt;
    $self->{t}->{style}          = $style;
    $self->{t}->{page}           = $page;
    $self->{t}->{paging}         = $paging;
}

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
        push @{$docinfo->{groups}}, $row->{group_name}  if( $row->{group_name} );
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

# @summary ユーザーのバッファの状態を取得してテンプレートにセット
#
sub set_buffer_info {
    my $self    = shift;
    my $fid     = $self->qParam('fid');
    my $uid     = $self->{s}->param("login");
    my $gitctrl = $self->{git};

    return 0 unless( $fid && $uid );

    # check whether current repository has been older than master
    my $shared_logs = $gitctrl->get_shared_logs();
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
    if($self->{git}->is_exist_user_branch($uid, "tmp")
      && $self->{git}->is_updated_buffer($uid)){
        push @{$self->{t}->{message}->{buffered}}, "Buffered";
    }
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

# @summary ドキュメントのログを取得(承認者用)
#
sub set_user_log {
    my $self = shift;

    my $fid  = $self->qParam("fid");
    my $uid  = $self->{s}->param("login");

    my @userary;
    my $gitctrl    = $self->{git};
    my $latest_rev = undef;
    my $doclogs    = $gitctrl->get_shared_logs();
    $latest_rev    = $doclogs->[0]->{id} if( @$doclogs );

    foreach ( $gitctrl->get_other_users() ) {
        my $userlog = {
            uid       => $_,
            name      => $self->_get_nic_name($_),
            loglist   => $gitctrl->get_user_logs($_),
        };

        my $userRoot = $gitctrl->get_branch_root($_);
        if ( $latest_rev =~ m/${userRoot}[0-9a-z]+/
             && (@{$userlog->{loglist}}) ) {
            $userlog->{is_live} = 1;
            push @userary, $userlog;
        }
    }

    $self->{t}->{userlist} = \@userary;
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

# @summary 承認するために指定したリヴィジョンまでの履歴を取得してテンプレートにセット
#
sub set_approve_list {
    my $self = shift;

    my $uid      = $self->{s}->param("login");
    my $fid      = $self->qParam("fid");
    my $revision = $self->qParam("revision");
    my $user     = $self->qParam("user");
    return unless($uid && $fid && $revision && $user); # NULL CHECK

    my $branch   = "$self->{repo_prefix}${user}";

    my @logs;
    my $flg = undef;
    my $branches = $self->{git}->get_user_logs($user);
    for( @$branches ) {
        my $obj = eval {($_)};
        my $rev = $obj->{id};
        if( $flg || (!$flg && $obj->{id} eq ${revision}) ) {
            push @logs, $obj;
            $flg = 1 unless($flg);
        }
    }
    $self->{t}->{loglist}     = \@logs;
    $self->{t}->{approve_pre} = 1;
  }

# @summary
#
sub set_merge_view {
    my $self     = shift;

    my $uid      = $self->{s}->param("login");
    my $fid      = $self->qParam("fid");
    my $gitctrl  = $self->{git};

    my $sql = "select file_name from docx_infos where id = ${fid};";
    my @ary = $self->{dbh}->selectrow_array($sql);
    return unless(@ary);
    my $filename = $ary[0];
    my $filepath = "$self->{repodir}/${fid}/${filename}";

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
    my $diff = $gitctrl->get_diff($filename, 'master', 'HEAD');
    $gitctrl->detach_local();

    $self->{t}->{doc_master} = $list_master;
    $self->{t}->{doc_mine}   = $list_user;
    $self->{t}->{diff}       = $diff;
}


# @summary 指定のユーザーの指定のリヴィジョンを承認して共有化
#
sub doc_approve {
    my $self = shift;

    my $uid      = $self->{s}->param("login");
    my $fid      = $self->qParam("fid");
    my $revision = $self->qParam("revision");
    my $user     = $self->qParam("user");
    return unless($uid && $fid && $revision && $user); # NULL CHECK

    $self->{git}->approve($user, $revision);
}


# @summary MDファイルを作る
#
sub create_file {
  my $self = shift;
  my $uid  = $self->{s}->param("login");

  my $docname = nkf("-w", $self->qParam('doc_name'));
  my $filename = nkf("-w", $self->qParam('file_name'));
  $docname =~ s/^\s*(.*)\s*$/$1/;
  $docname =~ s/^(.*)\..*$/$1/;
  return unless($docname);
  unless( $filename ){
    $filename = $docname;
  }else{
    $filename =~ s/^\s*(.*)\s*$/$1/;
    $filename =~ s/^(.*)\..*$/$1/;
  }
  $filename =~ s/　/ /g;
  $filename =~ s/\s/_/g;

  my $fname = $filename . "\.md";
  my $fid      = $self->_setup_new_file($docname, $fname, $uid);
  my $workdir  = "$self->{repodir}/${fid}";
  my $filepath = "${workdir}/${fname}";
  open my $hF, ">", $filepath || die "Create Error!. $filepath";
  close($hF);

  $self->{git}     = GitCtrl->new($workdir);
  $self->{outline} = OutlineCtrl->new($workdir);
  $self->{git}->init($fid, [$fname], $self->_get_author($uid));

  $self->dbCommit();
}

# @summary ドキュメントの新規作成
# @param1 filename
# @param2 uid
#
sub _setup_new_file{
  my $self     = shift;
  my $docname  = shift;
  my $filename = shift;
  my $uid      = shift;

 my $sql_insert = << "SQL";
INSERT INTO
  docx_infos(doc_name, file_name, created_at, created_by)
VALUES
  ('$docname', '$filename',now(),$uid);
SQL
  $self->{dbh}->do($sql_insert) || $self->errorMessage("DB:Error _setup_new_file infos", 1);

  my $sql_newfile = "SELECT currval('docx_infos_id_seq');";
  my @ary_id = $self->{dbh}->selectrow_array($sql_newfile);
  my $fid = $ary_id[0];
  mkdir("./$self->{repodir}/$fid",0776)
    || die "Error:_setup_new_file can't make a directory($self->{repodir}/$fid)";

  my $sql_auth = << "SQL";
INSERT INTO
  docx_auths(info_id, user_id, may_approve, may_edit, created_at, created_by, updated_at)
VALUES
  (${fid}, ${uid}, 't', 't', now(), ${uid}, now());
SQL
  $self->{dbh}->do($sql_auth) || $self->errorMessage("DB:Error _setup_new_file auth", 1);

  return $fid;
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

# @summary
#
sub change_file_info {
  my $self = shift;
  my $ope  = shift;

  my $fid  = $self->qParam('fid');
  return unless($fid);  # NULL CHECK
  my $sql;

  if($ope =~ m/^use$/){
    $sql = "update docx_infos set is_used = true where id = $fid;";
  }elsif($ope =~ m/^unuse$/){
    $sql = "update docx_infos set is_used = false where id = $fid;";
  }elsif($ope =~ m/^delete$/){
    $sql = "update docx_infos set deleted_at = now() where id = $fid;";
    File::Path::rmtree(["./$self->{repodir}/$fid"]) || die("can't remove a directory: $fid");
  }
  $self->{dbh}->do($sql) || errorMessage("Error:change_file_info = $sql");

  $self->dbCommit();
}

# @summary 指定のバージョンのドキュメントをダウンロード出力する
# @param1 fid
# @param2 rev
#
sub download_file {
  my $self = shift;
  my $fid  = shift;
  my $rev  = shift;

  my $sql  = "select file_name from docx_infos where id = $fid;";
  my @ary  = $self->{dbh}->selectrow_array($sql);
  return unless($ary[0]);
  my $filename = $ary[0];
  my $filepath = "./$self->{repodir}/$fid/$filename";

  if($rev){
    $self->{git}->checkout_version($rev);
  }

  print "Content-type:application/octet-stream\n";
  print "Content-Disposition:attachment;filename=$filename\n\n";

  open (DF, $filepath) || die "can't open a file($filename)";
  binmode DF;
  binmode STDOUT;
  while (my $DFdata = <DF>) {
    print STDOUT $DFdata;
  }
  close DF;

  $self->{git}->detach_local() if($rev);
}

# @summary
# @param1 uid
#
sub _get_account {
  my $self = shift;
  my $uid  = shift;

  my $sql  = "select account from docx_users where id = $uid;";
  my @ary  = $self->{dbh}->selectrow_array($sql);
  return $ary[0];
}

# @summary 
# @param1 uid
#
sub _get_nic_name {
    my ($self, $uid) = @_;

    my $sth  = $self->{dbh}->prepare(SQL::user_info);
    $sth->execute($uid);
    my $ary = $sth->fetchrow_hashref();
    my $nic_name = $ary->{nic_name};
    $sth->finish();

    return $nic_name;
}

# @summary
# @param1 uid
#
sub _get_author {
    my ($self, $uid) = @_;

    my $sth  = $self->{dbh}->prepare(SQL::user_info);
    $sth->execute($uid);
    my $ary = $sth->fetchrow_hashref();
    my $author = "$ary->{nic_name} <$ary->{mail}>";
    $sth->finish();
    return $author;
}

# @summary
#  - MDドキュメントをアウトライン用整形してテンプレートにセットする
#  - またドキュメントの情報もテンプレートにセットする
#
sub set_master_outline{
    my $self = shift;

    my $fid  = $self->qParam('fid');
    return unless($fid);  # NULL CHECK

    my $sth = $self->{dbh}->prepare(SQL::document_info);
    $sth->execute($fid);
    my $row = $sth->fetchrow_hashref();
    return unless($row);

    my $filename = $row->{file_name};
    my $filepath = "$self->{repodir}/${fid}/${filename}";
    my $user     = undef;
    my $revision = undef;
    my $gitctrl  = $self->{git};

    #MDファイルの更新履歴の整形
    $self->{t}->{loglist} = $gitctrl->get_shared_logs("DESC");

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
        $line =~ s#"md_imageView\.cgi\?(.*)"#"md_imageView.cgi?master=1&$1" #g;
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

    push @$docs, $dat  if( $dat ne "" );

    $self->{t}->{revision} = $revision;
    $self->{t}->{contents} = \@contents;
    $self->{t}->{docs}     = $docs;
}

# @summary MDドキュメントをテンプレートにセットする
#
sub set_buffer_raw{
    my $self     = shift;

    my $uid      = $self->{s}->param("login");
    return unless($uid);
    my $fid      = $self->qParam('fid');
    my $document = $self->get_user_document($uid, $fid);
    $self->{t}->{document} = $document;
}

# @summary  MDドキュメントの編集バッファをテンプレートにセットする
#
sub set_buffer_md{
    my $self     = shift;

    my $uid      = $self->{s}->param("login");
    return unless($uid);
    my $fid      = $self->qParam('fid');
    my $document = $self->get_user_document($uid, $fid);
    my $md       = markdown($document);
    $md =~ s#"md_imageView\.cgi\?(.*)"#"md_imageView.cgi?tmp=1&$1" #g;

    $self->{t}->{markdown} = $md;
    $self->{t}->{raws} = paragraphs($document);
}

# @summary MDドキュメントの編集バッファを更新する
#
sub update_md_buffer {
    my $self = shift;

    my $uid  = $self->{s}->param("login");
    my $fid  = $self->qParam('fid');
    return 0 unless($uid && $fid);

    my $sth = $self->{dbh}->prepare(SQL::document_info);
    $sth->execute($fid);
    my $row = $sth->fetchrow_hashref();
    unless($row){
        push @{$self->{t}->{message}->{error}}, "指定のファイルが見つかりません";
    return 0;
    }

    my $filename = $row->{file_name};
    my $filepath = "$self->{repodir}/${fid}/${filename}";
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
    $self->{git}->commit($filename, $author, "temp saved");
    $self->{git}->detach_local();
    push @{$self->{t}->{message}->{info}}, "編集内容を保存しました";
    return 1;
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
    my $comment = $self->qParam('comment');
    unless($uid && $fid && $comment){
        push @{$self->{t}->{message}->{error}},
            "コメントがないためコミット失敗しました";
        return 0;
    }

    my $ret = $gitctrl->fix_tmp($uid,
                                $self->_get_author($uid),
                                $comment);
    unless($ret){
        push @{$self->{t}->{message}->{error}},
            "編集バッファのコミットに失敗しました";
        return 0;
    }
    push @{$self->{t}->{message}->{info}}, "コミットしました";
    push(@{$self->{t}->{message}->{info}}, $gitctrl->{info})
        if($gitctrl->{info});
    return 1;
}

# @summary
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

# @summary MDドキュメントで管理している画像一覧を取得
#
sub set_md_image{
  my $self   = shift;

  my $uid    = $self->{s}->param("login");
  return unless($uid);
  my $fid    = $self->qParam('fid');
  my $imgdir = "$self->{repodir}/${fid}/image";

  unless(-d $imgdir){
    mkdir $imgdir, 0774 || die "can't make image directory.";
  }

  $self->{git}->attach_local_tmp($uid);
  my @images = glob "$imgdir/*";
  $self->{git}->detach_local();

  my @imgpaths;
  foreach (@images) {
    my $path = $_;
    $path =~ s#$self->{repodir}/${fid}/image/(.*)$#$1#g;
    push @imgpaths, $path;
  }

  $self->{t}->{images} = \@imgpaths;
  $self->{t}->{uid}    = $self->{s}->param("login");
}

# @summary 画像をアップロードしてユーザーの編集バッファにコミット
#
sub upload_image {
    my $self     = shift;
    my $fid      = $self->qParam('fid');
    my $uid      = $self->{s}->param("login");
    return 0 unless($fid && $uid);

    my $hF       = $self->{q}->upload('imagefile');
    my $filename = basename($hF);

    $self->{git}->attach_local_tmp($uid, 1);
    my $imgdir    = "$self->{repodir}/${fid}/image";
    unless(-d $imgdir){
        mkdir $imgdir, 0774 || die "can't make image directory.";
    }
    my $tmppath   = $self->{q}->tmpFileName($hF);
    my $filepath  = "${imgdir}/${filename}";
    move ($tmppath, $filepath) || die "Upload Error!. $filepath";
    close($hF);
    my $thumbnail = $self->add_thumbnail($fid, $filename);

    my $author = $self->_get_author($self->{s}->param('login'));
    $self->{git}->add_image($filepath, $author);
    $self->{git}->add_image($thumbnail, $author);

    $self->{git}->detach_local();
    push @{$self->{t}->{message}->{info}},
      "画像をアップロードしました";
    return 1;
}

# @summary 画像のサムネイルを作成
# @param1 fid
# @param2 ファイル名
#
sub add_thumbnail {
  my $self     = shift;
  my $fid      = shift;
  my $filename = shift;

  my $imgpath  = "$self->{repodir}/${fid}/image/${filename}";
  my $thumbdir = "$self->{repodir}/${fid}/thumb";
  unless(-d $thumbdir){
    mkdir $thumbdir, 0774 || die "can't make thumbnail directory.";
  }

  my $mImg = Image::Magick->new();
  $mImg->Read($imgpath);
  my ($w, $h) = $mImg->get('width', 'height');
  my ($rw, $rh);
  if ($w > THUMBNAIL_SIZE || $h > THUMBNAIL_SIZE) { #サイズが大きいときだけリサイズ
      if ($w >= $h) {
          $rw = THUMBNAIL_SIZE;
          $rh = THUMBNAIL_SIZE / $w * $h;
      } else {
          $rh = THUMBNAIL_SIZE;
          $rw = THUMBNAIL_SIZE / $h * $w;
      }
      $mImg->Resize(width=>$rw, height=> $rh);
  }
  $mImg->Write("${thumbdir}/${filename}");
  return "${thumbdir}/${filename}";
}

#
#
sub delete_image {
  my $self = shift;

  my $fid  = $self->qParam('fid');
  my $uid  = $self->{s}->param("login");
  return 0 unless($uid && $fid);

  my @selected = ($self->qParam('select_image'));

  $self->{git}->attach_local_tmp($uid);
  my $author = $self->_get_author($self->{s}->param('login'));
  $self->{git}->delete_image([@selected], $author);
  $self->{git}->detach_local();
  push @{$self->{t}->{message}->{info}}, "画像を削除しました";
  return 1;
}

# @summary 指定の画像ファイルを出力
#
sub print_image {
  my $self = shift;

  my $fid       = $self->qParam('fid');
  my $image     = $self->qParam('image');
  my $thumbnail = $self->qParam('thumbnail');
  my $tmp       = $self->qParam('tmp');
  my $size      = $self->qParam('size');      # 0 - 100
  my $uid       = $self->{s}->param("login");
  return unless($image && $fid);              # NULL CHECK

  $uid = undef if($uid && $self->qParam('master'));

  my $imgpath;
  unless($thumbnail){
    $imgpath = "$self->{repodir}/${fid}/image/${image}";
  } else {
    $imgpath = "$self->{repodir}/${fid}/thumb/${image}";
  }

  if($uid && $tmp){
    $self->{git}->attach_local_tmp($uid);
  }else{
    $self->{git}->attach_local($uid);
  }

  if( -f $imgpath ){
    my $type = $imgpath;
    $type =~ s/.*\.(.*)$/$1/;
    $type =~ tr/A-Z/a-z/;

    print "Content-type: image/${type}\n\n";

    my $mImg = Image::Magick->new();
    $mImg->Read($imgpath);
    if( $size > 0 && $size < 100 ){
        my ($w, $h) = $mImg->get('width', 'height');
        my $rw = $w * $size / 100;
        my $rh = $h * $size / 100;
        $mImg->Resize(width => $rw, height => $rh);
    }
    binmode STDOUT;
    $mImg->Write($type . ":-");
  }
  $self->{git}->detach_local();
}

#
# @param1 uid
# @param2 fid
#
sub get_user_document {
    my ($self, $uid, $fid) = @_;

    my $sth = $self->{dbh}->prepare(SQL::document_info);
    $sth->execute($fid);
    my $row = $sth->fetchrow_hashref();
    return unless($row);

    my $filename = $row->{file_name};
    my $filepath = "$self->{repodir}/${fid}/${filename}";

    $self->{git}->attach_local_tmp($uid);
    my($document, $pos) = MYUTIL::_fread($filepath);
    $self->{git}->detach_local();

    return $document;
}

#
#
sub count_paragraph {
    my ($self, $data) = @_;

    my $tmp = $data;
    my $cnt = 0;
    my $next = 0;
    while( $tmp =~ m/^.*<[a-z][a-z0-9]*>.*/ ){
        $tmp =~ s/^.*<[a-z][a-z0-9]*>(.*)/$1/;
    }
}

#
#
sub change_doc_name {
    my $self     = shift;
    my $fid      = $self->qParam('fid');
    my $doc_name = $self->qParam('doc_name');
    return 0 unless($fid && $doc_name);

    my $sth = $self->{dbh}->prepare(SQL::document_name_update);
    $sth->execute($doc_name, $fid);
    $self->dbCommit();
    return 1;
}

#
#
sub listup_groups {
    my $self = shift;
    my $ar;
    my $group = $self->param_or_cookie("index", "group");
    my $sth = $self->{dbh}->prepare(SQL::group_list);
    $sth->execute;
    while( my $row = $sth->fetchrow_hashref() ){
        if( $group &&  $row->{id} == $group ){
            $row->{selected} = 1;
        }
        push @$ar, $row;
    }

    $sth->finish();
    $self->{t}->{groups} = $ar;
}

#
#
sub param_or_cookie{
    my ($self, $prefix, $key) = @_;

    my $val = $self->qParam($key);
    unless( join(' ', $self->{q}->param()) =~ m/.*${key}.*/ ){
        my $ckey = uc "${prefix}${key}";
        if( $self->{q}->cookie(${ckey}) ){
            $val = $self->{q}->cookie(${ckey});
        }else{
            $val = undef;
        }
    }
    return $val;
}

1;
