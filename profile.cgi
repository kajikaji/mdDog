#!/usr/bin/perl

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

use strict; no strict "refs";
use lib './lib/', './src';
use mdDog::Profile;

my $dog = mdDog::Profile->new();
$dog->setup_config();
my $uid = $dog->login();
unless( $uid ){
    print "Location: index.cgi\n\n";
    exit();
}

if($dog->qParam("save")){
    #アカウント情報の保存
    my $account     = $dog->qParam('account');
    my $mail        = $dog->qParam('mail');
    my $nic_name    = $dog->qParam('nic_name');
    my $password    = $dog->qParam('password');
    my $re_password = $dog->qParam('re_password');

    if( $password ne $re_password ){
        push @{$dog->{t}->{message}->{error}},
            "再入力されたパスワードが一致しません";
    }
    elsif( $dog->change_profile($uid,
                                $account,
                                $mail,
                                $nic_name,
                                $password)){
        $dog->login();
    }
}

$dog->print_page();
exit();
