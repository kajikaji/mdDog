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
$dog->login();

if($dog->qParam('unuse')){
  $dog->change_file_info('unuse');
}elsif($dog->qParam('use')){
  $dog->change_file_info('use');
}elsif($dog->qParam('delete')){
  $dog->change_file_info('delete');
}

$dog->listup_documents();

$dog->print_page();
exit();
