#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use DocxLog;
use Data::Dumper;

my $docxlog =DocxLog->new();
$docxlog->setupConfig();
$docxlog->login();

if(!$docxlog->qParam('fid')
  || !$docxlog->qParam('revision')
  || !$docxlog->qParam('user')) {
  $docxlog->{t}->{error} = "違法なアクセスです";
} else {
  #正常系の処理
  if($docxlog->qParam('approve')){
    $docxlog->docApprove();

    print "Location: docinfo.cgi?fid=".$docxlog->qParam('fid') . "&revision=" . $docxlog->qParam('revision') . "\n\n";
    exit();
  }

  $docxlog->setDocumentInfo();
  $docxlog->setApproveList();
}

$docxlog->printPage();
exit();
