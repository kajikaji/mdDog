#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/14
#

use strict; no strict "refs";
use lib './lib/';
use mdDogAdmin;
use Data::Dumper;

my $dog = mdDogAdmin->new();
$dog->setup_config();
if(!$dog->login_for_admin()){
  #管理者でない場合、index.cgiにリダイレクト
  print "Location: index.cgi\n\n";
  exit();
}

$dog->set_user_infos();

$dog->print_page();
exit();
