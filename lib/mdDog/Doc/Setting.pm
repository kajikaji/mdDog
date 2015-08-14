package mdDog::Doc::Setting;

use strict; no strict "subs";
use parent mdDog::Doc;
use SQL;

sub get_document_users {
    my $self = shift;

    my $fid = $self->qParam('fid');
    my $sql = << "SQL";
SELECT
  a.*,
  u.account,
  u.nic_name,
  CASE
    WHEN i.created_by = a.user_id THEN true
    ELSE false
  END AS is_owned
FROM
  docx_auths a
INNER JOIN docx_users u ON a.user_id = u.id
INNER JOIN docx_infos i ON a.info_id = i.id
WHERE
  a.info_id = ${fid};
SQL
    my $users = $self->{dbh}->selectall_arrayref($sql, +{Slice => {}})
      || $self->viewAccident("Error: get_document_users", 1);
    $self->{t}->{users} = $users;
    my $sql_unallow = << "SQL";
SELECT
  *
FROM
  docx_users
WHERE
  id not in (SELECT
    user_id
  FROM
    docx_auths
  WHERE
    info_id = ${fid})
  AND is_used = 't';
SQL
    my $unallow_users = $self->{dbh}->selectall_arrayref($sql_unallow, +{Slice => {}})
      || $self->viewAccident("Error: get_document_users unallow", 1);
    $self->{t}->{unallow_users} = $unallow_users;
}


# @summary ドキュメントの名称を変更
#
sub change_doc_name {
    my $self     = shift;
    my $fid      = $self->qParam('fid');
    my $doc_name = $self->qParam('doc_name');
    return 0 unless($fid && $doc_name);

    $self->{teng}->update('docx_infos' => {
        doc_name => $doc_name
    }, {
        id => $fid
    });

    $self->dbCommit();
    return 1;
}

1;
