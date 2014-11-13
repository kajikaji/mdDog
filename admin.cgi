#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use mdDogAdmin;
use Data::Dumper;

my $dog =mdDogAdmin->new();
$dog->setupConfig();
if(!$dog->login4admin()){
  #管理者でない場合、index.cgiにリダイレクト
  print "Location: index.cgi\n\n";
  exit();
}

$dog->setUserInfos();

$dog->printPage();
exit();
