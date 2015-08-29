#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/27
#

use strict;no strict "refs";
use lib '../lib', '../src';
use mdDog::API;

my $dog = mdDog::API->new('api');
my $fid = $dog->qParam('fid');
$dog->setup_config($fid);
my $uid = $dog->login();
$dog->check_auths($uid, $fid, "is_owned", "is_admin");

print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){

} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    if( $dog->qParam('action') eq 'change_public' ){
        my $is_public = $dog->qParam('is_public')?'true':'false';
        print $dog->document_change_public($fid, $is_public);
    }
}

exit();
