#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use DocxLog;
use Data::Dumper;

my $docxlog =DocxLog->new();
$docxlog->setupConfig();

if(!$docxlog->qParam('fid')) {
  $docxlog->{t}->{error} = "違法なアクセスです";
} else {
  if($docxlog->qParam('docxfile')){
    $docxlog->commitFile();
  }

  $docxlog->gitLog();
  $docxlog->setupFileinfo();
}

$docxlog->printPage();
exit();
