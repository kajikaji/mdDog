#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/23
#

use strict;no strict "refs";
use lib '../lib', '../src';
use mdDog::API;

my $dog    = mdDog::API->new('api');
my $fid    = $dog->qParam('fid');
$dog->init($fid);
my $uid    = $dog->login();
my $action = $dog->qParam('action');
$dog->check_auths($uid, $fid, "is_owned", "is_admin");

print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){

} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    if( $action  eq 'user_add' ) {
        my @users = $dog->qParam('users[]');
        print $dog->document_user_add($uid, $fid, \@users);
    }
    if( $action eq 'user_delete' ){
        my @users = $dog->qParam('users[]');
        print $dog->document_user_delete($uid, $fid, \@users);
    }
    if( $action eq 'user_may_approve' ){
        my $checked = $dog->qParam('checked')?'true':'false';
        my $user = $dog->qParam('uid');
        print $dog->document_user_may_approve($uid, $fid, $user, $checked);
    }
    if( $action eq 'user_may_edit' ){
        my $checked = $dog->qParam('checked')?'true':'false';
        my $user = $dog->qParam('uid');
        print $dog->document_user_may_edit($uid, $fid, $user, $checked);
    }
}

exit();
