#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/5/12
#

use strict;no strict "refs";
use lib '../lib', '../src';
use mdDog::API;
use MYUTIL;

my $dog = mdDog::API->new('api');
my $fid = $dog->qParam('fid');
$dog->init($fid);
my $uid = $dog->login();
$dog->check_auths($uid, $fid, "is_edit", "is_admin");

print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){
} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ){
    print $dog->clear_user_buffer();
}

exit();
