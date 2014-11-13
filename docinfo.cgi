#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use DocxLog;
use Data::Dumper;

my $docxlog =DocxLog->new();
$docxlog->setupConfig();
$docxlog->login();

if(!$docxlog->qParam('fid')) {
  $docxlog->{t}->{error} = "ドキュメントが指定されずにアクセスされました<br>docinfo.cgi<br>Err001";
} else {
  if($docxlog->qParam('docxfile')){
    $docxlog->commitFile();
  }

  $docxlog->gitLog();
  $docxlog->setDocumentInfo();
}

$docxlog->printPage();
exit();
