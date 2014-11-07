package DocxLog;

use strict; no strict "subs";
use base APPBASE;
use Git::Wrapper;
use Data::Dumper;
use File::Copy;
use File::Basename;
use File::Path;
use Date::Manip;
use NKF;
use MYUTIL;

sub new {
  my $pkg = shift;
  my $base = $pkg->SUPER::new(@_);

  my $hash = {
    repo_prefix => "user_",
  };
  @{$base}{keys %{$hash}} = values %{$hash};

  return bless $base, $pkg;
}

sub setupConfig {
  my $self = shift;

  $self->SUPER::setupConfig();
}

############################################################
#ログイン処理
#
sub login {
  my $self = shift;

  if($self->qParam('login')){
    my $account = $self->qParam('account');
    my $password = $self->qParam('password');

    my $sql = "select id from docx_users where account = '$account' and password = md5('$password') and is_used = true;";
    my @ary = $self->{dbh}->selectrow_array($sql);
    if(@ary){
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
  if($id){
    my $sql = "select account,mail,nic_name,may_admin,may_approve,may_delete from docx_users where id = ${id} and is_used = true;";
    my $ha = $self->{dbh}->selectrow_hashref($sql);
    $self->{user} = {
      account     => $ha->{account},
      mail        => $ha->{mail},
      nic_name    => $ha->{nic_name},
      may_admin   => $ha->{may_admin},
      may_approve => $ha->{may_approve},
      may_delete  => $ha->{may_delete},
    };
  }
}


############################################################
#出力処理
#
sub printPage {
  my $self = shift;

  if($self->{s}->param("login")){
    $self->{t}->{login} = $self->{s}->param("login");
  }
  if($self->{user}){
    $self->{t}->{account} = $self->{user}->{account};
    $self->{t}->{is_admin} = $self->{user}->{may_admin};
    $self->{t}->{is_approve} = $self->{user}->{may_approve};
    $self->{t}->{is_delete} = $self->{user}->{may_delete};
  }

  $self->SUPER::printPage();
}

############################################################
#登録されたファイル一覧の取得
#
sub listupFile {
  my $self = shift;
  my @infos;

  my $sql = "select
  id,file_name,is_used,to_char(created_at,'YYYY-MM-DD hh:mm:ss'),to_char(deleted_at,'YYYY-MM-DD hh:mm:ss')
from docx_infos
where deleted_at is null
order by is_used DESC, created_at desc;";

  my $ary = $self->{dbh}->selectall_arrayref($sql) || $self->errorMessage("DB:Error",1);
  if(@$ary){
    foreach (@$ary)
    {
      my $info = {
        id        => $_->[0],
        file_name => $_->[1],
        is_used   => $_->[2],
        created_at => $_->[3],
        deleted_at => $_->[4],
      };
      push @infos, $info;
    }
    $self->{t}->{infos} = \@infos;
  }
}

sub setupFileinfo {
  my $self = shift;

  my $fid = $self->qParam('fid');
  my $branch = $self->qParam('branch');
  my $ver = $self->qParam('revision');
  return unless($fid);

  my $sql = "select id, file_name, is_used, created_at, deleted_at from docx_infos where id = $fid;";
  my @ary = $self->{dbh}->selectrow_array($sql);
  if(@ary) {
    $self->{t}->{file_name} = $ary[1];
  }

  $self->{t}->{fid} = $fid;
  $self->{t}->{branch} = $branch;
  $self->{t}->{revision} = $ver if($ver);
}

sub gitLog {
  my $self = shift;

  my $fid = $self->qParam("fid");
  my $uid = $self->{s}->param("login");

  my $git = Git::Wrapper->new("$self->{repodir}/$fid");
  my @logary;
  my @userary;
  my $latest_rev = undef;

  #共有リポジトリ(master)
  for ($git->log("master")) {
    my $obj = eval {$_};
    my $rev = $obj->{id};
    $latest_rev = $rev unless($latest_rev);
    $obj->{branch} = "master";
    push @logary, $self->adjustLog($obj);
  }
  $self->{t}->{loglist} = \@logary;

  if($uid){ #ユーザーリポジトリ
    #自分のリポジトリ
    my $my_branch = "$self->{repo_prefix}${uid}";
    my @branches = $git->branch;
    if(MYUTIL::isInclude(\@branches, $my_branch)){
      push @userary, $self->getUserLoglist($git, $my_branch, $uid, $self->{user}->{account}, $latest_rev);
    }

    if($self->{user}->{may_approve}){
      #承認者
      foreach (@branches){
        my $branch = $_;
        $branch =~ s/^[\s\*]*(.*)\s*/\1/;
        next if($branch =~ m/master/);
        next if($branch eq $my_branch);
        my $uuid = $branch;
        $uuid =~ s/$self->{repo_prefix}([0-9]*)/\1/;
        my $userlog = $self->getUserLoglist($git, $branch, $uuid, $self->getAccount($uuid), $latest_rev);
        if($userlog->{is_live} && (@{$userlog->{loglist}} > 0)){
          push @userary, $userlog;
        }
      }
    }
  }
  $self->{t}->{userlist} = \@userary;
}

###################################################
#
sub getBranchRoot{
  my $self = shift;
  my $git = shift;
  my $branch = shift;

  my @branches = $git->show_branch({"sha1-name" => 1}, master, $branch);
  my $last = @branches;
  my $ret = ${branches}[$last - 1];
  $ret =~ s/.* \[([a-z0-9]+)\].*/\1/;

  return $ret;
}

###################################################
#
sub getUserLoglist {
  my $self = shift;
  my $git = shift;
  my $branch = shift;
  my $uid = shift;
  my $account = shift;
  my $latest_rev = shift;
  my $branch_root = $self->getBranchRoot($git, $branch);

  my @logary;
  for($git->log("master.." . $branch)){
    my $obj = eval {$_};
    push @logary, ($self->adjustLog($obj));
  }
  return {
    id       => $uid,
    name     => $account,
    branch   => $branch,
    is_live  => $latest_rev =~ m/^$branch_root[0-9a-z]+/ ?1:0,
    loglist  => \@logary,
  };
}

###################################################
# 承認するために指定したリヴィジョンまでの履歴を取得してテンプレートにセット
#
sub setApproveList {
  my $self = shift;

  my $fid = $self->qParam("fid");
  my $revision = $self->qParam("revision");
  my $uid = $self->{s}->param("login");
#  my $branch = "$self->{repo_prefix}${uid}";
  my $branch = $self->qParam("branch");

  my $git = Git::Wrapper->new("$self->{repodir}/$fid");
  my %loghash;

  my $flg = undef;
  for($git->log("master.." . $branch)){
    my $obj = eval {$_};
    my $rev = $obj->{id};
    if($flg
       || (!$flg && ${rev} eq ${revision}) ){
      $loghash{$rev} = $self->adjustLog($obj);
      $flg = 1 unless($flg);
    }
  }

  $self->{t}->{loglist} = [sort {$b->{attr}->{date} cmp $a->{attr}->{date}} values %loghash];
}

###################################################
#
#
sub docApprove {
  my $self = shift;

  my $fid = $self->qParam("fid");
  my $revision = $self->qParam("revision");
  my $uid = $self->{s}->param("login");
  my $branch = $self->qParam("branch");

  my $git = Git::Wrapper->new("$self->{repodir}/$fid");
  $git->checkout("master");
  my $cnt = 0;
  for($git->log("master.." . $branch)){
    my $obj = eval {$_};
    my $rev = $obj->{id};
    if($rev eq $revision){
      last;
    }
    $cnt++;
  }

  my $branch_rebase = $branch;
  $branch_rebase .= "~${cnt}" if($cnt > 0);

  $git->rebase($branch_rebase);
}


###################################################
# 新規でdocxファイルを登録する
# その際にアップロードしたユーザーブランチを作成
# 同名のファイルを許容する
sub uploadFile {
  my $self = shift;

  my $uid = $self->{s}->param("login");
  return unless($uid);
  my $hF = $self->{q}->upload('docxfile');
  my $filename = basename($hF);
  my $fid = $self->setupNewFile($filename);

  my $tmppath = $self->{q}->tmpFileName($hF);
  my $filepath = $self->{repodir}. "/$fid/$filename";
  move ($tmppath, $filepath) || die "Upload Error!. $filepath";
  close($hF);

  $self->gitInitWith1stCommit($uid, $fid, $filename);
  $self->dbCommit();
}

###################################################
# MDファイルを作る
sub createFile {
  my $self = shift;
  my $uid = $self->{s}->param("login");
  
  my $docname = nkf("-w", $self->qParam('docname'));
  $docname =~ s/^\s*(.*)\s*$/\1/;
  $docname =~ s/\s/_/g;
  $docname =~ s/^(.*)\..*$/\1/;
  return unless($docname);

  my $filename = $docname . "\.md";
  my $fid = $self->setupNewFile($filename);
  my $filepath = $self->{repodir}. "/$fid/$filename";
  open my $hF, ">", $filepath || die "Create Error!. $filepath";
  close($hF);

  $self->gitInitWith1stCommit($uid, $fid, $filename);
  $self->dbCommit();
}

###################################################
#
sub setupNewFile{
  my $self = shift;
  my $filename = shift;

 my $sql_insert = "insert into docx_infos(file_name,created_at) values('$filename',now());";
  $self->{dbh}->do($sql_insert) || $self->errorMessage("DB:Error uploadFile", 1);
  my $sql_newfile = "select currval('docx_infos_id_seq');";
  my @ary_id = $self->{dbh}->selectrow_array($sql_newfile);
  my $fid = $ary_id[0];
  mkdir("./$self->{repodir}/$fid",0776)
    || die "Error:uploadFile can't make a directory($self->{repodir}/$fid)";
  return $fid;
}

###################################################
#
sub gitInitWith1stCommit{
  my $self = shift;
  my $uid = shift;
  my $fid = shift;
  my $filename = shift;

  my $branch = "$self->{repo_prefix}${uid}";
  my $author = $self->getAuthor(${uid});
  my $git = Git::Wrapper->new("$self->{repodir}/$fid");
  $git->init();
  $self->setDocx2Txt($fid);
  $git->add($filename);
  $git->commit({message => "新規追加", author => $author});
  $git->branch($branch);
}

###################################################
# ユーザーのブランチにコミットする
#
sub commitFile {
  my $self = shift;

  my $fid = $self->qParam('fid');
  my $uid = $self->{s}->param("login");
  my $branch = "$self->{repo_prefix}${uid}";

  my $hF = $self->{q}->upload('docxfile');
  my $filename = basename($hF);

  my $sql_check = "select id from docx_infos where file_name = '$filename' and is_used = true;";
  my @ary_check = $self->{dbh}->selectrow_array($sql_check);
  if(!@ary_check || $ary_check[0] != $fid){
    $self->{t}->{error} = "違うファイルがアップロードされました";
    close($hF);
    return;
  }

  my $author = $self->getAuthor($self->{s}->param('login'));
  my $git = Git::Wrapper->new("$self->{repodir}/$fid");

  my @branches = $git->branch;
  if(MYUTIL::isInclude(\@branches, $branch)){
    my $latest_rev  = $self->getBranchRoot($git, "master");
    my $branch_root = $self->getBranchRoot($git, $branch);
    if($latest_rev ne $branch_root){
      #ユーザーの古い履歴は不要なので削除
      $git->branch("-D", $branch);
      $git->branch($branch);
    }
    $git->checkout(${branch});
  }else{
    $git->checkout({b => ${branch}});
  }

  my $tmppath = $self->{q}->tmpFileName($hF);
  my $filepath = $self->{repodir}. "/$fid/$filename";
  move ($tmppath, $filepath) || die "Upload Error!. $filepath";
  close($hF);

  if($git->diff()){
    $git->add($filename);
    $git->commit({message => $self->qParam('detail'), author => $author});
    $git->checkout("master");
  }else{
    $self->{t}->{error} = "ファイルに変更がないため更新されませんでした";
  }
}

sub gitDiff{
  my $self = shift;
  my $fid = $self->qParam('fid');
  my $ver = $self->qParam('revision');
  my $dist = $self->qParam('dist');

  my $git = Git::Wrapper->new("$self->{repodir}/$fid");
  my @difflist;
  my $flg = 0;
  my $cnt = 1;

  $dist = "${ver}^" unless($dist);

  for ($git->diff("$dist..$ver"))
  {
    my $line = eval {$_};
    next if(length($line) == 0);
    next if($line =~ m/^diff --git.*/);
    if($line =~ m/^index /){
      $flg = 0;
      next;
    }
    if($flg == 0 && $line =~ m/--- .*/){
      next;
    }elsif($flg == 0 && $line =~ m/\+\+\+ .*/){
      $flg = 1;
      next;
    }
    if($flg == 1){
      push @difflist, {no => $cnt, content => "$line<br>"};
#    push @difflist, MYUTIL::adjustDiffLine($obj);
      $cnt++;
    }
  }
  $self->{t}->{difflist} = \@difflist;
}

sub setDocx2Txt {
  my $self = shift;
  my $fid = shift;

  my $gitd = "$self->{repodir}/$fid/.git";
  my $attr = "$gitd/info/attributes";
  my $conf = "$gitd/config";

  open(FILE, "> $attr") || die "Error: file can't create.($attr)";
  print FILE "*.docx diff=wordx";
  close(FILE);

  open(FILE, ">> $conf") || die "Error: file can't open. ($conf)";
  print FILE "\n[diff \"wordx\"]\n";
  print FILE "    textconv = docx2txt\n";
  close(FILE);
}

sub changeFileInfo {
  my $self = shift;
  my $ope = shift;

  my $fid = $self->qParam('fid');
  return unless($fid);
  my $sql;

  if($ope =~ m/^use$/){
    $sql = "update docx_infos set is_used = true where id = $fid;";
  }elsif($ope =~ m/^unuse$/){
    $sql = "update docx_infos set is_used = false where id = $fid;";
  }elsif($ope =~ m/^delete$/){
    $sql = "update docx_infos set deleted_at = now() where id = $fid;";
    File::Path::rmtree(["./$self->{repodir}/$fid"]) || die("can't remove a directory: $fid");
  }
  $self->{dbh}->do($sql) || errorMessage("Error:changeFileInfo = $sql");

  $self->dbCommit();
}

sub downloadFile {
  my $self = shift;
  my $fid = shift;
  my $rev = shift;

  my $sql = "select file_name from docx_infos where id = $fid;";
  my @ary = $self->{dbh}->selectrow_array($sql);
  return unless($ary[0]);
  my $filename = $ary[0];
  my $filepath = "./$self->{repodir}/$fid/$filename";

  my $git = Git::Wrapper->new("$self->{repodir}/$fid");
  if($rev){
    $git->checkout($rev);
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

  $git->checkout("master");
}

sub getAccount {
  my $self = shift;
  my $uid = shift;

  my $sql = "select account from docx_users where id = $uid;";
  my @ary = $self->{dbh}->selectrow_array($sql);
  return $ary[0];
}

sub getAuthor {
  my $self = shift;
  my $uid = shift;

  my $sql = "select account || ' <' || mail || '>' from docx_users where id = $uid;";
  my @ary = $self->{dbh}->selectrow_array($sql);
  return $ary[0];
}

sub adjustLog {
  my $self = shift;
  my $obj = shift;

  $obj->{message} =~ s/</&lt;/g;
  $obj->{message} =~ s/>/&gt;/g;
  $obj->{message} =~ s/\n/<br>/g;
  $obj->{message} =~ s/(.*)git-svn-id:.*/\1/;

  $obj->{attr}->{author} =~ s/</&lt;/g;
  $obj->{attr}->{author} =~ s/>/&gt;/g;

  $obj->{attr}->{date} =~ s/^(.*) \+0900/\1/;
  $obj->{attr}->{date} = UnixDate(ParseDate($obj->{attr}->{date}), "%Y-%m-%d %H:%M:%S");

  return $obj;
}


1;
