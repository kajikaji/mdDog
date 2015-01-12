#!/usr/bin/perl

use strict;no strict "refs";
use lib '../lib/';
use mdDog;
use MYUTIL;

my $dog = mdDog->new('api');
$dog->setupConfig();
$dog->login();

print "Content-type: application/json; charset=utf-8\n\n";
if($ENV{'REQUEST_METHOD'} eq 'GET'){
} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    return unless($dog->qParam('fid'));

    my $uid = $dog->qParam('uid');
    print $dog->api_get_revisiondata();
}

exit();
