package mdDog;

#
# author: gm2bv
# date: 2015/1/14
#

use strict; no strict "subs";
use base APPBASE;
use Git::Wrapper;
use Data::Dumper;
use File::Copy;
use File::Basename;
use File::Path;
use Date::Manip;
use Text::Markdown::Discount qw(markdown);
use NKF;
use Cwd;
use Image::Magick;
use JSON;
use MYUTIL;
use mdDog::GitCtrl;
use mdDog::OutlineCtrl;

use constant THUMBNAIL_SIZE => 150;

###################################################
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

###################################################
#
sub setup_config {
  my $self = shift;

  if($self->qParam('fid')){
    my $workdir = "$self->{repodir}/" . $self->qParam('fid');
    $self->{git} = GitCtrl->new($workdir);
    $self->{outline} = OutlineCtrl->new($workdir);
  }

  $self->SUPER::setup_config();
}

###################################################
#
sub set_outline_buffer{
  my $self = shift;

  my $uid = $self->{s}->param("login");
  return unless($uid);

  $self->{git}->attach_local_tmp($uid);
  $self->{outline}->init();
  $self->{git}->detach_local();

  my $divides = $self->{outline}->get_divides();
  $self->{t}->{divides} = $divides;
}

############################################################
#ログイン処理
#
sub login {
    my $self = shift;

    if( $self->qParam('login') ){
        my $account  = $self->qParam('account');
        my $password = $self->qParam('password');

        my $sql = << "SQL";
SELECT
  id
FROM
  docx_users
WHERE
  account = '$account'
  AND password = md5('$password')
  AND is_used = true;
SQL
        my @ary = $self->{dbh}->selectrow_array($sql);
        if( @ary ){
            $self->{s}->param("login", $ary[0]);
        }
    }

    #ログアウト処理
    if($self->qParam('logout')){
        $self->{s}->clear("login");
        $self->{s}->close;
        $self->{s}->delete;
    }

    my $id = $self->{s}->param("login");
    if( $id ){
        my $sql = << "SQL";
SELECT
  account, mail, nic_name, may_admin, may_approve, may_delete
FROM
  docx_users
WHERE
  id = ${id}
  AND is_used = true;
SQL
        my $ha = $self->{dbh}->selectrow_hashref($sql);
        $self->{user} = {
          account     => $ha->{account},
          mail        => $ha->{mail},
          nic_name    => $ha->{nic_name},
          is_admin    => $ha->{may_admin},
        };
        return 1;
    }
    return 0;
}


############################################################
#出力処理
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

############################################################
#
#
sub change_profile{
    my $self = shift;
    my $uid  = $self->{s}->param('login');

    my $account     = $self->qParam('account');
    my $mail        = $self->qParam('mail');
    my $nic_name    = $self->qParam('nic_name');
    my $password    = $self->qParam('password');
    my $re_password = $self->qParam('re_password');

    if( $password != $re_password ){
      push @{$self->{t}->{message}->{error}}, "再入力されたパスワードが一致しません";
      return 0;
    }
    unless( $account && $nic_name && $mail ){
      push @{$self->{t}->{message}->{error}}, "入力が不足しています";
      return 0;
    }

    my $sql_update = << "SQL";
UPDATE docx_users
SET
  account = '${account}',
  nic_name = '${nic_name}',
  mail = '${mail}',
  password = md5('${password}')
WHERE
  id = ${uid}
SQL
    $self->{dbh}->do($sql_update);
    $self->dbCommit();
    return 1;
}

############################################################
#ユーザーが編集・承認を行なうページへのログインを行なう
#条件を満たさないと適宜ページにリダイレクトする
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

############################################################
# 権限チェック
#
sub check_auths {
    my $self  = shift;
    my $fid   = $self->qParam('fid');
    my $uid   = $self->{s}->param('login');

    if( $uid ){
        my $sql_auth = << "SQL";
SELECT
  da.*,
  di.created_by
FROM docx_auths da
INNER JOIN docx_infos di ON da.info_id = di.id
WHERE
  da.info_id = ${fid}
  AND da.user_id = ${uid}
SQL
        my $ary = $self->{dbh}->selectrow_hashref($sql_auth);
        if($ary) {
            $self->{user}->{is_approve} = $ary->{may_approve};
            $self->{user}->{is_edit}    = $ary->{may_edit};
            $self->{user}->{is_delete}  = $ary->{may_delete};
            $self->{user}->{is_owned}   = $ary->{created_by} == $uid?1:0;
        }
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
      if ( $_ =~ m/is_delete/  && $self->{user}->{is_delete}  ) {
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

############################################################
#登録されたドキュメント一覧の取得してテンプレートにセット
#
sub listup_documents {
    my $self = shift;
    my @infos;
    my $uid  = $self->{s}->param("login");

    my $sql;

    if( $uid ){
        $sql = << "SQL";
SELECT
  di.*,
  du.nic_name    AS nic_name,
  du.account     AS account,
  du.mail        AS mail,
  da.id          AS auth_id,
  da.may_edit    AS may_edit,
  da.may_approve AS may_approve
FROM
  docx_infos di
JOIN docx_users du ON du.id = di.created_by
LEFT OUTER JOIN docx_auths da on da.info_id = di.id and da.user_id = ${uid}
WHERE
  di.deleted_at is null
  and (di.is_public = true or da.id is not null)
ORDER BY
  di.is_used DESC, di.created_at DESC;
SQL
      }else{
        #ログインなし
        $sql = << "SQL";
SELECT
  di.*,
  du.nic_name AS nic_name,
  du.account AS account,
  du.mail AS mail
FROM
  docx_infos di
JOIN docx_users du ON du.id = di.created_by
WHERE
  di.deleted_at is null
  and di.is_public = true
ORDER BY
  di.is_used DESC, di.created_at DESC;
SQL
      }

  my $ary = $self->{dbh}->selectall_arrayref($sql, +{Slice => {}})
     || $self->errorMessage("DB:Error",1);
  if(@$ary){
    foreach (@$ary) {
      my @logs = GitCtrl->new("$self->{repodir}/$_->{id}")->get_shared_logs();
      my $info = {
        id              => $_->{id},
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
        is_owned        => $_->{created_by}==${uid}?1:0,
      };
      push @infos, $info;
    }
    $self->{t}->{infos} = \@infos;
  }
}

############################################################
# ドキュメント情報を取得してテンプレートにセット
sub set_document_info {
    my $self = shift;

    my $fid   = $self->qParam('fid');
    my $uid   = $self->{s}->param('login');
    my $user  = $self->qParam('user');
    my $ver   = $self->qParam('revision');
    return unless($fid);        # NULL CHECK

    my $sql   = << "SQL";
SELECT
  di.*,
  du.nic_name AS nic_name,
  du.account  AS account,
  du.mail     AS mail
FROM
  docx_infos di
JOIN docx_users du
  ON di.created_by = du.id AND du.is_used = 't'
WHERE
  di.id = $fid;
SQL

    my $ary = $self->{dbh}->selectrow_hashref($sql);

    if( $ary ){
        $self->{t}->{file_name}       = $ary->{file_name};
        $self->{t}->{created_at}      = MYUTIL::format_date2($ary->{created_at});
        $self->{t}->{created_by}      = $ary->{nic_name};
        $self->{t}->{file_size}       = MYUTIL::num_unit(-s $self->{repodir} . "/${fid}/$ary->{file_name}");
        $self->{t}->{is_public}       = $ary->{is_public};
        $self->{t}->{is_owned}        = $ary->{created_by} == $self->{s}->param('login')?1:0;

        my @logs = $self->{git}->get_shared_logs();
        $self->{t}->{last_updated_at} = ${logs}[0][0]->{attr}->{date};
    }

    if( $uid ){
        $self->{t}->{is_approve} = $self->{user}->{is_approve};
        $self->{t}->{is_edit}    = $self->{user}->{is_edit};
        $self->{t}->{is_delete}  = $self->{user}->{is_delete};
    }

    $self->{t}->{fid}      = $fid;
    $self->{t}->{user}     = $user;
    $self->{t}->{revision} = $ver if($ver);
}


############################################################
#
sub is_exist_buffer {
    my $self = shift;
    my $fid  = $self->qParam('fid');
    my $uid  = $self->{s}->param("login");

    if($self->{git}->is_exist_user_branch($uid, {tmp=>1})
      && $self->{git}->is_updated_buffer($uid)){
        push @{$self->{t}->{message}->{buffered}}, "コミットされていないバッファがあります";
    }
}


############################################################
#ドキュメントのログを取得
#
# @param1 全ての編集ユーザーのログを取得するかのフラグ
#
sub git_log {
    my $self = shift;
    my $all  = shift;

    my $fid  = $self->qParam("fid");
    my $uid  = $self->{s}->param("login");

    my @userary;
    my $latest_rev = undef;
    my $gitctrl    = $self->{git};

    #共有リポジトリ(master)
    $self->{t}->{sharedlist} = $gitctrl->get_shared_logs();
    $latest_rev = $self->{t}->{sharedlist}->[0]->{id} if($self->{t}->{sharedlist});

    if( $all and $uid ){        #ユーザーリポジトリ
        #自分のリポジトリ
        my $mylog = {
                   uid     => $uid,
                   name    => $self->{user}->{account},
                   loglist => [],
                  };
        if( $gitctrl->is_exist_user_branch($uid) ){
            $mylog->{loglist} = $gitctrl->get_user_logs($uid);
            my $user_root = $gitctrl->get_branch_root($uid);
            $mylog->{is_live} = $latest_rev =~ m/^${user_root}[0-9a-z]+/ ?1:0;
        }else{
            $mylog->{is_live} = 1;
        }
        push @userary, $mylog;
        if( $self->{user}->{is_approve} ){
            #承認者
            foreach( $gitctrl->get_other_users() ){
                next if($_ eq $uid);
                my $userlog = {
                         uid       => $_,
                         name      => $self->_get_account($_),
                         loglist   => $gitctrl->get_user_logs($_),
                };

                my $userRoot = $gitctrl->get_branch_root($_);
                if( $latest_rev =~ m/${userRoot}[0-9a-z]+/
                    && (@{$userlog->{loglist}}) ){
                    $userlog->{is_live} = 1;
                    push @userary, $userlog;
                }
            }
        }
    }
    $self->{t}->{userlist} = \@userary;
}

############################################################
#ログインユーザー自身の編集バッファのログの取得
#
sub git_my_log {
    my $self = shift;

    my $fid  = $self->qParam("fid");
    my $uid  = $self->{s}->param("login");
    return 0 unless($fid && $uid);  # NULL CHECK

    my @userary;
    my $latest_rev = undef;
    my $gitctrl    = $self->{git};

    #共有リポジトリ(master)
    $self->{t}->{sharedlist} = $gitctrl->get_shared_logs();
    $latest_rev = $self->{t}->{sharedlist}->[0]->{id} if($self->{t}->{sharedlist});

    if($gitctrl->is_exist_user_branch($uid)){
        $self->{t}->{loglist} = $gitctrl->get_user_logs($uid);
        my $user_root = $gitctrl->get_branch_root($uid);
        $self->{t}->{is_live} = $latest_rev =~ m/^${user_root}[0-9a-z]+/ ?1:0;
    }
    else{
        $self->{t}->{is_live} = 1;
    }
    $self->{t}->{owned} = 1;
}

###################################################
# 承認するために指定したリヴィジョンまでの履歴を取得してテンプレートにセット
#
sub set_approve_list {
  my $self = shift;

  my $uid      = $self->{s}->param("login");
  my $fid      = $self->qParam("fid");
  my $revision = $self->qParam("revision");
  my $user     = $self->qParam("user");
  return unless($uid && $fid && $revision && $user);  # NULL CHECK

  my $branch   = "$self->{repo_prefix}${user}";

  my @logs;
  my $flg = undef;
  my $branches = $self->{git}->get_user_logs($user);
  for (@$branches){
    my $obj = eval {($_)};
    my $rev = $obj->{id};
    if($flg
       || (!$flg && $obj->{id} eq ${revision}) ){
      push @logs, $obj;
      $flg = 1 unless($flg);
    }
  }
  $self->{t}->{loglist}     = \@logs;
  $self->{t}->{approve_pre} = 1;
}

###################################################
# 指定のユーザーの指定のリヴィジョンを承認して共有化
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


###################################################
# MDファイルを作る
sub create_file {
  my $self = shift;
  my $uid  = $self->{s}->param("login");

  my $docname = nkf("-w", $self->qParam('docname'));
  $docname =~ s/^\s*(.*)\s*$/\1/;
  $docname =~ s/\s/_/g;
  $docname =~ s/^(.*)\..*$/\1/;
  return unless($docname);

  my $filename = $docname . "\.md";
  my $fid      = $self->_setup_new_file($filename, $uid);
  my $workdir  = "$self->{repodir}/${fid}";
  my $filepath = "${workdir}/${filename}";
  open my $hF, ">", $filepath || die "Create Error!. $filepath";
  close($hF);

  $self->{git}     = GitCtrl->new($workdir);
  $self->{outline} = OutlineCtrl->new($workdir);
  $self->{git}->init($fid, [$filename, $self->{outline}->{filename}], $self->_get_author($uid));

  $self->dbCommit();
}

###################################################
# ドキュメントの新規作成
# @param1 filename
# @param2 uid
#
sub _setup_new_file{
  my $self     = shift;
  my $filename = shift;
  my $uid      = shift;

 my $sql_insert = << "SQL";
INSERT INTO
  docx_infos(file_name, created_at, created_by)
VALUES
  ('$filename',now(),$uid);
SQL
  $self->{dbh}->do($sql_insert) || $self->errorMessage("DB:Error _setup_new_file infos", 1);

  my $sql_newfile = "SELECT currval('docx_infos_id_seq');";
  my @ary_id = $self->{dbh}->selectrow_array($sql_newfile);
  my $fid = $ary_id[0];
  mkdir("./$self->{repodir}/$fid",0776)
    || die "Error:_setup_new_file can't make a directory($self->{repodir}/$fid)";

  my $sql_auth = << "SQL";
INSERT INTO
  docx_auths(info_id, user_id, may_approve, created_at, created_by, updated_at)
VALUES
  (${fid}, ${uid}, 't', now(), ${uid}, now());
SQL
  $self->{dbh}->do($sql_auth) || $self->errorMessage("DB:Error _setup_new_file auth", 1);

  return $fid;
}

###################################################
# ユーザーのブランチにアップロードしたファイルをコミットする
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

############################################################
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

############################################################
#指定のバージョンのドキュメントをダウンロード出力する
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

############################################################
# @param1 uid
#
sub _get_account {
  my $self = shift;
  my $uid  = shift;

  my $sql  = "select account from docx_users where id = $uid;";
  my @ary  = $self->{dbh}->selectrow_array($sql);
  return $ary[0];
}

############################################################
# @param1 uid
#
sub _get_author {
  my $self = shift;
  my $uid  = shift;

  my $sql  = "select account || ' <' || mail || '>' from docx_users where id = $uid;";
  my @ary  = $self->{dbh}->selectrow_array($sql);
  return $ary[0];
}

############################################################
# MDドキュメントをアウトライン用整形してテンプレートにセットする
# またドキュメントの情報もテンプレートにセットする
#
sub set_master_outline{
  my $self = shift;

  my $fid  = $self->qParam('fid');
  return unless($fid);  # NULL CHECK

  my $sql  = "select file_name from docx_infos where id = ${fid};";
  my @ary  = $self->{dbh}->selectrow_array($sql);
  return unless(@ary);

  my $filename = $ary[0];
  my $filepath = "$self->{repodir}/${fid}/${filename}";
  my $md;
  my $user     = undef;
  my $revision = undef;
  my $gitctrl  = $self->{git};

  #MDファイルの更新履歴の整形
  $self->{t}->{loglist} = $gitctrl->get_shared_logs("DESC");

  #ドキュメントの読み込み
  $gitctrl->attach_local($user);
  $gitctrl->checkout_version($revision);
  open my $hF, '<', $filepath || die "failed to read ${filepath}";
  my $pos = 0;
  while (my $length = sysread $hF, $md, 1024, $pos) {
    $pos += $length;
  }
  close $hF;
  $gitctrl->detach_local();

  my @contents;

  $self->{outline}->init();
  my $divides = $self->{outline}->get_divides();
  my ($rowdata, @partsAry) = $self->split_for_md($md);
  my ($i, $j) = (0, 0);
  my ($docs, $dat);
  foreach (@partsAry) {
    if($divides){
      #改ページ
      if(@$divides[$i] == $j){
        push @$docs, $dat;
        $dat = undef;
        $i++;
      }
    }

    my $line = markdown($_);
    $line =~ s#^<([a-z1-9]+)>#<\1 id="document${j}">#;
    $line =~ s#"md_imageView\.cgi\?(.*)"#"md_imageView.cgi?master=1&\1" #g;
    $dat .= $line;

    #目次の生成
    if( $line =~ m/<h1.*>/){
      $line =~ s#<h1.*>(.*)</h1>#\1#;
      push @contents, {level => 1, line => $line, num => $j};
    }elsif( $line =~ m/<h2.*>/ ){
      $line =~ s#<h2.*>(.*)</h2>#\1#;
      push @contents, {level => 2, line => $line, num => $j};
    }elsif( $line =~ m/<h3.*>/ ){
      $line =~ s#<h3.*>(.*)</h3>#\1#;
      push @contents, {level => 3, line => $line, num => $j};
    }elsif( $line =~ m/<h4.*>/ ){
      $line =~ s#<h4.*>(.*)</h4>#\1#;
      push @contents, {level => 4, line => $line, num => $j};
    }

    $j++;
  }
  if($dat ne ""){
    push @$docs, $dat;
  }

  $self->{t}->{revision} = $revision;
  $self->{t}->{contents} = \@contents;
  $self->{t}->{docs}     = $docs;
}

############################################################
# MDドキュメントの編集バッファをテンプレートにセットする
# @param1 ドキュメントを構造解析するかのフラグ
#
sub set_md_buffer{
  my $self     = shift;
  my $preview  = shift;

  my $uid      = $self->{s}->param("login");
  return unless($uid);
  my $fid      = $self->qParam('fid');
  my $document = $self->get_user_document($uid, $fid);

  unless($preview){
    $self->{t}->{document} = $document;
  }else {
    my ($rowdata, @partsAry) = $self->split_for_md($document);
    my $md;
    my $cnt = 0;

    foreach (@partsAry) {
      my $conv = markdown($_);

      $conv =~ s/^<([a-z1-9]+)>/<\1 id=\"md${cnt}\" class=\"Md\">/;
      $conv =~ s#^<([a-z1-9]+) />#<\1 id=\"md${cnt}\" class=\"Md\" />#;
      $conv =~ s#"md_imageView\.cgi\?(.*)"#"md_imageView.cgi?tmp=1&\1" #g;

      $md .= $conv;
      $cnt++;
    }

    $self->{t}->{rowdata} = $rowdata;
    $self->{t}->{markdown} = $md;
  }
}

############################################################
# MDドキュメントの編集バッファを更新する
#
sub update_md_buffer {
  my $self = shift;

  my $uid  = $self->{s}->param("login");
  my $fid  = $self->qParam('fid');
  return 0 unless($uid && $fid);

  my $sql  = "select file_name from docx_infos where id = ${fid};";
  my @ary  = $self->{dbh}->selectrow_array($sql);
  unless(@ary){
    push @{$self->{t}->{message}->{error}}, "指定のファイルが見つかりません";
    return 0;
  }
  my $filename = $ary[0];
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

############################################################
# MDドキュメントの編集バッファをフィックスする
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
    push @{$self->{t}->{message}->{error}}, "コメントがないためコミット失敗しました";
    return 0;
  }

  if($self->qParam('document')){
    return 0 unless($self->update_md_buffer());
  }
  my $ret = $gitctrl->fix_tmp($uid, $self->_get_author($uid), $comment);
  unless($ret){
    push @{$self->{t}->{message}->{error}}, "編集バッファのコミットに失敗しました";
    return 0;
  }
  push @{$self->{t}->{message}->{info}}, "コミットしました";
  push(@{$self->{t}->{message}->{info}}, $gitctrl->{info}) if($gitctrl->{info});
  return 1;
}

############################################################
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

############################################################
# MDドキュメントで管理している画像一覧を取得
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
    $path =~ s#$self->{repodir}/${fid}/image/(.*)$#\1#g;
    push @imgpaths, $path;
  }

  $self->{t}->{images} = \@imgpaths;
  $self->{t}->{uid}    = $self->{s}->param("login");
}

############################################################
# 画像をアップロードしてユーザーの編集バッファにコミット
#
sub upload_image {
  my $self     = shift;

  my $fid      = $self->qParam('fid');
  my $uid      = $self->{s}->param("login");
  return 0 unless($fid && $uid);

  my $hF       = $self->{q}->upload('imagefile');
  my $filename = basename($hF);

  $self->{git}->attach_local_tmp($uid, 1);

  my $imgdir   = "$self->{repodir}/${fid}/image";
  unless(-d $imgdir){
    mkdir $imgdir, 0774 || die "can't make image directory.";
  }
  my $tmppath  = $self->{q}->tmpFileName($hF);
  my $imgdir   = "$self->{repodir}/${fid}/image";
  my $filepath = "${imgdir}/${filename}";
  unless(-d $imgdir){
    mkdir $imgdir, 0774 || die "can't make image directory.";
  }
  move ($tmppath, $filepath) || die "Upload Error!. $filepath";
  close($hF);

  my $thumbnail = $self->add_thumbnail($fid, $filename);

  my $author = $self->_get_author($self->{s}->param('login'));
  $self->{git}->add_image($filepath, $author);
  $self->{git}->add_image($thumbnail, $author);

  $self->{git}->detach_local();
  push @{$self->{t}->{message}->{info}},  "画像をアップロードしました";
  return 1;
}

############################################################
# 画像のサムネイルを作成
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

############################################################
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

############################################################
#指定の画像ファイルを出力
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
    $type =~ s/.*\.(.*)$/\1/;
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

############################################################
# @param1 uid
# @param2 fid
#
sub get_user_document {
  my $self = shift;
  my $uid  = shift;
  my $fid  = shift;

  my $sql = "select file_name from docx_infos where id = ${fid};";
  my @ary = $self->{dbh}->selectrow_array($sql);
  return unless(@ary);
  my $filename = $ary[0];
  my $filepath = "$self->{repodir}/${fid}/${filename}";

  $self->{git}->attach_local_tmp($uid);

  my $document;
  open my $hF, '<', $filepath || die "failed to read ${filepath}";
  my $pos = 0;
  while (my $length = sysread $hF, $document, 1024, $pos) {
    $pos += $length;
  }
  close $hF;
  $self->{git}->detach_local();

  return $document;
}

############################################################
#ドキュメントデータを構造解析する
# @param1 ドキュメントデータ
# @param2 要素番号
#
sub split_for_md {
  my $self       = shift;
  my $document   = shift;
  my $index      = shift;

  my @partsAry;
  my $parts      = "";
  my $rowdata    = "";
  my $block      = 0;
  my $blockquote = 0;
  my $quote      = 0;
  my $cnt        = $index?$index:0;
  foreach (split(/\n/, $document)) {
    if ( $blockquote && $_ !~ m/^> .*/ ) {
      $blockquote = 0;
      push @partsAry, $parts;
      $rowdata .= "${parts}</div>";
      $parts    = "";
      $cnt++;
    }

    if ( !$block && !$blockquote ) {
      if ( $_ =~ m/^.+$/ ) {
          unless( $_ =~ m/^> .+/ ){
            $block      = 1;
          }else{
            $blockquote = 1;
          }
          $rowdata .= "<div id=\"elm${cnt}\" class=\"Elm\">";
      }
    } else {
      if ( $_ =~ m/^\s*$/ ) {
        $blockquote = 0;
        $block      = 0;
        push @partsAry, $parts;
        $rowdata   .= "${parts}</div>";
        $parts      = "";
        $cnt++;
      } elsif ( !$blockquote && $_ =~ m/^> .*/) {
        $blockquote = 1;
        $block      = 0;
        push @partsAry, $parts;
        $rowdata   .= "${parts}</div>";
        $parts      = "";
        $cnt++;
        $rowdata   .= "<div id=\"elm${cnt}\" class=\"Elm\">";
      } elsif ( $block && $_ =~ m/^(====|----|#+).*/ ) {
        push @partsAry, $parts;
        $rowdata   .= "${parts}</div>";
        $parts      = "";
        $cnt++;
        $rowdata   .= "<div id=\"elm${cnt}\" class=\"Elm\">";
      }
    }

    if ($block || $blockquote || $quote) {
      $parts       .= $_ . "\n";
    }

    if ( $block && $_ =~ m/^(====|----|#+).*/ ) {
      $block = 0;
      push @partsAry, $parts;
      $rowdata     .= "${parts}</div>";
      $parts        = "";
      $cnt++;
    }
  }
  if ($block || $blockquote || $quote) {
    push @partsAry, $parts;
    $rowdata       .= "${parts}</div>";
  }

  return ($rowdata, @partsAry);
}

1;
