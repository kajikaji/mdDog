#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use mdDog;
use Data::Dumper;

my $dog =mdDog->new();
$dog->setupConfig();
$dog->login();

if(!$dog->qParam('fid')
  || !$dog->qParam('revision')
  || !$dog->qParam('user')) {
  $dog->{t}->{error} = "違法なアクセスです";
} else {
  #正常系の処理
  if($dog->qParam('approve')){
    $dog->docApprove();

    print "Location: docinfo.cgi?fid=".$dog->qParam('fid') . "&revision=" . $dog->qParam('revision') . "\n\n";
    exit();
  }

  $dog->setDocumentInfo();
  $dog->setApproveList();
}

$dog->printPage();
exit();
