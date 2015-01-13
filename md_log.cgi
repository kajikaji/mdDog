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
    if($dog->is_exist_buffer()){
        $dog->{t}->{message} = { "info" => "コミットされていないバッファがあります" };
    }

    $dog->git_my_log();
    $dog->set_document_info();
}

$dog->print_page();
exit();
