#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use mdDog;
use Data::Dumper;

my $dog =mdDog->new();
$dog->setupConfig();
$dog->login();

if(!$dog->qParam('fid')) {
  $dog->{t}->{error} = "ドキュメントが指定されずにアクセスされました<br>docinfo.cgi<br>Err001";
} else {
  $dog->gitLog();
  $dog->setDocumentInfo();
}

$dog->printPage();
exit();
