package mdDog::Admin;

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
use MYUTIL;

sub login_for_admin{
    my $self = shift;

    $self->SUPER::login();
    return $self->{user}->{is_admin}
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


1;
