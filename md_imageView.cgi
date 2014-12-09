#!/usr/bin/perl
# 画像をバイナリ出力する
#

use strict; no strict "refs";
use lib './lib/';
use mdDog;

my $dog = mdDog->new();
$dog->setupConfig();
$dog->login();

return if(!$dog->qParam('fid'));

$dog->printImage();

exit();
