package mdDogAdmin;

#
# author: gm2bv
# date: 2015/1/14
#

use strict; no strict "subs";
use base mdDog;

sub login_for_admin{
  my $self = shift;

  $self->SUPER::login();
  return $self->{user}->{may_admin}
}

sub set_user_infos{
  my $self = shift;

  my $sql = "select * from docx_users;";
  my $infos = $self->{dbh}->selectall_arrayref($sql, {+Slice, {}}) || $self->errorMessage("DB:Error getUserInfos", 1);

  
  foreach(@$infos){
#    $self->{t}->{userinfos}
  }
}

1;
