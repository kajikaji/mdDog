#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use DocxLogAdmin;
use Data::Dumper;

my $docxlog =DocxLogAdmin->new();
$docxlog->setupConfig();
if(!$docxlog->login4admin()){
  #管理者でない場合、index.cgiにリダイレクト
  print "Location: index.cgi\n\n";
  exit();
}

$docxlog->setUserInfos();

$docxlog->printPage();
exit();
