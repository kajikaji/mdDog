
package mdDogAPI;

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
        my $document = $self->get_user_document($uid, $fid);
        if ( $eid >= 0) {
            my $raw = paragraph_raw($document, $eid);
            my $html = paragraph_html($document, $eid);
            $raw  =~ s#\(md_imageView\.cgi\?(.*)\)#(md_imageView.cgi?tmp=1&\1)#g;
            $html =~ s#\(md_imageView\.cgi\?(.*)\)#(md_imageView.cgi?tmp=1&\1)#g;
            $data = [{eid => ${eid}, raw => ${raw}, html => ${html}}];
        } else {
            my $cnt = 0;
            while ( my $ret = paragraph_raw($document, $cnt) ) {
                last if( $ret =~ m/^\n/ );
                $ret  =~ s#\(md_imageView\.cgi\?(.*)\)#(md_imageView.cgi?tmp=1&\1)#g;
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
sub post_data {
    my $self = shift;
    my $uid = $self->{s}->param("login");
    return unless($uid);
    my $fid = $self->qParam('fid') + 0;
    my $eid = $self->qParam('eid') + 0;
    my $data = $self->qParam('data');
    $data .= "\n" if( $data !~ m/(.*)\n*$/);
#    $data .= "\n" if( $data !~ m/(.*)\n\n$/);

    my $document = $self->get_user_document($uid, $fid);
    $document = alter_paragraph(length($document)>0?$document:"", $eid, $data);

    #ファイル書き込み
    # TODO: ファイル名取得ルーチンが重複！
    my $sql = "select file_name from docx_infos where id = ${fid};";
    my @ary = $self->{dbh}->selectrow_array($sql);
    return unless(@ary);
    my $filename = $ary[0];
    my $filepath = "$self->{repodir}/${fid}/${filename}";

    $self->{git}->attach_local_tmp($uid, 1);
    open my $hF, '>', $filepath || return undef;
    syswrite $hF, $document, length($document);
    close $hF;

    my $author = $self->_get_author($self->{s}->param('login'));
    $self->{git}->commit($filename, $author, "temp saved");

    my $mds;
    my $cnt = 0;
    my $raws = paragraphs($data);

    foreach ( @$raws ) {
        my $raw = $_;
        my $md = markdown($raw);
        $md =~ s#"md_imageView\.cgi\?(.*)"#"md_imageView.cgi?tmp=1&\1"#g;
        push @$mds, {md => $md, raw => $raw};
        $cnt++;
    }

    my $comment = "SLIDE_DOWN DIVIDE";
    $self->{outline}->slide_down_divide($eid, $cnt - 1);
    $self->{git}->commit($self->{outline}->{filename}, $author, $comment);

    $self->{git}->detach_local();

    my $json = JSON->new();
    return $json->encode($mds);
}

############################################################
#[API]
#
sub delete_data {
    my $self = shift;
    my $uid = $self->{s}->param("login");
    return unless($uid);
    my $fid = $self->qParam('fid') + 0;
    my $eid = $self->qParam('eid') + 0;
    my $document = $self->get_user_document($uid, $fid);

    $document = alter_paragraph($document, $eid, "");

    $self->{git}->attach_local_tmp($uid, 1);

    #ファイル書き込み
    # TODO: ファイル名取得ルーチンが重複！
    my $sql = "select file_name from docx_infos where id = ${fid};";
    my @ary = $self->{dbh}->selectrow_array($sql);
    return unless(@ary);
    my $filename = $ary[0];
    my $filepath = "$self->{repodir}/${fid}/${filename}";

    open my $hF, '>', $filepath || return undef;
    syswrite $hF, $document, length($document);
    close $hF;

    my $author = $self->_get_author($self->{s}->param('login'));
    $self->{git}->commit($filename, $author, "temp saved");

    my $comment = "SLIDE_UP DIVIDE";
    $self->{outline}->slide_up_divide($eid);
    $self->{git}->commit($self->{outline}->{filename}, $author, $comment);

    $self->{git}->detach_local();

    my $raw = paragraph_raw($self->get_user_document($uid, $fid), $eid);

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
  $self->{git}->attach_local_tmp($uid, 1);
  $self->{outline}->insert_divide($num, $comment);
  $self->{git}->commit($self->{outline}->{filename}, $author, $comment);
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
  $self->{git}->attach_local_tmp($uid, 1);
  $self->{outline}->remove_divide($num);
  $self->{git}->commit($self->{outline}->{filename}, $author, $comment);
  $self->{git}->detach_local();
  my $json = JSON->new();
  return $json->encode({action => 'undivide',num => ${num}});
}

############################################################
#[API] 指定のrevisionのJSONデータを返す
#
sub get_revisiondata {
  my $self = shift;

  my $fid = $self->qParam('fid');
  my $sql = "select file_name from docx_infos where id = ${fid};";
  my @ary = $self->{dbh}->selectrow_array($sql);
  return unless(@ary);

  my $filename = $ary[0];
  my $filepath = "$self->{repodir}/${fid}/${filename}";
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
      name => $filename,
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
  my $sql = "SELECT file_name FROM docx_infos WHERE id = ${fid};";
  my @ary = $self->{dbh}->selectrow_array($sql);
  return unless(@ary);

  my $filename = $ary[0];
  my $revision = $self->qParam('revision');
  my $dist     = $self->qParam('dist');
  my $diff     = $self->{git}->get_diff($filename, $revision, $dist);

  my $json = JSON->new();
  return $json->encode({
      name     => $filename,
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

    my $sql = "select file_name from docx_infos where id = ${fid};";
    my @ary = $self->{dbh}->selectrow_array($sql);
    return unless(@ary);
    my $filename = $ary[0];
    my $filepath = "$self->{repodir}/${fid}/${filename}";

    open my $hF, '>', $filepath || return undef;
    syswrite $hF, $doc, length($doc);
    close $hF;

    my $author = $self->_get_author($self->{s}->param('login'));
    $self->{git}->commit($filename, $author, $log);

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

    my $sql_insert = << "SQL";
INSERT INTO docx_users
  (account, nic_name, mail, password, created_at)
VALUES
  ('${account}', '${nicname}', '${mail}', md5('${password}'), now())
SQL

    $self->{dbh}->do($sql_insert)
      || die("DB Error: add account");
    $self->dbCommit();

    my $sql = << "SQL";
SELECT * FROM docx_users
WHERE id = currval('docx_users_id_seq')
SQL
    my $infos = $self->{dbh}->selectrow_hashref($sql)
      || die("DB Error: get new account", 1);

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
#[API] ユーザーの使用・不使用切り替え
#
sub user_used {
    my $self    = shift;

    my $uid     = $self->qParam('uid');
    my $checked = $self->qParam('is_used') eq '1'?'t':'f';

    my $sql_update = << "SQL";
UPDATE docx_users
SET is_used = '${checked}'
WHERE id = ${uid};
SQL

    $self->{dbh}->do($sql_update)
      || die("DB Error: user_used changed");
    $self->dbCommit();

    my $sql = << "SQL";
SELECT * FROM docx_users WHERE id = ${uid}
SQL
    my $infos = $self->{dbh}->selectrow_hashref($sql);
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
    my $checked = $self->qParam('checked') eq '1'?'t':'f';
    my $col;
    if(     $type == USER_AUTH_ADMIN ){
        $col = 'may_admin';
    }elsif( $type == USER_AUTH_APPROVE ){
        $col = 'may_approve';
    }elsif( $type == USER_AUTH_DELETE ){
        $col = 'may_delete';
    }

    my $sql_update = << "SQL";
UPDATE docx_users
SET ${col} = '${checked}'
WHERE id = ${uid};
SQL

    $self->{dbh}->do($sql_update)
      || die("DB Error: user_used changed");
    $self->dbCommit();

    my $sql = << "SQL";
SELECT * FROM docx_users WHERE id = ${uid}
SQL
    my $infos = $self->{dbh}->selectrow_hashref($sql);
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

    my $sql_insert = << "SQL";
INSERT INTO
  docx_auths(info_id, user_id, created_at, created_by, updated_at)
VALUES
SQL
    my $sql = "SELECT id,account,nic_name FROM docx_users WHERE id IN (";

    my $i = 0;
    foreach(@users) {
      $sql_insert .= "," if( $i > 0 );
      $sql_insert .= "(${fid}, $_, now(), ${uid}, now())";

      $sql .= "," if($i > 0);
      $sql .= $_;
      $i++;
    }
    $sql .= ')';

    $self->{dbh}->do($sql_insert)
      || die("DB Error: document_user_add");

    my $data = $self->{dbh}->selectall_arrayref($sql, +{Slice => {}})
      || die("DB Error+ document_user_add select");

    $self->dbCommit();

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
    my $sql = "SELECT id,account,nic_name FROM docx_users WHERE id IN (";

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

    my $data = $self->{dbh}->selectall_arrayref($sql, +{Slice => {}})
      || die("DB Error+ document_user_add select");

    $self->dbCommit();

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
    my $checked = $self->qParam('checked')?'t':'f';

    my $sql_update = << "SQL";
UPDATE docx_auths
SET may_approve = '${checked}'
WHERE
  info_id = ${fid}
  AND user_id = ${uid};
SQL
    $self->{dbh}->do($sql_update)
      || die("DB Error: document_user_may_approve");

    my $sql = "SELECT * FROM docx_auths WHERE info_id = ${fid} AND user_id = ${uid}";
    my $info = $self->{dbh}->selectrow_hashref($sql)
      || die("DB Error: document_user_may_approve select ${sql}");
    $self->dbCommit();

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
    my $checked = $self->qParam('checked')?'t':'f';

    my $sql_update = << "SQL";
UPDATE docx_auths
SET may_edit = '${checked}'
WHERE
  info_id = ${fid}
  AND user_id = ${uid};
SQL
    $self->{dbh}->do($sql_update)
      || die("DB Error: document_user_may_edit");

    my $sql = "SELECT * FROM docx_auths WHERE info_id = ${fid} AND user_id = ${uid}";
    my $info = $self->{dbh}->selectrow_hashref($sql)
      || die("DB Error: document_user_may_edit select ${sql}");
    $self->dbCommit();

    my $json = JSON->new();
    return $json->encode($info);
}

############################################################
#[API]
#
sub document_change_public {
    my $self = shift;

    my $fid       = $self->qParam('fid');
    my $is_public = $self->qParam('is_public')?'t':'f';

    my $sql_update = << "SQL";
UPDATE docx_infos
SET is_public = '${is_public}'
WHERE
  id = ${fid};
SQL

    $self->{dbh}->do($sql_update)
      || die("DB Error: document_change_public");

    my $sql = "SELECT * FROM docx_infos WHERE id = ${fid}";
    my $info = $self->{dbh}->selectrow_hashref($sql)
      || die("DB Error: document_change_public select ${sql}");
    $self->dbCommit();

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

    my $document = $self->get_user_document($uid, $fid);
    my $md       = markdown($document);
    $md =~ s#"md_imageView\.cgi\?(.*)"#"md_imageView.cgi?tmp=1&$1" #g;
    my $rows     = paragraphs($document);

    my $json = JSON->new();
    return $json->encode({md => $md, rows => $rows});
}

#--------------------------------------------------
#
#--------------------------------------------------
sub get_groups {
    my $self = shift;

    if( $self->qParam('fid') ){
      return $self->get_doc_groups();
    }

    my $sql = << "SQL";
SELECT * FROM mddog_groups ORDER BY title
SQL

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

    my $sql = << "SQL";
SELECT
  g.*
FROM
  mddog_groups g
LEFT OUTER JOIN mddog_doc_group dg ON g.id = dg.group_id
WHERE
  dg.doc_id = ${fid}
SQL
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

    my $sql = << "SQL";
SELECT
  *
FROM mddog_groups
WHERE
  title like '%${search}%'
SQL
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
      my $sql_check = "SELECT * FROM mddog_groups WHERE title = '${groupname}'";
      if( $self->{dbh}->selectrow_arrayref($sql_check) ){
        next;
      }
      my $sql_insert = << "SQL";
INSERT INTO mddog_groups
(title, type, created_by, created_at, updated_at)
 VALUES
('${groupname}', ${g_type}, ${uid}, now(), now() )
SQL
      $self->{dbh}->do($sql_insert);
    }

    #ドキュメントのグループ設定付け（一旦消してから再登録）
    my $sql_groupdelete = "DELETE FROM mddog_doc_group WHERE doc_id = ${fid}";
    $self->{dbh}->do($sql_groupdelete);

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
