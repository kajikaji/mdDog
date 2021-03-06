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
use mdDog::Doc::Setting;

my $dog = mdDog::Doc::Setting->new();
my $fid = $dog->qParam('fid');
unless( $fid ){
    print "Location: index.cgi\n\n";
    exit;
}
$dog->init($fid);
unless( $dog->login ){
    print "Location: doc_history.cgi?fid=${fid}\n\n";
    exit;
}

$dog->check_auths("is_owned", "is_admin");

if( $dog->qParam("change_name") ){
    #ドキュメントの名前変更
    my $doc_name = $dog->qParam('doc_name');
    $dog->change_doc_name($doc_name);
}

my %parts;
my ($users, $unallows) = $dog->get_document_users;
$parts{users}          = $users;
$parts{unallow_users}  = $unallows;
$parts{docinfo}        = $dog->get_document_info;

$dog->print_page(\%parts);
exit();
