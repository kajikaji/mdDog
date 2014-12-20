#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use mdDog;

my $dog =mdDog->new();
$dog->setupConfig();
$dog->login();

if(!$dog->qParam('fid')) {
    $dog->{t}->{error} = "mdドキュメントが指定されていません<br>md_edit.cgi:err01<br>";
} else {
    if($dog->qParam('upload')){
        $dog->upload_image();
    }
 
    if($dog->qParam('delete')){
        $dog->delete_image();
    }

    $dog->setMD_image();
    $dog->setDocumentInfo();
}

$dog->printPage();
exit();
