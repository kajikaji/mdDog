#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/23
#

use strict;no strict "refs";
use lib '../lib/';
use mdDogAPI;

my $dog = mdDogAPI->new('api');
$dog->setup_config();
$dog->login();

print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){

} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    if( $dog->qParam('action')  eq 'add_users' ) {
        print $dog->document_user_add();
    }
    if( $dog->qParam('action') eq 'user_may_approve' ){
	print $dog->document_user_may_approve();
    }
}

exit();
