#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/14
#

use strict; no strict "refs";
use lib './lib/';
use mdDog;

my $dog = mdDog->new();
$dog->setup_config();
$dog->login();

if(!$dog->qParam('fid')) {
    $dog->{t}->{error} = "md&MMkwrTDlMOEw8zDIMExjB1uaMFUwjDBmMEQwfjBbMJM-<br>md_edit.cgi:err01<br>";
} else {
    if ($dog->qParam('commit')) {
        #変更を反映 変更履歴は必須
        if ($dog->fix_md_buffer()) {
            $dog->{t}->{message}->{info} = "コミットしました";
        } else {
            $dog->{t}->{message}->{error} = "編集バッファのコミットに失敗しました";
        }
    }

    if($dog->is_exist_buffer()){
        $dog->{t}->{message} = { "info" => "コミットされていないバッファがあります" };
    }

    $dog->git_my_log();
    $dog->set_document_info();
}

$dog->print_page();
exit();
