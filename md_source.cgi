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
$dog->check_auths("is_edit");

#一時保存処理
if ($dog->qParam('update')) {
    #一時保存
    $dog->update_md_buffer();
}

#コミット処理
if ($dog->qParam('commit')) {
    #変更を反映 変更履歴は必須
    $dog->fix_md_buffer();
}

$dog->is_exist_buffer();

$dog->set_md_buffer();
$dog->set_document_info();

$dog->print_page();
exit();
