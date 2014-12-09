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

############################################################
#ユーザーリポジトリを作成
# @param1 fid
# @param2 "filename"
# @param3 "author"
#
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


############################################################
#共有リポジトリの履歴を返す
#
sub getSharedLogs {
  my $self = shift;
  my @logs;

  foreach ($self->{git}->log("master")){
    my $obj = eval {$_};
    push @logs, $self->adjustLog($obj);
  }
  return \@logs;
}


############################################################
#ユーザーがリポジトリを所有するか確認
# @param1 uid
#
sub isExistUserBranch {
  my $self = shift;
  my $uid = shift;

  my @branches = $self->{git}->branch;
  my $branch = "$self->{branch_prefix}${uid}";
  return MYUTIL::isInclude(\@branches, $branch);
}

############################################################
#指定のユーザーの共有リポジトリ分岐後の履歴を返す
# @param1 uid
#
sub getUserLogs {
  my $self = shift;
  my $uid = shift;

  my @userlogs;
  my $branch = "$self->{branch_prefix}${uid}";
  for($self->{git}->log("master.." . $branch)){
    my $obj = eval {$_};
    $obj->{user} = $uid;
    push @userlogs, $self->adjustLog($obj);
  }

  return \@userlogs;
}

############################################################
#編集リポジトリを所有するユーザー一覧を返す
# @param uid
#
sub getOtherUsers {
  my $self = shift;
  my $uid = shift;
  my @users;

  foreach ($self->{git}->branch) {
     my $branch = $_;
     $branch =~ s/^[\s\*]*(.*)\s*/\1/;
     next if($branch =~ m/master/);

     $branch =~ s/$self->{branch_prefix}(.*)/\1/;
     next if($branch =~ m/[0-9]+_tmp/ );
#     $branch =~ s/([0-9]+)_tmp/\1/;
     next if($branch eq $uid);
     push @users, $branch;
  }
  return @users;
}


############################################################
#共有リポジトリから分岐したリヴィジョンを返す
# @param1 uid
# @param2 編集バッファフラグ:無指定だと通常のユーザーリポジトリを精査
#
sub getBranchRoot {
  my $self = shift;
  my $uid = shift;
  my $isTmp = shift;

  my $branch = $uid?"$self->{branch_prefix}${uid}":"master";
  $branch .= "_tmp" if($uid && $isTmp);
  my @branches = $self->{git}->branch;
  return 0 if(!MYUTIL::isInclude(\@branches, $branch));

  my @show_branches = $self->{git}->show_branch({"sha1-name" => 1}, "master", $branch);
  my $last = @show_branches;
  my $ret = ${show_branches}[$last - 1];
  $ret =~ s/^.*\[([a-z0-9]+)\].*/\1/;

  return $ret;
}

############################################################
# 最新版のリヴィジョン番号を返す
#
sub getBranchLatest {
  my $self = shift;
  my $uid = shift;
  my $isTmp = shift;

  my $branch = $uid?"$self->{branch_prefix}${uid}":"master";
  $branch .= "_tmp" if($uid && $isTmp);
  my @branches = $self->{git}->branch;
  return 0 if(!MYUTIL::isInclude(\@branches, $branch));

  my @log_branch = $self->{git}->log($branch, "-n1");
  return $log_branch[0]->id;
}


############################################################
#ドキュメントを承認して共有する
# @param1 uid
# @param2 revision
#
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

############################################################
#リヴィジョン間のdiffを取って結果をリストで返す
# @param1 "バージョン"
# @param2 "比較対象のバージョン":無指定だと前バージョン
#
sub getDiff {
  my $self = shift;
  my $ver = shift;
  my $dist = shift;

  my $gitctrl = $self->{git};
  my @difflist;
  my $flg = 0;
  my $cnt = 1;

  $dist = "${ver}^" unless($dist);

  for ($gitctrl->diff("$dist..$ver"))
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
  return \@difflist;
}

############################################################
#リポジトリにコミット
# @param1 filename
# @param2 "author"
# @param3 "commit message"
#
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

############################################################
#画像ファイルのアップロード
#
sub addImage {
  my $self = shift;
  my $imagepath = shift;
  my $author = shift;

  my $gitctrl = $self->{git};
  if ( -f $imagepath ){
  $imagepath =~ s#$self->{workdir}/(.*)$#\1#;
    $gitctrl->add($imagepath);
    $gitctrl->commit({message => "image upload",author => $author});
    return 1;
  }
  return 0;
}

############################################################
#ユーザーリポジトリを用意する
# @param1 uid
# @param2 isCreate: 1だと強制でリポジトリ作成
#
sub attachLocal {
  my $self = shift;
  my $uid = shift;
  my $isCreate = shift;

  my $gitctrl = $self->{git};
  my @branches = $gitctrl->branch;
  my $branch = $uid?"$self->{branch_prefix}${uid}":"master";

  if(MYUTIL::isInclude(\@branches, $branch)){
    if($isCreate){
      my $latest_rev  = $self->getBranchRoot();
      my $branch_root = $self->getBranchRoot($uid);
      if($latest_rev ne $branch_root){
        #ユーザーの古い履歴は不要なので削除
        $gitctrl->branch("-D", $branch);
        $gitctrl->branch($branch);
      }
    }
    $gitctrl->checkout(${branch});
  }elsif($isCreate){
    $gitctrl->checkout({b => ${branch}});
  }
}

############################################################
#編集バッファを用意する
# @param1 uid
# @param2 isCreate: 1だと編集バッファを強制で作成
#
sub attachLocal_tmp {
  my $self = shift;
  my $uid = shift;
  my $isCreate = shift;

  my $gitctrl = $self->{git};
  my @branches = $gitctrl->branch;
  my $branch     = "$self->{branch_prefix}${uid}";
  my $branch_tmp = "$self->{branch_prefix}${uid}_tmp";

  my $flg = MYUTIL::isInclude(\@branches, $branch);
  my $flg_tmp = MYUTIL::isInclude(\@branches, $branch_tmp);

  if($flg && $flg_tmp){
    if($self->getBranchRoot($uid) ne $self->getBranchRoot($uid, 1)){
      $gitctrl->branch("-D", $branch_tmp);
      $gitctrl->checkout($branch);
      $gitctrl->checkout({b => $branch_tmp}) if($isCreate);
    }else{
      $gitctrl->checkout($branch_tmp);
    }
  }elsif($flg && !$flg_tmp){
    $gitctrl->checkout($branch);
    $gitctrl->checkout({b => $branch_tmp}) if($isCreate);
  }elsif(!$flg && $flg_tmp){
    if($self->getBranchRoot() ne $self->getBranchRoot($uid, 1)){
      $gitctrl->branch("-D", $branch_tmp);
      $gitctrl->checkout({b => $branch_tmp}) if($isCreate);
    }else{
      $gitctrl->checkout($branch_tmp);
    }
  }else{
    $gitctrl->checkout({b => $branch_tmp}) if($isCreate);
  }
}

############################################################
#attachLocalまたはattachLocal_tmpの呼出し後、処理の最後に必ず呼ぶこと
#
sub detachLocal {
  my $self = shift;

  $self->{git}->reset({hard => 1}, "HEAD");
  $self->{git}->checkout("master");
}


############################################################
#編集バッファをユーザーリポジトリに反映
# @param1 uid 
# @param2 "author"
# @param3 "commit message"
#
sub fixTmp {
  my $self = shift;
  my $uid = shift;
  my $author = shift;
  my $message = shift;

  my $branch = "$self->{branch_prefix}${uid}";
  my $branch_tmp = "${branch}_tmp";
  my $gitctrl = $self->{git};

  my @branches = $gitctrl->branch;
  return unless(MYUTIL::isInclude(\@branches, $branch_tmp));
  $gitctrl->branch($branch) unless(MYUTIL::isInclude(\@branches, $branch));

  my @logs_tmp = ($gitctrl->log($branch . ".." . $branch_tmp));
  if(@logs_tmp > 0){
    my $cnt = @logs_tmp;
    $gitctrl->checkout($branch_tmp);
    $gitctrl->reset({soft => 1}, "HEAD~${cnt}");
    $gitctrl->commit({message => $message, author => $author});
    $gitctrl->checkout($branch);
    $gitctrl->rebase($branch_tmp);
    $gitctrl->checkout("master");
  }
  $gitctrl->branch("-D", $branch_tmp);
}

############################################################
#指定のリヴィジョンにリポジトリを変更する
#使用後にはdetachLocalを呼ぶこと
#
# @param1 リヴィジョン
#
sub checkoutVersion {
  my $self = shift;
  my $rev = shift;
  
  $self->{git}->checkout($rev);
}

############################################################
#
sub oneLog {
  my $self = shift;
  my $revision = shift;

  my @logs = $self->{git}->log($revision, "-n1");
  for (@logs) {
    my $obj = eval {$_};
    return $obj;
  }
  return undef;
}

############################################################
#gitのログを適切な文字列に整形
# @param1 ログオブジェクト
#
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
#  $obj->{attr}->{date} = UnixDate(ParseDate($obj->{attr}->{date}), "%Y-%m-%d %H:%M:%S");
  $obj->{attr}->{date} = MYUTIL::formatDate2(ParseDate($obj->{attr}->{date}));

  return $obj;
}

############################################################
#gitリポジトリでdocxモジュールを使う準備
# @param1 fid
#
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
