#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/7/7
#

use strict;no strict "refs";
use lib '../lib/';
use mdDogAPI;
use MYUTIL;
use Data::Dumper;

my $dog = mdDogAPI->new('api');
$dog->setup_config();
$dog->login();
$dog->check_auths("is_edit", "is_admin");

print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){
    print $dog->get_doc_groups();
}elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ){
    if( $dog->qParam('search') ){
      print $dog->search_groups();
    }
    if( $dog->qParam('action') eq 'editGroup' ){
        print $dog->add_groups();
    }
}

exit();
