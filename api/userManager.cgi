#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/23
#

use strict;no strict "refs";
use lib '../lib', '../src';
use mdDog::API;

my $dog = mdDog::API->new('api');
$dog->setup_config();
$dog->login();
$dog->check_auths("is_owned", "is_admin");

print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){

} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    if( $dog->qParam('action')  eq 'user_add' ) {
        print $dog->document_user_add();
    }
    if( $dog->qParam('action') eq 'user_delete' ){
	print $dog->document_user_delete();
    }
    if( $dog->qParam('action') eq 'user_may_approve' ){
	print $dog->document_user_may_approve();
    }
    if( $dog->qParam('action') eq 'user_may_edit' ){
	print $dog->document_user_may_edit();
    }
}

exit();
