#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/7/13
#

use strict;no strict "refs";
use lib '../lib/';
use mdDogAPI;
use MYUTIL;

my $dog = mdDogAPI->new('api');
$dog->setup_config();

print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){
    print $dog->get_groups();
}

exit();
