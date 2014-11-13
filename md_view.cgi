#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use DocxLog;
use Data::Dumper;

my $docxlog =DocxLog->new();
$docxlog->setupConfig();
$docxlog->login();

if(!$docxlog->qParam('fid')) {
  $docxlog->{t}->{error} = "mdドキュメントが指定されていません<br>md_view.cgi:err01<br>";
} else {
  $docxlog->setMD();
  $docxlog->setDocumentInfo();
}

$docxlog->printPage();
exit();
