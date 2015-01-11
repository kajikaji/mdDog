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
    return unless($dog->qParam('fid'));

    ## ?fid=[fid](&eid=[eid])
    print $dog->api_getData();
} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    ## ?fid=[fid]&eid=[eid]&action=[action]
    return unless($dog->qParam('fid')
                  || $dog->qParam('eid')
                  || $dog->qParam('action'));

    if($dog->qParam('action') eq 'update' &&  $dog->qParam('data')){
        my $updateData = $dog->api_postData();
        print $updateData;
    }elsif($dog->qParam('action') eq 'delete' ) {
        my $ret = $dog->api_deleteData();
        print $ret;
    }
}

exit();
