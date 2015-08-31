#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/27
#

use strict;no strict "refs";
use lib '../lib', '../src';
use mdDog::Doc::API;

my $dog = mdDog::Doc::API->new('api');
my $fid = $dog->qParam('fid');
$dog->init($fid);
return unless( $fid );
$dog->login();
$dog->check_auths("is_owned", "is_admin");

my $action = $dog->qParam('action');

print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){

} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    if( $action eq 'change_public' ){
        my $is_public = $dog->qParam('is_public')?'true':'false';
        print $dog->document_change_public($is_public);
    }
    if( $action  eq 'user_add' ) {
        my @users = $dog->qParam('users[]');
        print $dog->document_user_add(\@users);
    }
    if( $action eq 'user_delete' ){
        my @users = $dog->qParam('users[]');
        print $dog->document_user_delete(\@users);
    }
    if( $action eq 'user_may_approve' ){
        my $checked = $dog->qParam('checked')?'true':'false';
        my $user = $dog->qParam('uid');
        print $dog->document_user_may_approve($user, $checked);
    }
    if( $action eq 'user_may_edit' ){
        my $checked = $dog->qParam('checked')?'true':'false';
        my $user = $dog->qParam('uid');
        print $dog->document_user_may_edit($user, $checked);
    }

}

exit();
