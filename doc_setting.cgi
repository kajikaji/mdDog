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
use lib './lib/';
use mdDog::Admin;
use Data::Dumper;

my $dog = mdDog::Admin->new();
$dog->setup_config();
$dog->login_user_document();
$dog->check_auths("is_owned", "is_admin");

if( $dog->qParam("change_name") ){
    #ドキュメントの名前変更
    $dog->change_doc_name();
}

$dog->get_document_users();
$dog->set_document_info();

$dog->print_page();
exit();
