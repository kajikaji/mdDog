#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/5/9
#

use strict;no strict "refs";
use lib '../lib/';
use mdDog::API;
use MYUTIL;

my $dog = mdDog::API->new('api');
$dog->setup_config();
$dog->login();
$dog->check_auths("is_edit", "is_admin");

print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){
} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ){
    return unless( $dog->qParam('fid') );

    print $dog->restruct_document();
}

exit();
