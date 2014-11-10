package GitCtrl;

use strict; no strict 'subs';
use Git::Wrapper;
use Date::Manip;
use Data::Dumper;
use MYUTIL;

sub new {
  my $pkg = shift;
  my $workdir = shift;

  my $hash = {
    git         => undef,
    workdir     => ${workdir},
    branch_prefix => "user_",
  };

  $hash->{git} = Git::Wrapper->new($hash->{workdir}) if($workdir);

  return bless $hash, $pkg;
}

sub init{
  my $self = shift;
  my $fid = shift;
  my $filename = shift;
  my $author = shift;

  $self->{git}->init();
  $self->setDocx2Txt($fid) if($filename =~ m/.*\.docx$/);
  $self->{git}->add($filename);
  $self->{git}->commit({message => "新規追加", author => $author});
}


sub getSharedLogs {
  my $self = shift;
  my @logs;

  foreach ($self->{git}->log("master")){
    my $obj = eval {$_};
    push @logs, $self->adjustLog($obj);
  }
  return \@logs;
}


sub isExistUserBranch {
  my $self = shift;
  my $uid = shift;

  my @branches = $self->{git}->branch;
  my $branch = "$self->{branch_prefix}${uid}";
  return MYUTIL::isInclude(\@branches, $branch);
}

sub getUserLogs {
  my $self = shift;
  my $uid = shift;

  my @userlogs;
  my $branch = "$self->{branch_prefix}${uid}";
  for($self->{git}->log("master.." . $branch)){
    my $obj = eval {$_};
    push @userlogs, $self->adjustLog($obj);
  }

  return \@userlogs;
}

sub getOtherUsers {
  my $self = shift;
  my $uid = shift;
  my @users;

  foreach ($self->{git}->branch) {
     my $branch = $_;
     $branch =~ s/^[\s\*]*(.*)\s*/\1/;
     next if($branch =~ m/master/);

     $branch =~ s/$self->{branch_prefix}(.*)/\1/;
     $branch =~ s/([0-9]+)_tmp/\1/;
     next if($branch eq $uid);
     push @users, $branch;
  }
  return @users;
}


sub getBranchRoot {
  my $self = shift;
  my $uid = shift;

  my $branch = $uid?"$self->{branch_prefix}${uid}":"master";
#  if($uid) { $branch = "$self->{branch_prefix}${uid}"; }
#  else { $branch= "master" };

  my @branches = $self->{git}->show_branch({"sha1-name" => 1}, "master", $branch);
  my $last = @branches;
  my $ret = ${branches}[$last - 1];
  $ret =~ s/^.*\[([a-z0-9]+)\].*/\1/;

  return $ret;
}

sub approve {
  my $self = shift;
  my $uid = shift;
  my $revision = shift;

  my $branch = "$self->{branch_prefix}${uid}";
  my $gitctrl = $self->{git};

  my $cnt = 0;
  $gitctrl->checkout("master");
  for($gitctrl->log("master.." . $branch)){
    my $obj = eval {$_};
    my $rev = $obj->{id};
    if($rev eq $revision){
      last;
    }
    $cnt++;
  }
  my $branch_rebase = $branch;
  $branch_rebase .= "~${cnt}" if($cnt > 0);

  $gitctrl->rebase($branch_rebase);
}

sub commit {
  my $self = shift;
  my $filename = shift;
  my $author = shift;
  my $message = shift;

  my $gitctrl = $self->{git};
  if($gitctrl->diff()){
    $gitctrl->add($filename);
    $gitctrl->commit({message => $message, author => $author});
    return 1;
  }
  return 0;
}

sub attachLocal {
  my $self = shift;
  my $uid = shift;

  my $gitctrl = $self->{git};
  my @branches = $gitctrl->branch;
  my $branch = "$self->{branch_prefix}${uid}";

  if(MYUTIL::isInclude(\@branches, $branch)){
    my $latest_rev  = $self->getBranchRoot();
    my $branch_root = $self->getBranchRoot($uid);
    if($latest_rev ne $branch_root){
      #ユーザーの古い履歴は不要なので削除
      $gitctrl->branch("-D", $branch);
      $gitctrl->branch($branch);
    }
    $gitctrl->checkout(${branch});
  }else{
    $gitctrl->checkout({b => ${branch}});
  }
}

sub detachLocal {
  my $self = shift;

  $self->{git}->reset({hard => 1}, "HEAD");
  $self->{git}->checkout("master");
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

sub setDocx2Txt {
  my $self = shift;
  my $fid = shift;

  my $gitd = "$self->{workdir}/.git";
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

1;
