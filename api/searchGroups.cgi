#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/7/13
#

use strict;no strict "refs";
use lib '../lib', '../src';
use mdDog::API;
use MYUTIL;

my $dog = mdDog::API->new('api');
my $fid = $dog->qParam('fid');
$dog->init($fid);

print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){
    print $dog->get_groups($fid);
}

exit();
