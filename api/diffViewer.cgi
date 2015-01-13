#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/15
#

use strict;no strict "refs";
use lib '../lib/';
use mdDog;
use MYUTIL;

my $dog = mdDog->new('api');
$dog->setup_config();
$dog->login();

print "Content-type: application/json; charset=utf-8\n\n";
if($ENV{'REQUEST_METHOD'} eq 'GET'){
} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    return unless($dog->qParam('fid') && $dog->qParam('revision'));

    print $dog->api_get_diff();
}

exit();
