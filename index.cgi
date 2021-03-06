#!/usr/bin/perl
#
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
#

use strict; no strict "refs";
use lib './lib', './src';
use mdDog;
use MYUTIL;

my $dog = mdDog->new();
$dog->init();
my $uid = $dog->login();

my $ope = $dog->qParam('unuse')?'unuse'
    :$dog->qParam('use')?'use'
    :$dog->qParam('delete')?'delete'
    :undef;
if( $ope ){
    $dog->change_file_info($ope);
}

my $grouplist = $dog->listup_groups();
my $page      = $dog->param_or_cookie("index", "page");
my $style     = $dog->param_or_cookie("index", "style");
my $group     = $dog->param_or_cookie("index", "group");
my ($docs, $count, $paging) = 
    $dog->listup_documents($uid, $page, $style, $group);

$dog->print_page({
    'grouplist'      => $grouplist,
    'docs'           => $docs,
    'document_count' => $count,
    'paging'         => $paging,
    'style'          => $style,
    'page'           => $page
});
exit();
