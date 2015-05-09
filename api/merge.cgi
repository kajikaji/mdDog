#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/5/9
#

use strict;no strict "refs";
use lib '../lib/';
use mdDogAPI;
use MYUTIL;

my $dog = mdDogAPI->new('api');
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
