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
#use File::Copy;
#use File::Basename;
use File::Path;
use Date::Manip;
use Text::Markdown::MdDog qw/markdown paragraph_html paragraph_raw alter_paragraph paragraphs/;
use Cwd;
use Image::Magick;
use JSON;
use MYUTIL;
use GitCtrl;
use OutlineCtrl;
use SQL;

use model::User;
use model::Docinfo;
use model::DocGroup;

# @summary constructor
#
sub new {
    my $pkg   = shift;
    my $base  = $pkg->SUPER::new(@_);

    my $hash  = {
        repo_prefix => "user_",
        git         => undef,
        outline     => undef,

        filename    => undef,
    };
    @{$base}{keys %{$hash}} = values %{$hash};

    return bless $base, $pkg;
}

# @summary need to call at first
#
sub setup_config {
    my ($self, $fid) = @_;

    if( $fid ){
        my $workdir = "$self->{repodir}/" . $fid;
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

        $self->{userinfo} = mdDog::model::User->new();
        $self->{userinfo}->set_row($ha);

        $sth->finish();
        return $id;
    }
    return 0;
}


# @summary 出力処理
#
sub print_page {
    my $self = shift;
    my $ref = shift;

    if( $ref ){
        foreach (keys %$ref){
            $self->{t}->{$_} = $ref->{$_};
        }
    }

    if($self->{s}->param("login")){
        $self->{t}->{login}      = $self->{s}->param("login");
    }
    if($self->{userinfo}){ #ユーザー情報をセット
        $self->{t}->{userinfo} = $self->{userinfo};
    }

    $self->SUPER::print_page();
}


# @summary
#  - ユーザーが編集・承認を行なうページへのログインを行なう
#  - 条件を満たさないと適宜ページにリダイレクトする
#
sub login_user_document {
  my ($self, $fid) = @_;

  unless($fid) {
      print "Location: index.cgi\n\n";
      exit();
  }
  my $uid;
  if( my $uid = $self->login() ){
      return $uid;
  }

  print "Location: doc_history.cgi?fid=${fid}\n\n";
  exit();
}

# @summary 権限チェック
#
sub check_auths {
    my ($self, $uid, $fid)  = @_;

    if( $uid ){
        my $sth = $self->{dbh}->prepare(SQL::auth_info);
        $sth->execute($fid, $uid);
        if( my $row = $sth->fetchrow_hashref() ){
            $self->{userinfo}->set_docACL($row, $uid);
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
    my ($self, $uid, $page, $style, $group) = @_;

    my $offset = $page * $self->{paging_top};
    my @infos;
    my ($sql, $sql_cnt);

    if( $uid ){
        $sql     = SQL::list_for_index($uid, $style,
                                   $offset, $self->{paging_top}, $group);
        $sql_cnt = SQL::document_list($uid, $style, $group);
    }else{ #ログインなし
        $sql     = SQL::list_for_index_without_login($offset, $self->{paging_top}, $group);
        $sql_cnt = SQL::document_list_without_login($group);
    }

    my $ary = $self->{dbh}->selectall_arrayref($sql, +{Slice => {}})
       || $self->errorMessage("DB:Error",1);
    if( @$ary ){
        my $prev_obj = undef;
        foreach( @$ary ) {
            my $logs = GitCtrl->new("$self->{repodir}/$_->{id}")->get_shared_logs();

            if( $prev_obj && $prev_obj->{fid} eq $_->{id} ){
                push @{$prev_obj->{groups}}, mdDog::model::DocGroup->new(
                    gid  => $_->{gid},
                    name => $_->{group_title}
                );
                next;
            }

            my $info = mdDog::model::Docinfo->new();
            $info->set_row($_);
            $info->{is_owned}  = $uid && $_->{created_by}==${uid}?1:0;
            $info->{file_size} = -s $self->{repodir} . "/$_->{id}/$_->{file_name}";
            $info->{last_updated_at} = $logs->[0]->format_datetime;

            if( $_->{group_title} ){
                push @{$info->{groups}}, mdDog::model::DocGroup->new(
                    gid  => $_->{gid},
                    name => $_->{group_title}
                );
            }
            push @infos, $info;
            $prev_obj = $info;
        }
    }
    my $rows = $self->{dbh}->selectall_arrayref($sql_cnt)
      || $self->viewAccident("DB:Error", 1);
    my $cnt = @$rows;
    my $pages = $cnt / $self->{paging_top};
    my $paging;
    for( my $i = 0; $i < $pages; $i++ ){
        push @$paging, $i;
    }

    return (\@infos, $cnt, $paging);
}

# @summary ファイルの使用状態を更新
# @param 'use'/'unuse'/'delete'
#
sub change_file_info {
    my ($self, $ope) = @_;

    my $fid  = $self->qParam('fid');
    return unless($fid);        # NULL CHECK
    my ($is_used, $deleted_at) = (undef, undef);

    if($ope =~ m/^use$/){
        $is_used = 'true';
    }elsif($ope =~ m/^unuse$/){
        $is_used = 'false';
    }elsif($ope =~ m/^delete$/){
        $deleted_at = 'now()';
    }
    $self->{teng}->update('docx_infos' => {
        is_used    => $is_used,
        deleted_at => $deleted_at
    },{
        id => $fid
    });

    $self->dbCommit();

    if( $deleted_at ){
        File::Path::rmtree(["./$self->{repodir}/$fid"])
              || die("can't remove a directory: $fid");
    }
}

# @summary 指定のバージョンのドキュメントをダウンロード出力する
# @param1 fid
# @param2 rev
#
sub download_file {
    my ($self, $fid, $rev) = @_;

    my $sth = $self->{dbh}->prepare(SQL::document_info);
    $sth->execute($fid);
    my $row = $sth->fetchrow_hashref();
    return unless($row);
    my $filename = $row->{file_name};
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


# @param1 uid
#
sub _get_account {
    my $self = shift;
    my $uid  = shift;

    my $sth  = $self->{dbh}->prepare(SQL::user_info);
    $sth->execute($uid);
    my $ary = $sth->fetchrow_hashref();
    my $account = $ary->{account};
    $sth->finish();

    return $account;
}


# @param1 uid
#
sub _get_nic_name {
    my $self = shift;
    my $uid  = shift;

    my $sth  = $self->{dbh}->prepare(SQL::user_info);
    $sth->execute($uid);
    my $ary = $sth->fetchrow_hashref();
    my $nic_name = $ary->{nic_name};
    $sth->finish();

    return $nic_name;
}

# @summary gitで登録する著者名を返す
# @param1 uid
#
sub _get_author {
    my $self = shift;
    my $uid  = shift;

    my $sth  = $self->{dbh}->prepare(SQL::user_info);
    $sth->execute($uid);
    my $ary = $sth->fetchrow_hashref();
    my $author = "$ary->{nic_name} <$ary->{mail}>";
    $sth->finish();

    return $author;
}

# @summary 指定の画像ファイルを出力
#
sub print_image {
    my ($self, $uid, $fid, $image, $thumbnail, $tmp, $size, $master) = @_;
    return unless($image && $fid); # NULL CHECK
    $uid = undef if($uid && $master);

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

# @summary ファイル名をセットする
# @param fid
# @return 正常に終了なら1を返す
sub _set_filename {
    my ($self, $fid) = @_;
    return undef unless($fid);

    unless( $self->{filename} ){
        my $sth = $self->{dbh}->prepare(SQL::document_info);
        $sth->execute($fid);
        my $row = $sth->fetchrow_hashref();
        return undef unless($row);
        $self->{filename} = $row->{file_name};
        $sth->finish();
    }
    return 1;
}

# @summary 指定のユーザーの編集中のドキュメントの内容を返す
# @param1 uid
# @param2 fid
# @return ドキュメントの内容の文字列
sub _get_user_document {
    my ($self, $uid, $fid) = @_;

    $self->_set_filename($fid);
    my $filepath = "$self->{repodir}/${fid}/$self->{filename}";
    $self->{git}->attach_local_tmp($uid);
    my($document, $pos) = MYUTIL::_fread($filepath);
    $self->{git}->detach_local();

    return $document;
}

# @summary グループの一覧を取得してテンプレートにセット
#
sub listup_groups {
    my $self = shift;

    my $sql = SQL::group_list;
    $sql   .= " ORDER BY title ";
    my $ar = $self->{dbh}->selectall_arrayref($sql, +{Slice =>{}})
      || errorMessage("SQL Error: listup_groups");
    my $grouplist;
    my $selected = $self->param_or_cookie("index", "group");

    foreach(@$ar){
        my $group = mdDog::model::DocGroup->new(
            gid  => $_->{id},
            name => $_->{title}
        );
        if( $selected && $selected == $group->{gid} ){
            $group->{selected} = 1;
        }
        push @$grouplist, $group;
    }

    return $grouplist;
#    $self->{t}->{grouplist} = $grouplist;
}

# @summary  任意の値をクエリパラメータから取得、クエリパラメータになければクッキーから取得して返す
# @param    プレフィックス
# @param    キー
# @return 　値
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
