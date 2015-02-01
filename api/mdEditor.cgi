#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/14
#

use strict;no strict "refs";
use lib '../lib/';
use mdDogAPI;
use MYUTIL;

my $dog = mdDogAPI->new('api');
$dog->setup_config();
$dog->login();
$dog->check_auths("is_edit", "is_admin");

print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){
    return unless($dog->qParam('fid'));

    ## ?fid=[fid](&eid=[eid])
    print $dog->get_data();
} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ){
    ## ?fid=[fid]&eid=[eid]&action=[action]
    return unless( $dog->qParam('fid')
                || $dog->qParam('eid')
                || $dog->qParam('action'));

    if(     $dog->qParam('action') eq 'update' ){
        my $updateData = $dog->post_data();
        print $updateData;
    }elsif( $dog->qParam('action') eq 'delete' ){
        my $ret = $dog->delete_data();
        print $ret;
    }
}

exit();
