package SQL;

sub document_list {
    my ($uid, $style) = @_;

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
INNER JOIN docx_users du ON du.id = di.created_by
LEFT OUTER JOIN docx_auths da on da.info_id = di.id and da.user_id = ${uid}
SQL

    if( $style eq 'approver' ){
      $sql .= << "SQL";
WHERE
  di.deleted_at is null and di.is_used = 't'
  and da.may_approve = 't'
SQL
    }elsif( $style eq 'dustbox' ){
      $sql .= << "SQL";
WHERE
  di.deleted_at is null and di.is_used = 'f'
SQL
    }else{
      $sql .= << "SQL";
WHERE
  di.deleted_at is null and di.is_used = 't'
  and (di.is_public = true or da.id is not null)
SQL
    }

  return $sql;
}

sub list_for_index {
    my ($uid, $style, $offset, $limit, $group) = @_;

    my $sql = document_list($uid, $style);
    $sql .= << "SQL";
ORDER BY
  di.is_used DESC, di.doc_name
OFFSET ${offset} LIMIT ${limit}
SQL

    my $sql_wrapper = << "SQL";
SELECT
  foo.*,
  g.title AS group_title
FROM (${sql}) foo
LEFT OUTER JOIN mddog_doc_group dg ON dg.doc_id = foo.id
LEFT OUTER JOIN mddog_groups g ON g.id = dg.group_id
SQL

    if( $group ){
      $sql_wrapper .= << "SQL";
WHERE
  g.id = ${group}
SQL
    }

    return $sql_wrapper;
}

sub document_list_without_login{
    my $sql = << "SQL";
SELECT
  di.*,
  du.nic_name AS nic_name,
  du.account  AS account,
  du.mail     AS mail
FROM
  docx_infos di
JOIN docx_users du ON du.id = di.created_by
WHERE
  di.deleted_at is null
  and di.is_used = true
  and di.is_public = true
SQL
    return $sql;
}

sub list_for_index_without_login{
    my ($offset, $limit, $group) = @_;
    my $sql = document_list_without_login();
    $sql .= <<"SQL";
ORDER BY
  di.is_used DESC, di.doc_name
OFFSET ${offset} LIMIT ${limit}
SQL

    my $sql_wrapper = << "SQL";
SELECT
  foo.*,
  g.title AS group_title
FROM (${sql}) foo
LEFT OUTER JOIN mddog_doc_group dg ON dg.doc_id = foo.id
LEFT OUTER JOIN mddog_groups g ON g.id = dg.group_id
SQL

    if( $group ){
      $sql_wrapper .= << "SQL";
WHERE
  g.id = ${group}
SQL
    }

    return $sql_wrapper;
}

1;

