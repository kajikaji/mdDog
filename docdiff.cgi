#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/14
#

use strict; no strict "refs";
use lib './lib/';
use mdDog;
use Data::Dumper;

my $dog =mdDog->new();
$dog->setup_config();
$dog->login();

if(!$dog->qParam('fid')) {
  $dog->{t}->{error} = "違法なアクセスです";
} else {
  if($dog->qParam('revision')){
    $dog->git_diff();
  }

  $dog->set_document_info();
}

$dog->print_page();
exit();
