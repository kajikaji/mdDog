#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/7/7
#

use strict;no strict "refs";
use lib '../lib', '../src';
use mdDog::API;

my $dog = mdDog::API->new('api');
my $fid = $dog->qParam('fid');
$dog->setup_config($fid);
my $uid = $dog->login();
$dog->check_auths($uid, $fid, "is_edit", "is_admin");

print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){
    print $dog->get_doc_groups($fid);
}elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ){
    if( my $search = $dog->qParam('search') ){
        print $dog->search_groups($search);
    }
    if( $dog->qParam('action') eq 'editGroup' ){
        my @groups = $dog->qParam('groups[]');
        print $dog->add_groups($uid, $fid, \@groups);
    }
}

exit();
