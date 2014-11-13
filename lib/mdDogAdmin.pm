package mdDogAdmin;

use strict; no strict "subs";
use base mdDog;

sub login4admin{
  my $self = shift;

  $self->SUPER::login();
  return $self->{user}->{may_admin}
}

sub setUserInfos{
  my $self = shift;

  my $sql = "select * from docx_users;";
  my $infos = $self->{dbh}->selectall_arrayref($sql, {+Slice, {}}) || $self->errorMessage("DB:Error getUserInfos", 1);

  
  foreach(@$infos){
#    $self->{t}->{userinfos}
  }
}

1;
