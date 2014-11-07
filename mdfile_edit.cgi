#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use DocxLog;
use Data::Dumper;

my $docxlog =DocxLog->new();
$docxlog->setupConfig();
$docxlog->login();

if(!$docxlog->qParam('fid')) {
  $docxlog->{t}->{error} = "違法なアクセスです";
} else {


}

$docxlog->printPage();
exit();
