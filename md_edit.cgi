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
  if($dog->qParam('commit')){
    #変更を反映 変更履歴は必須
    if($dog->fixMD_buffer()){
    }
  }

  $dog->setMD_buffer(1);
  $dog->setDocumentInfo();
  $dog->setOutline_buffer();
}

$dog->printPage();
exit();
