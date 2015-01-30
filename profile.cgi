#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/14
#

use strict; no strict "refs";
use lib './lib/';
use mdDog;

my $dog =mdDog->new();
$dog->setup_config();
unless($dog->login()){
    print "Location: index.cgi\n\n";
    exit();
}

if($dog->qParam("save")){
  #アカウント情報の保存
  if($dog->change_profile()){
    $dog->login();
  }
}

$dog->print_page();
exit();
