#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/14
#

use strict; no strict "refs";
use lib './lib/';
use mdDog;

my $dog =mdDog->new();
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
