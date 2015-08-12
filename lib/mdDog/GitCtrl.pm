package GitCtrl;

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

use strict; no strict 'subs';
use Git::Wrapper;
use Date::Manip;
use Data::Dumper;
use MYUTIL;
use Fcntl ':flock';

############################################################
# @param1: 作業ディレクトリ
#
sub new {
    my $pkg = shift;
    my $workdir = shift;

    my $hash = {
        git           => undef,
        workdir       => ${workdir},
        branch_prefix => "user_",
        lock_handle   => undef,
        error         => undef,
        info          => undef,
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
    my $files = shift;
    my $author = shift;

    $self->{git}->init();
    foreach( @$files ){
        $self->{git}->add($_);
    }
    $self->{git}->commit({message => "新規追加", author => $author});
}


############################################################
#共有リポジトリの履歴を返す
# @param1 ソート順(任意)
#
sub get_shared_logs {
    my $self = shift;
    my $desc = shift;
    my @logs;

    foreach( $self->{git}->log("master") ){
        my $obj = eval {$_};
        push @logs, $self->adjust_log($obj);
    }

    if( $desc ){
        @logs = sort{$a->{attr}->{date} cmp $b->{attr}->{date}} @logs;
    }

    return \@logs;
}


############################################################
#ユーザーがリポジトリを所有するか確認
# @param1 uid
# @param2 tmp 編集バッファフラグ
#
sub is_exist_user_branch {
    my $self = shift;
    my $uid  = shift;
    my $tmp  = shift;

    my @branches = $self->{git}->branch;
    my $branch   = $uid?"$self->{branch_prefix}${uid}":"master";
    $branch     .= "_${tmp}" if($tmp);
    return MYUTIL::is_include(\@branches, $branch);
}

############################################################
# 編集バッファが存在するか判定する
# @param1 uid
#
sub is_updated_buffer {
    my $self = shift;
    my $uid = shift;

    my @branches = $self->{git}->branch;
    my $branch = "$self->{branch_prefix}${uid}";
    my $tmp  = "${branch}_tmp";
    if( MYUTIL::is_include(\@branches, $tmp) ){
        if( MYUTIL::is_include(\@branches, $branch) ){
            my @diff = $self->{git}->diff({"name-only" => 1}, "${tmp}..${branch}");
            return @diff;
        }else{
            my @diff = $self->{git}->diff({"name-only" => 1}, "${tmp}..master");
            return @diff;
        }
    }
    return 0;
}

############################################################
#指定のユーザーの共有リポジトリ分岐後の履歴を返す
# @param1 uid
#
sub get_user_logs {
    my $self = shift;
    my $uid = shift;

    my @userlogs;
    my $branch = "$self->{branch_prefix}${uid}";
    for( $self->{git}->log("master.." . $branch) ){
        my $obj = eval {$_};
        $obj->{user} = $uid;
        push @userlogs, $self->adjust_log($obj);
    }

    return \@userlogs;
}

############################################################
#編集リポジトリを所有するユーザー一覧を返す
#
sub get_other_users {
    my $self = shift;
    my @users;

    foreach( $self->{git}->branch ){
        my $branch = $_;
        $branch =~ s/^[\s\*]*(.*)\s*/$1/;
        next if($branch =~ m/master/);

        $branch =~ s/$self->{branch_prefix}(.*)/$1/;
        next if($branch =~ m/[0-9]+_(tmp|info)/ );
#        $branch =~ s/([0-9]+)_tmp/\1/;
        push @users, $branch;
    }

    return @users;
}


############################################################
#共有リポジトリから分岐したリヴィジョンを返す
# @param1 uid
# @param2 編集バッファフラグ:無指定だと通常のユーザーリポジトリを精査
#
sub get_branch_root {
    my ($self, $uid, $isTmp) = @_;

    my $branch = $uid?"$self->{branch_prefix}${uid}":"master";
    $branch .= "_${isTmp}" if( $uid && $isTmp );
    my @branches = $self->{git}->branch;
    return 0 if(!MYUTIL::is_include(\@branches, $branch));

    my @show_branches = $self->{git}->show_branch({"sha1-name" => 1}, "master", $branch);
    my $last = @show_branches;
    my $ret = ${show_branches}[$last - 1];
    $ret =~ s/^.*\[([a-z0-9]+)\].*/$1/;

    return $ret;
}

############################################################
# 最新版のリヴィジョン番号を返す
# @param1 uid
# @param2 編集バッファフラグ:無指定だと通常のユーザーリポジトリを精査
#
sub get_branch_latest {
  my $self = shift;
  my $uid = shift;
  my $isTmp = shift;

  my $branch = $uid?"$self->{branch_prefix}${uid}":"master";
  $branch .= "_tmp" if($uid && $isTmp);
  my @branches = $self->{git}->branch;
  return 0 if(!MYUTIL::is_include(\@branches, $branch));

  my @log_branch = $self->{git}->log($branch, "-n1");
  return $log_branch[0]->id;
}


############################################################
#ドキュメントを承認して共有する
# @param1 uid
# @param2 revision
#
sub approve {
    my ($self, $uid, $revision) = @_;

    my $branch = "$self->{branch_prefix}${uid}";
    my $branch_info = "${branch}_info";
    my $gitctrl = $self->{git};

    my $cnt = 0;
    $self->attach_local();
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
    $self->detach_local();

    $self->remove_info();
    $self->attach_info();
    $gitctrl->rebase(${branch_info});
#    $self->rebase_info($uid);
    $self->detach_local();
}

############################################################
#リヴィジョン間のdiffを取って結果をリストで返す
# @param1 ドキュメント名
# @param2 "バージョン"
# @param3 "比較対象のバージョン":無指定だと前バージョン
#
sub get_diff {
    my ($self, $filename, $ver, $dist) = @_;

    my $gitctrl = $self->{git};
    my @difflist;
    my $flg = 0;
    my $cnt = 1;

    $dist = "${ver}^" unless($dist);

    for ($gitctrl->diff("$dist..$ver", $filename))
    {
        my $line = eval {$_};
        next if(length($line) == 0);
        next if($line =~ m/^diff --git.*/);
        if ($line =~ m/^index /) {
          $flg = 0;
          next;
        }
        if ($flg == 0 && $line =~ m/--- .*/) {
          next;
        } elsif ($flg == 0 && $line =~ m/\+\+\+ .*/) {
          $flg = 1;
          next;
        }
        if ($flg == 1) {
          push @difflist, {no => $cnt, content => "$line"};
          #    push @difflist, MYUTIL::adjust_diff_line($obj);
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
# infoリポジトリにコミット
# @param1 filename
# @param2 "author"
#
sub commit_info {
    my ($self, $filename, $author) = @_;
    my $message  = "#UPDATE INFO#";

    my $gitctrl = $self->{git};
    my @logs    = $gitctrl->log("-n1");
    if( $logs[0]->message =~ m/#UPDATE INFO#/ ){
        if($gitctrl->diff()){
            $gitctrl->add($filename);
            $gitctrl->commit({
                message => $message,
                amend   => 1,
                author  => $author
            });
         }
        else{
            return 0;
        }
    }
    else{
      $gitctrl->add($filename);
        $gitctrl->commit({
                message => $message,
                author  => $author
        });
    }
    return 1;
}

############################################################
#
sub edit_commit_message{
    my ($self, $author, $msg) = @_;
    return unless($msg);

    my $gitctrl = $self->{git};
    $gitctrl->commit({"message" => $msg, "amend" => 1, "author" => $author});
}

############################################################
#
sub rebase_info{
    my ($self, $target) = @_;
    my $br = $target?"$self->{branch_prefix}${target}":"master";

    my $gitctrl = $self->{git};
    $gitctrl->rebase($br);
}

############################################################
#画像ファイルのアップロード
# @param1 画像ファイルの保存ディレクトリ
# @param2 author
#
sub add_image {
  my $self = shift;
  my $imagepath = shift;
  my $author = shift;

  my $gitctrl = $self->{git};
  if ( -f $imagepath ){
    $imagepath =~ s#$self->{workdir}/(.*)$#$1#;
    $gitctrl->add($imagepath);
    $gitctrl->commit({message => "image upload",author => $author});
    return 1;
  }
  return 0;
}

############################################################
#画像ファイルの削除
# @param1 画像ファイル名の配列
# @param2 author
#
sub delete_image {
  my $self = shift;
  my $images = shift;
  my $author = shift;

  my $gitctrl = $self->{git};

  foreach (@$images) {
    if( -f "$self->{workdir}/image/$_" ){
      $gitctrl->rm("image/$_");
    }
    if( -f "$self->{workdir}/thumb/$_" ) {
      $gitctrl->rm("thumb/$_");
    }
  }
  $gitctrl->commit({message => "delete images", author => $author});
}

############################################################
#
sub lock_dir {
  my $self = shift;

  my $lockfile = "$self->{workdir}/\.lock";

  open my $hF, ">", $lockfile || die "Can't create lockfile";
  flock($hF, LOCK_EX);
  $self->{lock_handle} = $hF;
}

############################################################
#
sub unlock_dir {
  my $self = shift;

  flock($self->{lock_handle}, LOCK_UN);
  close $self->{lock_handle};
  $self->{lock_handle} = undef;
}

############################################################
#ユーザーリポジトリを用意する
# @param1 uid
# @param2 isCreate: 1だと強制でリポジトリ作成
#
sub attach_local {
  my $self = shift;
  my $uid = shift;
  my $isCreate = shift;

  $self->lock_dir();

  my $gitctrl = $self->{git};
  my @branches = $gitctrl->branch;
  my $branch = $uid?"$self->{branch_prefix}${uid}":"master";

  if(MYUTIL::is_include(\@branches, $branch)){
    if($isCreate){
      my $latest_rev  = $self->get_branch_root();
      my $branch_root = $self->get_branch_root($uid);
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
sub attach_local_tmp {
    my ($self, $uid, $isCreate) = @_;

    $self->lock_dir();

    my $gitctrl    = $self->{git};
    my @branches   = $gitctrl->branch;
    my $branch     = "$self->{branch_prefix}${uid}";
    my $branch_tmp = "$self->{branch_prefix}${uid}_tmp";

    my $flg     = MYUTIL::is_include(\@branches, $branch);
    my $flg_tmp = MYUTIL::is_include(\@branches, $branch_tmp);

    if( $flg && $flg_tmp ){
        if( $self->get_branch_root($uid) ne $self->get_branch_root($uid, "tmp") ){
            $gitctrl->branch("-D", $branch_tmp);
            $gitctrl->checkout($branch);
            $gitctrl->checkout({b => $branch_tmp}) if($isCreate);
        }else{
            $gitctrl->checkout($branch_tmp);
        }
    }elsif( $flg && !$flg_tmp ){
        $gitctrl->checkout($branch);
        $gitctrl->checkout({b => $branch_tmp}) if($isCreate);
    }elsif( !$flg && $flg_tmp ){
        if( $self->get_branch_root() ne $self->get_branch_root($uid, "tmp") ){
            $gitctrl->branch("-D", $branch_tmp);
            $gitctrl->checkout({b => $branch_tmp}) if( $isCreate );
        }else{
            $gitctrl->checkout($branch_tmp);
        }
    }else{
        $gitctrl->checkout({b => $branch_tmp}) if($isCreate);
    }
}


############################################################
# 情報バッファを用意する
# @param1 uid
# @param2 isCreate: 1だと編集バッファを強制で作成
#
sub attach_info {
    my ($self, $uid) = @_;

    $self->lock_dir();

    my $gitctrl     = $self->{git};
    my @branches    = $gitctrl->branch;
    my $branch      = $uid?"$self->{branch_prefix}${uid}":"master";
    my $branch_info = "${branch}_info";

    if( MYUTIL::is_include(\@branches, $branch_info) ){
        $gitctrl->checkout($branch_info);
    }
    elsif( MYUTIL::is_include(\@branches, $branch) ){
        $gitctrl->checkout($branch);
        $gitctrl->checkout({b => $branch_info}); # userリポジトリから
    }
    else{
        $gitctrl->checkout({b => $branch_info});
    }
}

############################################################
#attach_localまたはattach_local_tmpの呼出し後、処理の最後に必ず呼ぶこと
#
sub detach_local {
  my $self = shift;

  $self->{git}->reset({hard => 1}, "HEAD");
  $self->{git}->checkout("master");

  $self->unlock_dir();

}


############################################################
#編集バッファをユーザーリポジトリに反映
# @param1 uid 
# @param2 "author"
# @param3 "commit message"
#
sub fix_tmp {
    my $self    = shift;
    my $uid     = shift;
    my $author  = shift;
    my $message = shift;

    my $ret;
    my $branch     = "$self->{branch_prefix}${uid}";
    my $branch_tmp = "${branch}_tmp";
    my $branch_info = "${branch}_info";
    my $gitctrl    = $self->{git};

    $self->lock_dir();

    my @branches = $gitctrl->branch;
    unless(MYUTIL::is_include(\@branches, $branch_tmp)){
        $self->{error} .= "編集バッファが見つかりません";
        return 0;
    }
    $gitctrl->branch($branch) unless(MYUTIL::is_include(\@branches, $branch));

    my @logs_tmp = ($gitctrl->log($branch . ".." . $branch_tmp));
    if(@logs_tmp > 0){
        my $cnt = @logs_tmp;
        $gitctrl->checkout($branch_tmp);
        $gitctrl->reset({soft => 1}, "HEAD~${cnt}");
        if($gitctrl->diff({cached => 1})){
            $gitctrl->commit({message => $message, author => $author});
        }else{
            $ret = "データの変更が見つからないのでコミットされませんでした";
            $self->{info} .= "データの変更が見つからないのでコミットされませんでした";
        }
        $gitctrl->checkout($branch);
        $gitctrl->rebase($branch_tmp);    #ユーザーリポジトリに反映

        $gitctrl->checkout($branch_info);
        $gitctrl->rebase($branch);        #infoリポジトリに反映

        $gitctrl->checkout("master");
    }
    $gitctrl->branch("-D", $branch_tmp);
    $self->unlock_dir();
    return 1;
}

############################################################
#
sub reset_buffer {
    my $self       = shift;
    my $uid        = shift;
    my $branch_tmp = "$self->{branch_prefix}${uid}_tmp";

    if( $self->is_exist_user_branch($uid, 'tmp') ){
        $self->lock_dir();
        $self->{git}->branch("-D", $branch_tmp);
        $self->unlock_dir();
    }
    return 1;
}

#
#
sub remove_info {
    my ($self, $uid) = @_;
    my $br = $uid?"$self->{branch_prefix}${uid}_info":"master_info";

    if( $self->is_exist_user_branch($uid, "info") ){
        $self->lock_dir();
        $self->{git}->branch("-D", $br);
        $self->unlock_dir();
      }
}


############################################################
#指定のリヴィジョンにリポジトリを変更する
#使用後にはdetach_localを呼ぶこと
#
# @param1 リヴィジョン
#
sub checkout_version {
  my $self = shift;
  my $rev = shift;
  
  $self->{git}->checkout($rev);
}

############################################################
# @param1 リヴィジョン
#
sub one_log {
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
#
sub rollback_buffer {
    my ($self, $revision) = @_;

    $self->{git}->reset("${revision}^", {hard=>1});
}


############################################################
#
sub clear_tmp {
    my ($self, $uid) = @_;

    my $branch     = "$self->{branch_prefix}${uid}";
    my $branch_tmp = "${branch}_tmp";

    $self->lock_dir();
    $self->{git}->branch("-D", $branch_tmp);
    $self->unlock_dir();
    return 1;
}

############################################################
#gitのログを適切な文字列に整形
# @param1 ログオブジェクト
#
sub adjust_log {
  my $self = shift;
  my $obj = shift;

  $obj->{sha1_name} = $obj->{id};
  $obj->{sha1_name} =~ s/^(.{7}).*/$1/;

  $obj->{raw}     = $obj->{message};
  $obj->{message} =~ s/</&lt;/g;
  $obj->{message} =~ s/>/&gt;/g;
  $obj->{message} =~ s/\n/<br>/g;
  $obj->{message} =~ s/(.*)git-svn-id:.*/$1/;

  $obj->{attr}->{author} =~ s/(.*) <.*>/$1/;
#  $obj->{attr}->{author} =~ s/</&lt;/g;
#  $obj->{attr}->{author} =~ s/>/&gt;/g;

  $obj->{attr}->{date} =~ s/^(.*) \+0900/$1/;
#  $obj->{attr}->{date} = UnixDate(ParseDate($obj->{attr}->{date}), "%Y-%m-%d %H:%M:%S");
  my $date = $obj->{attr}->{date};

  $obj->{attr}->{date} = MYUTIL::format_date2(ParseDate($date));
  $obj->{cdate} = MYUTIL::format_date3(ParseDate($date));

  return $obj;
}

1;
