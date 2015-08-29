#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/14
#

use strict;no strict "refs";
use lib '../lib', '../src';
use mdDog::API;
use MYUTIL;

my $dog    = mdDog::API->new('api');
my $fid    = $dog->qParam('fid');
$dog->setup_config($fid);
my $uid    = $dog->login();
my $eid    = $dog->qParam('eid') + 0;
my $action = $dog->qParam('action');
$dog->check_auths($uid, $fid, "is_edit", "is_admin");
 
print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){
    return unless( $fid );

    print $dog->get_data($uid, $fid, $eid);
} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ){
    return unless( $fid && $action );

    if(     $action eq 'update' ){
        my $data = $dog->qParam('data');
        my $updateData = $dog->update_paragraph($uid, $fid, $eid, $data);
        print $updateData;
    }elsif( $action eq 'delete' ){
        my $ret = $dog->delete_paragraph($uid, $fid, $eid);
        print $ret;
    }
}

exit();
