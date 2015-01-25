package mdDogAdmin;

#
# author: gm2bv
# date: 2015/1/14
#

use strict; no strict "subs";
use base mdDog;
use MYUTIL;

sub login_for_admin{
    my $self = shift;

    $self->SUPER::login();
    return $self->{user}->{may_admin}
}

sub set_user_infos{
    my $self  = shift;

    my $sql   = "SELECT * FROM docx_users;";
    my $infos = $self->{dbh}->selectall_arrayref($sql, {+Slice, {}})
        || $self->errorMessage("DB:Error set_user_infos", 1);

    foreach(@$infos){
        $_->{created_at} = MYUTIL::format_date3($_->{created_at});
    }

    $self->{t}->{userinfos} = $infos
}

sub get_document_users {
    my $self = shift;

    my $fid = $self->qParam('fid');
    my $sql = << "SQL";
SELECT
  a.*,
  u.account,
  u.nic_name
FROM
  docx_auths a
INNER JOIN docx_users u ON a.user_id = u.id
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

1;
