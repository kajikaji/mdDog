
package mdDog::API;

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
use Digest::MD5 qw/md5 md5_hex/;

use constant USER_AUTH_ADMIN   => 1;
use constant USER_AUTH_APPROVE => 2;
use constant USER_AUTH_DELETE  => 3;


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

    my $row = $self->{teng}->insert('docx_users' => {
        'account'    => $account,
        'nic_name'   => $nicname,
        'mail'       => $mail,
        'password'   => md5_hex(${password}),
        'created_at' => 'now()',
     });
    $self->dbCommit();
    my $json = JSON->new();
    return $json->encode({
        id          => $row->id,
        account     => $row->account,
        nic_name    => $row->nic_name,
        mail        => $row->mail,
        may_approve => $row->may_approve,
        may_admin   => $row->may_admin,
        may_delete  => $row->may_delete,
        is_used     => $row->is_used,
        created_at  => MYUTIL::format_date3($row->created_at)
    });
}

############################################################
#[API] ユーザーの使用・不使用切り替え
#
sub user_used {
    my $self    = shift;

    my $uid     = $self->qParam('uid');
    my $checked = $self->qParam('is_used') eq '1'?'true':'false';

    $self->{teng}->update('docx_users' => {
        is_used => ${checked}
    }, {
        id     => $uid
    });
    $self->dbCommit();

    my $sth  = $self->{dbh}->prepare(SQL::user_info);
    $sth->execute($uid);
    my $infos = $sth->fetchrow_hashref();
    $sth->finish();

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
    my $checked = $self->qParam('checked') eq '1'?'true':'false';
    my $col;
    if(     $type == USER_AUTH_ADMIN ){
        $col = 'may_admin';
    }elsif( $type == USER_AUTH_APPROVE ){
        $col = 'may_approve';
    }elsif( $type == USER_AUTH_DELETE ){
        $col = 'may_delete';
    }

    $self->{teng}->update('docx_users' => {
        ${col} => $checked
    }, {
        id => $uid
    });
    $self->dbCommit();

    my $sth  = $self->{dbh}->prepare(SQL::user_info);
    $sth->execute($uid);
    my $infos = $sth->fetchrow_hashref();
    $sth->finish();

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

1;
