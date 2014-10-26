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

  my $id = $self->{s}->param("login");

  if($self->qParam('login')){
    my $account = $self->qParam('account');
    my $password = $self->qParam('password');

    my $sql = "select id from docx_users where account = '$account' and password = md5('$password');";
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
}


############################################################
#出力処理
#
sub printPage {
  my $self = shift;

  if($self->{s}->param("login")){
    $self->{t}->{login} = $self->{s}->param("login");
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
  return unless($fid);

  my $sql = "select id, file_name, is_used, created_at, deleted_at from docx_infos where id = $fid;";
  my @ary = $self->{dbh}->selectrow_array($sql);
  if(@ary) {
    $self->{t}->{fid} = $ary[0];
    $self->{t}->{file_name} = $ary[1];
  }
}

sub gitLog {
  my $self = shift;

  my $fid = $self->qParam("fid");
  my $git = Git::Wrapper->new("$self->{repodir}/$fid");
  my @loglist;
  my $cnt = 0;
  for ($git->log)
  {
    my $obj = eval {$_};
    $obj->{message} =~ s/\n/<br>/g;
    $obj->{message} =~ s/(.*)git-svn-id:.*/\1/;

    $obj->{attr}->{date} =~ s/^(.*) \+0900/\1/;
    $obj->{attr}->{date} = UnixDate(ParseDate($obj->{attr}->{date}), "%Y-%m-%d %H:%M:%S");

    push @loglist, $obj;
    $cnt++;
  }
  $loglist[$cnt - 1]->{is_first} = 1;
  $self->{t}->{loglist} = \@loglist;
}

sub uploadFile {
  my $self = shift;

  my $hF = $self->{q}->upload('docxfile');
  my $filename = basename($hF);
  my $sql_check = "select count(*) from docx_infos where file_name = '$filename' and is_used = true;";
  my @ary_check = $self->{dbh}->selectrow_array($sql_check);
  if($ary_check[0] > 0){
    close($hF);
    $self->{t}->{error} = "同名のファイルが既に登録済です。";
    return;
  }

  my $sql_insert = "insert into docx_infos(file_name,created_at) values('$filename',now());";
  $self->{dbh}->do($sql_insert) || $self->errorMessage("DB:Error uploadFile", 1);
  my $sql_newfile = "select id from docx_infos where file_name = '$filename' and is_used = true;";
  my @ary_id = $self->{dbh}->selectrow_array($sql_newfile);
  my $fid = $ary_id[0];
  mkdir("./$self->{repodir}/$fid",0776)
    || die "Error:uploadFile can't make a directory($self->{repodir}/$fid)";

  my $tmppath = $self->{q}->tmpFileName($hF);
  my $filepath = $self->{repodir}. "/$fid/$filename";
  move ($tmppath, $filepath) || die "Upload Error!. $filepath";
  close($hF);

  my $git = Git::Wrapper->new("$self->{repodir}/$fid");
  $git->init();
  $self->setDocx2Txt($fid);
  $git->add($filename);
  $git->commit({message => "新規追加"});

  $self->dbCommit();
}

sub commitFile {
  my $self = shift;

  my $fid = $self->qParam('fid');

  my $hF = $self->{q}->upload('docxfile');
  my $filename = basename($hF);

  my $sql_check = "select id from docx_infos where file_name = '$filename' and is_used = true;";
  my @ary_check = $self->{dbh}->selectrow_array($sql_check);
  if(!@ary_check || $ary_check[0] != $fid){
    $self->{t}->{error} = "違うファイルがアップロードされました";
    close($hF);
    return;
  }

  my $tmppath = $self->{q}->tmpFileName($hF);
  my $filepath = $self->{repodir}. "/$fid/$filename";
  move ($tmppath, $filepath) || die "Upload Error!. $filepath";
  close($hF);

  my $git = Git::Wrapper->new("$self->{repodir}/$fid");
  if($git->diff()){
    $git->add($filename);
    $git->commit({message => $self->qParam('detail')});
  }else{
    $self->{t}->{error} = "ファイルに変更がないため更新されませんでした";
  }
}

sub gitDiff{
  my $self = shift;
  my $fid = $self->qParam('fid');
  my $ver = $self->qParam('revision');

  my $git = Git::Wrapper->new("$self->{repodir}/$fid");
  my @difflist;
  my $flg = 0;
  my $cnt = 1;

  for ($git->diff("$ver^..$ver"))
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
  $self->{t}->{revision} = $ver;
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

1;
