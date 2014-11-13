#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use mdDog;

my $dog =mdDog->new();
$dog->setupConfig();
unless($dog->login()){
  $dog->{t}->{error} = "この操作はログインする必要があります<br>create.cgi";
}else{

if($dog->qParam('docxfile')){
    $dog->uploadFile();
    print "Location: index.cgi\n\n";
    exit();
}
}

$dog->printPage();
exit();
