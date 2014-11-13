#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use mdDog;

my $dog =mdDog->new();
$dog->setupConfig();
$dog->login();

if($dog->qParam('docxfile')){
  $dog->uploadFile();
}elsif($dog->qParam('create')){
    $dog->createFile();
}elsif($dog->qParam('unuse')){
  $dog->changeFileInfo('unuse');
}elsif($dog->qParam('use')){
  $dog->changeFileInfo('use');
}elsif($dog->qParam('delete')){
  $dog->changeFileInfo('delete');
}

$dog->listupDocuments();

$dog->printPage();
exit();
