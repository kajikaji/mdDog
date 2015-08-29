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
my $fid = $dog->qParam('fid');
$dog->setup_config($fid);
my $uid = $dog->login();

print "Content-type: application/json; charset=utf-8\n\n";
if($ENV{'REQUEST_METHOD'} eq 'GET'){
} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    my $revision = $dog->qParam("revision");
    my $dist     = $dog->qParam('dist');

    return unless( $fid && $revision );
    print $dog->get_diff($fid, $revision, $dist);
}

exit();
