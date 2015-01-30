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
$dog->login_user_document();
$dog->check_auths("is_owned", "is_admin");

$dog->get_document_users();
$dog->set_document_info();

$dog->print_page();
exit();
