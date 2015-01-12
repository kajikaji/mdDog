#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use mdDog;

my $dog =mdDog->new();
$dog->setupConfig();
$dog->login();

if(!$dog->qParam('fid')) {
    $dog->{t}->{error} = "mdドキュメントが指定されていません<br>md_edit.cgi:err01<br>";
} else {
    $dog->gitMyLog();
    $dog->setDocumentInfo();
}

$dog->printPage();
exit();
