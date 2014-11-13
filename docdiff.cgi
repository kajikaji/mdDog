#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use mdDog;
use Data::Dumper;

my $dog =mdDog->new();
$dog->setupConfig();
$dog->login();

if(!$dog->qParam('fid')) {
  $dog->{t}->{error} = "違法なアクセスです";
} else {
  if($dog->qParam('revision')){
    $dog->gitDiff();
  }

  $dog->setDocumentInfo();
}

$dog->printPage();
exit();
