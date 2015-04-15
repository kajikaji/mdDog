package SQL;

sub document_list {
    my $uid = shift;

    my $sql = << "SQL";
SELECT
  di.*,
  du.nic_name    AS nic_name,
  du.account     AS account,
  du.mail        AS mail,
  da.id          AS auth_id,
  da.may_edit    AS may_edit,
  da.may_approve AS may_approve
FROM
  docx_infos di
JOIN docx_users du ON du.id = di.created_by
LEFT OUTER JOIN docx_auths da on da.info_id = di.id and da.user_id = ${uid}
WHERE
  di.deleted_at is null
  and (di.is_public = true or da.id is not null)
SQL
  return $sql;
}

sub list_for_index {
    my ($uid, $offset, $limit) = @_;

    my $sql = document_list($uid);
    $sql .= << "SQL";
ORDER BY
  di.is_used DESC, di.doc_name
OFFSET ${offset} LIMIT ${limit}
SQL
    return $sql;
}

sub document_list_without_login{
    my $sql = << "SQL";
SELECT
  di.*,
  du.nic_name AS nic_name,
  du.account AS account,
  du.mail AS mail
FROM
  docx_infos di
JOIN docx_users du ON du.id = di.created_by
WHERE
  di.deleted_at is null
  and di.is_public = true
SQL
    return $sql;
}

sub list_for_index_without_login{
    my ($offset, $limit) = @_;
    my $sql = document_list_without_login();
    $sql .= <<"SQL";
ORDER BY
  di.is_used DESC, di.doc_name
OFFSET ${offset} LIMIT ${limit}
SQL
    return $sql;
}

1;

