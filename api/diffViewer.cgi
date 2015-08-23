#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/15
#

use strict;no strict "refs";
use lib '../lib', '../src';
use mdDog::API;
use MYUTIL;

my $dog = mdDog::API->new('api');
$dog->setup_config();
$dog->login();

print "Content-type: application/json; charset=utf-8\n\n";
if($ENV{'REQUEST_METHOD'} eq 'GET'){
} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    return unless($dog->qParam('fid') && $dog->qParam('revision'));

    print $dog->get_diff();
}

exit();
