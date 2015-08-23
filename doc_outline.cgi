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
$dog->setup_config();
$dog->login();
$dog->check_auths("all");

if( !$dog->qParam('fid') ){
    $dog->{t}->{error} = "mdドキュメントが指定されていません<br>doc_outline.cgi:err01<br>";
}else{
    $dog->set_master_outline();

    #MDファイルの目次作成
    #MDファイルの出力
    $dog->set_document_info();
}

$dog->print_page();
exit();
