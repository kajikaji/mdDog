#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use mdDog;

my $dog =mdDog->new();
$dog->setupConfig();
$dog->login();

if(!$dog->qParam('fid')) {
  $dog->{t}->{error} = "mdドキュメントが指定されていません<br>md_output.cgi:err01<br>";
} else {
    $dog->setOutline();

#MDファイルの目次作成

#MDファイルの出力

    $dog->setDocumentInfo();
}

$dog->printPage();
exit();
