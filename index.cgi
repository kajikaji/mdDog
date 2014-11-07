#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use DocxLog;
use Data::Dumper;

my $docxlog =DocxLog->new();
$docxlog->setupConfig();
$docxlog->login();

if($docxlog->qParam('docxfile')){
  $docxlog->uploadFile();
}elsif($docxlog->qParam('create')){
    $docxlog->createFile();
}elsif($docxlog->qParam('unuse')){
  $docxlog->changeFileInfo('unuse');
}elsif($docxlog->qParam('use')){
  $docxlog->changeFileInfo('use');
}elsif($docxlog->qParam('delete')){
  $docxlog->changeFileInfo('delete');
}

$docxlog->listupFile();

$docxlog->printPage();
exit();
