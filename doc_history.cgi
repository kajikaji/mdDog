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
use lib './lib', './src';
use mdDog::Doc;

my $dog = mdDog::Doc->new();
my $fid = $dog->qParam('fid');
$dog->setup_config($fid);
my $uid = $dog->login();
$dog->check_auths($uid, $fid, "all");

unless( $fid ){
    my $error = "ドキュメントが指定されずにアクセスされました";
    $dog->print_page({
        'error'  => $error
    });
    exit();
}

my $user       = $dog->qParam('user');
my $ver        = $dog->qParam('revision');
my $docinfo    = $dog->set_document_info($uid, $fid);
my $sharedlist = $dog->set_document_log();

$dog->print_page({
    'fid'        => $fid,
    'user'       => $user,
    'revision'   => $ver,
    'docinfo'    => $docinfo,
    'sharedlist' => $sharedlist
});
exit();
