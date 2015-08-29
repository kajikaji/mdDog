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
use mdDog::Doc::Approve;

my $dog = mdDog::Doc::Approve->new();
my $fid = $dog->qParam('fid');
$dog->setup_config($fid);
my $uid = $dog->login_user_document($fid);
$dog->check_auths($uid, $fid, "is_approve", "is_admin");
my %parts;

#承認処理
if( $dog->qParam('approve') ){
    my $user     = $dog->qParam("user");
    my $revision = $dog->qParam("revision");
    $dog->doc_approve($uid, $fid, $user, $revision);
}elsif( $dog->qParam('approve_pre') ){ # 確認
    my $user     = $dog->qParam("user");
    my $revision = $dog->qParam("revision");
    $parts{loglist} = $dog->set_approve_list(
        $uid, $fid, $user, $revision);
    $parts{approve_pre} = 1;
}

$parts{userlist} = $dog->set_user_log($uid, $fid);
$parts{docinfo}  = $dog->set_document_info($uid, $fid);

$dog->print_page(\%parts);
exit();
