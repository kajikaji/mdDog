package mdDog::Profile;

use strict; no strict "subs";
use parent mdDog;
use Digest::MD5 qw/md5 md5_hex/;

# @summary プロフィールの変更
#
sub change_profile{
    my $self = shift;
    my $uid  = $self->{s}->param('login');

    my $account     = $self->qParam('account');
    my $mail        = $self->qParam('mail');
    my $nic_name    = $self->qParam('nic_name');
    my $password    = $self->qParam('password');
    my $re_password = $self->qParam('re_password');

    if( length $password == 0 ){
        push @{$self->{t}->{message}->{error}}, "パスワードが入力されていません";
        return 0;
    }

    if( $password ne $re_password ){
        push @{$self->{t}->{message}->{error}}, "再入力されたパスワードが一致しません";
        return 0;
    }
    unless( $account && $nic_name && $mail ){
        push @{$self->{t}->{message}->{error}}, "入力が不足しています";
        return 0;
    }

    $self->{teng}->update('docx_users' => {
        account  => $account,
        nic_name => $nic_name,
        mail     => $mail,
        password => md5_hex(${password}),
    }, {
        id       => $uid
    });

    $self->dbCommit();
    return 1;
}

1;
