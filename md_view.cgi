#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use mdDog;
use Data::Dumper;

my $dog =mdDog->new();
$dog->setupConfig();
$dog->login();

if(!$dog->qParam('fid')) {
  $dog->{t}->{error} = "mdドキュメントが指定されていません<br>md_view.cgi:err01<br>";
} else {
  $dog->setMD();
  $dog->setDocumentInfo();
}

$dog->printPage();
exit();
