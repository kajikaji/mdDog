#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use DocxLog;
use Data::Dumper;

my $docxlog =DocxLog->new();
$docxlog->setupConfig();

my $fid = $docxlog->qParam('fid');
my $rev = $docxlog->qParam('rev');

exit() unless($fid);

$docxlog->downloadFile($fid, $rev);
exit();
