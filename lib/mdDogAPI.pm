package mdDogAPI;

#
# author: gm2bv
# date: 2015/1/14
#

use strict; no strict "subs";
use base mdDog;
use Text::Markdown::Discount qw(markdown);

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
  my $fid = $self->qParam('fid');
  my $eid = $self->qParam('eid');
  my $data;

  if($self->qParam('action') eq 'image_list'){
      $self->{git}->attach_local_tmp($uid);
      my $imgdir = "$self->{repodir}/${fid}/image";
      if( -d $imgdir){
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
      my ($rowdata, @partsAry) = $self->split_for_md($document);
      my $cnt = 0;

      foreach (@partsAry) {
          if ($eid) {
              if ($eid == $cnt) {
                  $data = [{eid => ${cnt}, data => $_}];
                  last;
              }
          } else {
              push @$data, { eid => ${cnt}, data => $_ };
          }
          $cnt++;
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
  $data .= "\n" if( $data !~ m/(.*)\n$/);
  $data .= "\n" if( $data !~ m/(.*)\n\n$/);
  my $document = $self->get_user_document($uid, $fid);
  my ($rowdata, @partsAry) = $self->split_for_md($document);

  $self->{git}->attach_local_tmp($uid, 1);

  #ファイル書き込み
  # TODO: ファイル名取得ルーチンが重複！
  my $sql = "select file_name from docx_infos where id = ${fid};";
  my @ary = $self->{dbh}->selectrow_array($sql);
  return unless(@ary);
  my $filename = $ary[0];
  my $filepath = "$self->{repodir}/${fid}/${filename}";

  open my $hF, '>', $filepath || return undef;
  my $cnt = 0;
  my @newAry;
  my $line;
  if($eid >= 0){
      foreach (@partsAry) {
          if ($eid == $cnt) {
              $line = $data . "\n";
          } else {
              $line = $_ . "\n";
          }
          syswrite $hF, $line, length($line);
          $cnt++;
      }
  } else {
      $line = $data . "\n";
      syswrite $hF, $line, length($line);
  }
  close $hF;

  my $author = $self->_get_author($self->{s}->param('login'));
  $self->{git}->commit($filename, $author, "temp saved");
  $self->{git}->detach_local();

  my $json = JSON->new();
  my $md;# = markdown($data);
  $eid = 0 if($eid < 0);
  my ($row, @parts) = $self->split_for_md($data, $eid);
  $cnt = $eid;
  foreach(@parts){
    my $conv .= markdown($_)    if($_ !~ m/^\n*$/);
    $conv =~ s/^<([a-z1-9]+)>/<\1 id=\"md${cnt}\" class=\"Md\">/;
    $conv =~ s#^<([a-z1-9]+) />#<\1 id=\"md${cnt}\" class=\"Md\" />#;
    $conv =~ s#"md_imageView\.cgi\?(.*)"#"md_imageView.cgi?tmp=1&\1"#g;
    $conv =~ s/^(.*)\n$/\1/;
    $md .= $conv;
    $cnt++;
  }
  return $json->encode({eid => ${eid}, md => ${md}, row => ${row}});
}

############################################################
#[API]
#
sub delete_data {
  my $self = shift;
  my $uid = $self->{s}->param("login");
  return unless($uid);
  my $fid = $self->qParam('fid') + 0;
  my $eid = $self->qParam('eid');

  my $document = $self->get_user_document($uid, $fid);
  my ($rowdata, @partsAry) = $self->split_for_md($document);

  $self->{git}->attach_local_tmp($uid, 1);

  #ファイル書き込み
  # TODO: ファイル名取得ルーチンが重複！
  my $sql = "select file_name from docx_infos where id = ${fid};";
  my @ary = $self->{dbh}->selectrow_array($sql);
  return unless(@ary);
  my $filename = $ary[0];
  my $filepath = "$self->{repodir}/${fid}/${filename}";

  open my $hF, '>', $filepath || return undef;
  my $cnt = 0;
  foreach(@partsAry) {
    if($eid != $cnt){
      my $line = $_ . "\n";
      syswrite $hF, $line, length($line);
    }
    $cnt++;
  }
  close $hF;

  my $author = $self->_get_author($self->{s}->param('login'));
  $self->{git}->commit($filename, $author, "temp saved");
  $self->{git}->detach_local();

  my $json = JSON->new();
  return $json->encode({eid => ${eid}});
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
  my $diff     = $self->{git}->get_diff($revision, $dist);

  my $json = JSON->new();
  return $json->encode({
      name     => $filename,
      revision => $revision,
      dist     => $dist?$dist:'ひとつ前',
      diff    => $diff,
  });

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
  ('$account', '$nicname', '$mail', md5('$password'), now())
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

1;
