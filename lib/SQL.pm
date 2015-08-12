package SQL;

sub user_login {
    return << "SQL";
SELECT
  id
FROM
  docx_users
WHERE
  account = ?
  AND password = md5(?)
  AND is_used = true;
SQL
}

sub user_info {
    return << "SQL";
SELECT
  account, mail, nic_name, may_admin, may_approve, may_delete
FROM
  docx_users
WHERE
  id = ?
SQL
}

sub user_info_update {
    return << "SQL";
UPDATE docx_users
SET
  account = ?,
  nic_name = ?,
  mail = ?,
  password = md5(?)
WHERE
  id = ?
SQL
}

sub group_list {
    return << "SQL";
SELECT * FROM mddog_groups ORDER BY title
SQL
}

sub document_info {
    return << "SQL";
SELECT
  di.*,
  du.nic_name AS nic_name,
  du.account  AS account,
  du.mail     AS mail,
  g.title     AS group_name
FROM
  docx_infos di
INNER JOIN docx_users du ON di.created_by = du.id
LEFT OUTER JOIN mddog_doc_group dg ON dg.doc_id = di.id
LEFT OUTER JOIN mddog_groups g  ON g.id = dg.group_id
WHERE
  di.id = ?
SQL
}

sub document_name_update {
    return << "SQL";
UPDATE docx_infos
SET doc_name = ?
WHERE id = ?
SQL
}

sub document_list {
    my ($uid, $style, $group) = @_;

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

    if( $group ){
        $sql .= << "SQL";
LEFT OUTER JOIN mddog_doc_group dg ON dg.doc_id = di.id
LEFT OUTER JOIN mddog_groups g ON g.id = dg.group_id
SQL
    }

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

    if( $group ){
        $sql .= << "SQL"
  and g.id = ${group}
SQL
    }

    return $sql;
}

sub list_for_index {
    my ($uid, $style, $offset, $limit, $group) = @_;

    my $sql = document_list($uid, $style, $group);
    $sql .= << "SQL";
ORDER BY
  di.doc_name
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

    return $sql_wrapper;
}

sub auth_info {
    return << "SQL";
SELECT
  da.*,
  di.created_by
FROM docx_auths da
INNER JOIN docx_infos di ON da.info_id = di.id
WHERE
  da.info_id = ?
  AND da.user_id = ?
SQL
}

sub document_list_without_login{
    my ($group) = @_;

    my $sql = << "SQL";
SELECT
  di.*,
  du.nic_name AS nic_name,
  du.account  AS account,
  du.mail     AS mail
FROM
  docx_infos di
JOIN docx_users du ON du.id = di.created_by
SQL
    if( $group ){
        $sql .= << "SQL";
LEFT OUTER JOIN mddog_doc_group dg ON dg.doc_id = di.id
LEFT OUTER JOIN mddog_groups g ON g.id = dg.group_id
SQL
    }

    $sql .= << "SQL";
WHERE
  di.deleted_at is null
  and di.is_used = true
  and di.is_public = true
SQL

    if( $group ){
        $sql .= << "SQL"
  and g.id = ${group}
SQL
    }

    return $sql;
}

sub list_for_index_without_login{
    my ($offset, $limit, $group) = @_;
    my $sql = document_list_without_login($group);
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

    return $sql_wrapper;
}

1;

