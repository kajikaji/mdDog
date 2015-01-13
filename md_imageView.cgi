#!/usr/bin/perl
# 画像をバイナリ出力する
#
# author: gm2bv
# date: 2015/1/14
#


use strict; no strict "refs";
use lib './lib/';
use mdDog;

my $dog = mdDog->new();
$dog->setup_config();
$dog->login();

return if(!$dog->qParam('fid'));

$dog->print_image();

exit();
