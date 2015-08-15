
package mdDog::API;

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
use parent mdDog;
use Text::Markdown::MdDog qw/markdown paragraph_html paragraph_raw alter_paragraph paragraphs/;
use Digest::MD5 qw/md5 md5_hex/;

use constant USER_AUTH_ADMIN   => 1;
use constant USER_AUTH_APPROVE => 2;
use constant USER_AUTH_DELETE  => 3;

############################################################
#[API] JSONを返す
#
sub get_data {
    my $self = shift;
    my $uid = $self->{s}->param("login");
    return unless($uid);
    my $fid = $self->qParam('fid') + 0;
    my $eid = $self->qParam('eid') + 0;
    my $data;

    if ($self->qParam('action') eq 'image_list') {
        $self->{git}->attach_local_tmp($uid);
        my $imgdir = "$self->{repodir}/${fid}/image";
        if ( -d $imgdir) {
            my @images = glob "$imgdir/*";
            $self->{git}->detach_local();

            foreach (@images) {
                my $path = $_;
                $path =~ s#$self->{repodir}/${fid}/image/(.*)$#\1#g;
                push @$data, {filename => $path};
            }
        }
    } else {
        my $document = $self->_get_user_document($uid, $fid);
        if ( $eid >= 0) {
            my $raw = paragraph_raw($document, $eid);
            my $html = paragraph_html($document, $eid);
            $raw  =~ s#\(plugin/image_viewer\.cgi\?(.*)\)#(plugin/image_viewer.cgi?tmp=1&\1)#g;
            $html =~ s#\(plugin/image_viewer\.cgi\?(.*)\)#(plugin/image_viewer.cgi?tmp=1&\1)#g;
            $data = [{eid => ${eid}, raw => ${raw}, html => ${html}}];
        } else {
            my $cnt = 0;
            while ( my $ret = paragraph_raw($document, $cnt) ) {
                last if( $ret =~ m/^\n/ );
                $ret  =~ s#\(plugin/image_viewer\.cgi\?(.*)\)#(plugin/image_viewer.cgi?tmp=1&\1)#g;
                push @$data, { eid => ${cnt}, raw => ${ret} };
                $cnt++;
            }
        }
    }
    my $json = JSON->new();
    return $json->encode($data);
}

############################################################
#[API]
#
sub update_paragraph {
    my $self = shift;
    my $uid = $self->{s}->param("login");
    return unless($uid);
    my $fid = $self->qParam('fid') + 0;
    my $eid = $self->qParam('eid') + 0;
    my $data = $self->qParam('data');
    $data .= "\n" if( $data !~ m/(.*)\n*$/);
#    $data .= "\n" if( $data !~ m/(.*)\n\n$/);

    my $document = $self->_get_user_document($uid, $fid);
    $document = alter_paragraph(length($document)>0?$document:"", $eid, $data);

    #ファイル書き込み
    my $filepath = "$self->{repodir}/${fid}/$self->{filename}";
    $self->{git}->attach_local_tmp($uid, 1);
    open my $hF, '>', $filepath || return undef;
    syswrite $hF, $document, length($document);
    close $hF;

    my $author = $self->_get_author($self->{s}->param('login'));
    $self->{git}->commit($self->{filename}, $author, "temp saved");
    $self->{git}->detach_local();

    my $mds;
    my $cnt = 0;
    my $raws = paragraphs($data);

    foreach ( @$raws ) {
        my $raw = $_;
        my $md = markdown($raw);
        $md =~ s#"plugin/image_viewer\.cgi\?(.*)"#"plugin/image_viewer.cgi?tmp=1&\1"#g;
        push @$mds, {md => $md, raw => $raw};
        $cnt++;
    }

    $self->{git}->attach_info($uid);
    $self->{outline}->slide_down_divide($eid, $cnt - 1);
    $self->{git}->commit_info($self->{outline}->{filename}, $author);
    $self->{git}->detach_local();

    my $json = JSON->new();
    return $json->encode($mds);
}

############################################################
#[API]
#
sub delete_paragraph {
    my $self = shift;
    my $uid = $self->{s}->param("login");
    return unless($uid);
    my $fid = $self->qParam('fid') + 0;
    my $eid = $self->qParam('eid') + 0;
    my $document = $self->_get_user_document($uid, $fid);

    $document = alter_paragraph($document, $eid, "");

    $self->{git}->attach_local_tmp($uid, 1);

    #ファイル書き込み
    my $filepath = "$self->{repodir}/${fid}/$self->{filename}";
    open my $hF, '>', $filepath || return undef;
    syswrite $hF, $document, length($document);
    close $hF;

    my $author = $self->_get_author($self->{s}->param('login'));
    $self->{git}->commit($self->{filename}, $author, "temp saved");
    $self->{git}->detach_local();

    $self->{git}->attach_info($uid);
    $self->{outline}->slide_up_divide($eid);
    $self->{git}->commit_info($self->{outline}->{filename}, $author);
    $self->{git}->detach_local();

    my $raw = paragraph_raw($self->_get_user_document($uid, $fid), $eid);

    my $json = JSON->new();
    return $json->encode({eid => ${eid}, raw => $raw });
}

############################################################
#[API] アウトラインで改ページを加える
#
sub outline_add_divide {
    my $self = shift;

    my $uid = $self->{s}->param("login");
    return unless($uid);
    my $fid = $self->qParam('fid') + 0;

    my $num = $self->qParam('num');
    my $author = $self->_get_author($self->{s}->param('login'));
    my $comment = "INSERT DIVIDE";
    #  $self->{git}->attach_local_tmp($uid, 1);
    $self->{git}->attach_info($uid);
    $self->{outline}->insert_divide($num, $comment);
    #  $self->{git}->commit($self->{outline}->{filename}, $author, $comment);
    $self->{git}->commit_info($self->{outline}->{filename}, $author);
    $self->{git}->detach_local();
    my $json = JSON->new();
    return $json->encode({action => 'divide',num => ${num}});
}

############################################################
#[API] アウトラインに設定された改ページを削除する
#
sub outline_remove_divide {
    my $self = shift;

    my $uid = $self->{s}->param("login");
    return unless($uid);
    my $fid = $self->qParam('fid') + 0;

    my $num = $self->qParam('num');
    my $author = $self->_get_author($self->{s}->param('login'));
    my $comment = "REMOVE DIVIDE";
    #  $self->{git}->attach_local_tmp($uid, 1);
    $self->{git}->attach_info($uid);
    $self->{outline}->remove_divide($num);
    $self->{git}->commit_info($self->{outline}->{filename}, $author);
    $self->{git}->detach_local();
    my $json = JSON->new();
    return $json->encode({action => 'undivide',num => ${num}});
}

############################################################
#[API] 指定のrevisionのJSONデータを返す
#
sub get_revisiondata {
    my $self = shift;
    my $fid  = $self->qParam("fid");

    $self->_set_filename($fid);
    my $filepath = "$self->{repodir}/${fid}/$self->{filename}";
    my $document;
    my $revision = $self->qParam('revision');
    my $user = $self->qParam('user');
    $user = undef if($user == 0);

    my $gitctrl = $self->{git};

    my $user_root = $gitctrl->get_branch_latest($user);
    $revision = $user_root unless($revision);
    my $oneLog = $gitctrl->one_log($revision);

    $gitctrl->attach_local($user);
    $gitctrl->checkout_version($revision);

    open my $hF, '<', $filepath || die "failed to read ${filepath}";
    my $pos = 0;
    while (my $length = sysread $hF, $document, 1024, $pos) {
        $pos += $length;
    }
    close $hF;

    $gitctrl->detach_local();
    my $json = JSON->new();
    return $json->encode({
        name => $self->{filename},
        document => markdown($document),
        revision => $revision,
        commitDate => MYUTIL::format_date1($oneLog->{attr}->{date}),
        commitMessage => $oneLog->{message},
    });
}

############################################################
#[API] 指定のrevisionの差分を返す
#
sub get_diff {
    my $self = shift;
    my $fid = $self->qParam('fid');
    $self->_set_filename($fid);

    my $revision = $self->qParam('revision');
    my $dist     = $self->qParam('dist');
    my $diff     = $self->{git}->get_diff($self->{filename}, $revision, $dist);

    my $json = JSON->new();
    return $json->encode({
        name     => $self->{filename},
        revision => $revision,
        dist     => $dist?$dist:'ひとつ前',
        diff    => $diff,
    });
}

############################################################
#[API]
sub restruct_document {
    my $self = shift;
    my $fid = $self->qParam('fid');
    my $doc = $self->qParam('doc');
    my $uid = $self->{s}->param("login");
    return unless( $fid && $uid );

    my $gitctrl = $self->{git};
    my $oldlogs = $gitctrl->get_user_logs($uid);
    my $log;
    foreach(@$oldlogs){
      $log .= $_->{attr}->{date} . ": " . $_->{raw};
      $log .= "====\n";
    }

    $gitctrl->attach_local($uid, 1);

    $self->_set_filename($fid);
    my $filepath = "$self->{repodir}/${fid}/$self->{filename}";
    open my $hF, '>', $filepath || return undef;
    syswrite $hF, $doc, length($doc);
    close $hF;

    my $author = $self->_get_author($self->{s}->param('login'));
    $self->{git}->commit($self->{filename}, $author, $log);

    $gitctrl->detach_local();

    my $json = JSON->new();
    return $json->encode({fid => $fid, uid => $uid, log => $log});
}

############################################################
#[API] アカウントの追加
#
sub add_account {
    my $self = shift;

    my $account  = $self->qParam('account');
    my $nicname  = $self->qParam('nicname');
    my $mail     = $self->qParam('mail');
    my $password = $self->qParam('password');
    return unless( $account && $nicname && $mail && $password);

    my $row = $self->{teng}->insert('docx_users' => {
        'account'    => $account,
        'nic_name'   => $nicname,
        'mail'       => $mail,
        'password'   => md5_hex(${password}),
        'created_at' => 'now()',
     });
    $self->dbCommit();
    my $json = JSON->new();
    return $json->encode({
        id          => $row->id,
        account     => $row->account,
        nic_name    => $row->nic_name,
        mail        => $row->mail,
        may_approve => $row->may_approve,
        may_admin   => $row->may_admin,
        may_delete  => $row->may_delete,
        is_used     => $row->is_used,
        created_at  => MYUTIL::format_date3($row->created_at)
    });
}

############################################################
#[API] ユーザーの使用・不使用切り替え
#
sub user_used {
    my $self    = shift;

    my $uid     = $self->qParam('uid');
    my $checked = $self->qParam('is_used') eq '1'?'true':'false';

    $self->{teng}->update('docx_users' => {
        is_used => ${checked}
    }, {
        id     => $uid
    });
    $self->dbCommit();

    my $sth  = $self->{dbh}->prepare(SQL::user_info);
    $sth->execute($uid);
    my $infos = $sth->fetchrow_hashref();
    $sth->finish();

    my $json = JSON->new();
    return $json->encode({
        id          => $infos->{id},
        account     => $infos->{account},
        nic_name    => $infos->{nic_name},
        mail        => $infos->{mail},
        may_approve => $infos->{may_approve},
        may_admin   => $infos->{may_admin},
        may_delete  => $infos->{may_delete},
        is_used     => $infos->{is_used},
        created_at  => MYUTIL::format_date3($infos->{created_at})
    });
}

############################################################
#[API] 管理ユーザーの切り替え
#
sub user_admin {
    my $self = shift;
    $self->_user_auth(USER_AUTH_ADMIN);
}

############################################################
#[API]
#
sub user_approve {
    my $self = shift;
    $self->_user_auth(USER_AUTH_APPROVE);
}

############################################################
#[API]
#
sub user_delete {
    my $self = shift;
    $self->_user_auth(USER_AUTH_DELETE);
}

############################################################
# ユーザーの権限フラグの制御
#
sub _user_auth {
    my $self    = shift;
    my $type    = shift;

    my $uid     = $self->qParam('uid');
    my $checked = $self->qParam('checked') eq '1'?'true':'false';
    my $col;
    if(     $type == USER_AUTH_ADMIN ){
        $col = 'may_admin';
    }elsif( $type == USER_AUTH_APPROVE ){
        $col = 'may_approve';
    }elsif( $type == USER_AUTH_DELETE ){
        $col = 'may_delete';
    }

    $self->{teng}->update('docx_users' => {
        ${col} => $checked
    }, {
        id => $uid
    });
    $self->dbCommit();

    my $sth  = $self->{dbh}->prepare(SQL::user_info);
    $sth->execute($uid);
    my $infos = $sth->fetchrow_hashref();
    $sth->finish();

    my $json = JSON->new();
    return $json->encode({
        id          => $infos->{id},
        account     => $infos->{account},
        nic_name    => $infos->{nic_name},
        mail        => $infos->{mail},
        may_approve => $infos->{may_approve},
        may_admin   => $infos->{may_admin},
        may_delete  => $infos->{may_delete},
        is_used     => $infos->{is_used},
        created_at  => MYUTIL::format_date3($infos->{created_at})
    });
}

############################################################
#[API]
#
sub document_user_add {
    my $self  = shift;

    my $fid   = $self->qParam('fid');
    my @users = $self->qParam('users[]');
    my $uid   = $self->{s}->param('login');

    my $ar_insert;
    my $sql = SQL::user_info;
    $sql =~ s/ id = \?/ id IN (/;

    my $i = 0;
    foreach(@users) {
      push @$ar_insert, {
          info_id    => $fid,
          user_id    => $_,
          created_at => 'now()',
          created_by => $uid,
          updated_at => 'now()'
      };

      $sql .= "," if($i > 0);
      $sql .= $_;
      $i++;
    }
    $sql .= ')';

    $self->{teng}->bulk_insert('docx_auths', $ar_insert);
    $self->dbCommit();

    my $data = $self->{dbh}->selectall_arrayref($sql, +{Slice => {}})
      || die("DB Error+ document_user_add select");

    my $json = JSON->new();
    return $json->encode($data);
}

############################################################
#[API]
#
sub document_user_delete {
    my $self  = shift;

    my $fid   = $self->qParam('fid');
    my @users = $self->qParam('users[]');
    my $uid   = $self->{s}->param('login');

    return unless( @users );

    my $sql_delete = << "SQL";
DELETE FROM docx_auths
WHERE
  info_id = ${fid}
  AND user_id in (
SQL

    my $sql = SQL::user_info;
    $sql =~ s/ id = \?/ id IN (/;

    my $i = 0;
    foreach(@users) {
        $sql_delete .= ',' if( $i > 0 );
        $sql_delete .= $_;

        $sql .= ',' if( $i > 0);
        $sql .= $_;
        $i++;
    }
    $sql_delete .= ')';
    $sql        .= ')';

    $self->{dbh}->do($sql_delete)
      || die("DB Error: document_user_delete");
    $self->dbCommit();

    my $data = $self->{dbh}->selectall_arrayref($sql, +{Slice => {}})
      || die("DB Error+ document_user_add select");


    my $json = JSON->new();
    return $json->encode($data);
}

############################################################
#[API]
#
sub document_user_may_approve {
    my $self = shift;

    my $fid   = $self->qParam('fid');
    my $uid   = $self->qParam('uid');
    my $checked = $self->qParam('checked')?'true':'false';

    $self->{teng}->update('docx_auths' => {
        may_approve => $checked
    }, {
        info_id => $fid,
        user_id => $uid
    });

    $self->dbCommit();

    my $sth = $self->{dbh}->prepare(SQL::auth_info);
    $sth->execute($fid, $uid);
    my $info = $sth->fetchrow_hashref();

    my $json = JSON->new();
    return $json->encode($info);
}

############################################################
#[API]
#
sub document_user_may_edit {
    my $self    = shift;

    my $fid     = $self->qParam('fid');
    my $uid     = $self->qParam('uid');
    my $checked = $self->qParam('checked')?'true':'false';

    $self->{teng}->update('docx_auths' => {
        may_edit => $checked
    }, {
        info_id => $fid,
        user_id => $uid
    });
    $self->dbCommit();

    my $sth = $self->{dbh}->prepare(SQL::auth_info);
    $sth->execute($fid, $uid);
    my $info = $sth->fetchrow_hashref();

    my $json = JSON->new();
    return $json->encode($info);
}

############################################################
#[API]
#
sub document_change_public {
    my $self = shift;

    my $fid       = $self->qParam('fid');
    my $is_public = $self->qParam('is_public')?'true':'false';

    $self->{teng}->update('docx_infos' => {
        is_public => $is_public
    }, {
        id => $fid
    });
    $self->dbCommit();

    my $sth = $self->{dbh}->prepare(SQL::document_info);
    $sth->execute($fid);
    my $info = $sth->fetchrow_hashref();

    my $json = JSON->new();
    return $json->encode($info);
}

############################################################
#[API]
#
sub rollback_buffer {
    my $self     = shift;
    my $fid      = $self->qParam('fid');
    my $revision = $self->qParam('revision');
    my $uid      = $self->{s}->param('login');

    my $gitctrl  = $self->{git};
    unless( $gitctrl->is_exist_user_branch($uid, 'tmp') ){
        $gitctrl->attach_local_tmp($uid, 'create tmp');
        $gitctrl->detach_local();
    }
    $gitctrl->attach_local($uid);
    $gitctrl->rollback_buffer($revision);
    $gitctrl->detach_local();

#    my $logs = $gitctrl->get_user_logs($uid);
    my $json = JSON->new();
    return $json->encode({action => 'reset', revision => $revision});
}

############################################################
#[API]
#
sub edit_log {
    my $self     = shift;
    my $fid      = $self->qParam('fid');
    my $revision = $self->qParam('revision');
    my $comment  = $self->qParam('comment');
    my $uid      = $self->{s}->param('login');

    return unless( $fid && $uid && $comment );
    my $author   = $self->_get_author($uid);
    my $gitctrl = $self->{git};

    $gitctrl->attach_local($uid);
    $gitctrl->edit_commit_message($author, $comment);
    $gitctrl->detach_local();

    my $json = JSON->new();
    return $json->encode({fid => $fid, comment => $comment});
}

############################################################
#[API]
#
sub clear_user_buffer {
    my $self = shift;
    my $fid  = $self->qParam('fid');
    my $uid  = $self->{s}->param('login');

    return unless( $fid && $uid );
    my $gitctrl = $self->{git};

    return unless( $gitctrl->clear_tmp($uid) );

    my $document = $self->_get_user_document($uid, $fid);
    my $md       = markdown($document);
    $md =~ s#"plugin/image_viewer\.cgi\?(.*)"#"plugin/image_viewer.cgi?tmp=1&$1" #g;
    my $rows     = paragraphs($document);

    my $json = JSON->new();
    return $json->encode({md => $md, rows => $rows});
}


#
#
sub get_groups {
    my $self = shift;

    if( $self->qParam('fid') ){
      return $self->get_doc_groups();
    }

    my $sql = SQL::group_list;
    $sql   .= " ORDER BY title ";

    my $ar = $self->{dbh}->selectall_arrayref($sql, +{Slice =>{}})
      || die("SQL Error: in 'get_groups' $sql");
    my $json = JSON->new();
    return $json->encode($ar);
}

#--------------------------------------------------
#
#--------------------------------------------------
sub get_doc_groups {
    my $self = shift;
    my $fid = $self->qParam('fid') + 0;

    return unless( $fid );

    my $sql = SQL::doc_group_list;
    $sql   .= s/\?/${fid}/;
    my $ar = $self->{dbh}->selectall_arrayref($sql, +{Slice =>{}})
      || die("SQL Error: in 'get_doc_groups'");
    my $json = JSON->new();
    return $json->encode($ar);
}

#--------------------------------------------------
#
#--------------------------------------------------
sub search_groups{
    my $self = shift;
    my $search = $self->qParam('search');
    return unless( $search );

    my $sql = SQL::group_list;
    $sql   .= "WHERE title like '%${search}%'";

    my $ary = $self->{dbh}->selectall_arrayref($sql, +{Slice =>{}});
    $ary = "[]" unless( $ary );
    my $json = JSON->new();
    return $json->encode($ary);
}

#--------------------------------------------------
#
#--------------------------------------------------
sub add_groups {
    my $self = shift;
    my @groups = $self->qParam('groups[]');
#    return unless( @groups );
    my $fid    = $self->qParam('fid') + 0;
    my $uid    = $self->{s}->param('login');
    my $g_type   = 1;

    #グループの登録
    for (@groups) {
        my $groupname = $_;
        my $sql_check = SQL::group_list;
        $sql_check   .= " WHERE title = '${groupname}'";
        if( $self->{dbh}->selectrow_arrayref($sql_check) ){
            next;
        }

        $self->{teng}->insert('mddog_groups' => {
            title      => $groupname,
            type       => $g_type,
            created_by => $uid,
            created_at => 'now()',
            updated_at => 'now()'
        });
    }

    #ドキュメントのグループ設定付け（一旦消してから再登録）
    $self->{teng}->delete('mddog_doc_group', {
        doc_id => $fid
    });

    if( @groups ){
        my $values = "";
        for( @groups ){
            $values .= ',' if ( $values =~ m/^\(.*\).*/ );
            $values .= "(${fid}, (select id from mddog_groups where title = '$_'))";
        }

        my $sql_groupadd = << "SQL";
INSERT INTO mddog_doc_group(doc_id, group_id) VALUES ${values}
SQL
        $self->{dbh}->do($sql_groupadd);
    }

    # 不使用のグループは削除
    my $sql_clean = << "SQL";
DELETE FROM mddog_groups
WHERE id not in (
  SELECT group_id FROM mddog_doc_group GROUP BY group_id
)
SQL
    $self->{dbh}->do($sql_clean);

    $self->{dbh}->commit();

    my $length = @groups;
    my $json = JSON->new();
    return $json->encode(\@groups);
}

1;
