#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/14
#

use strict;no strict "refs";
use lib '../lib', '../src';
use mdDog::API;
use MYUTIL;

my $dog = mdDog::API->new('/api');
my $fid = $dog->qParam('fid');
$dog->setup_config($fid);
my $uid = $dog->login();
$dog->check_auths($uid, $fid, "is_edit", "is_admin");

print "Content-type: application/json; charset=utf-8\n\n";
if(     $ENV{'REQUEST_METHOD'} eq 'GET'  ){
}elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ){
    if( $dog->qParam('action') eq 'rollback' ){
        print $dog->rollback_buffer();
    }
    elsif( $dog->qParam('action') eq 'editLog' ){
        print $dog->edit_log();
    }
}

exit();
