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
$dog->login_user_document();
$dog->check_auths("is_approve", "is_admin");

#承認処理
if( $dog->qParam('approve') ){
    $dog->doc_approve();
}elsif( $dog->qParam('approve_pre') ){ # 確認
    $dog->set_approve_list();
}

$dog->git_log('all');
$dog->set_document_info();

$dog->print_page();
exit();
