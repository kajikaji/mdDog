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
$dog->check_auths("is_edit", "is_admin");

# コミット処理
if ($dog->qParam('commit')) {
    #変更を反映 変更履歴は必須
    $dog->fix_md_buffer();
}

$dog->is_exist_buffer();

$dog->set_md_buffer(1);
$dog->set_document_info();
$dog->set_outline_buffer();

$dog->print_page();
exit();
