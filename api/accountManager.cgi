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
exit() unless( $dog->{user}->{is_admin} );

print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){

} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    if( $dog->qParam('action')  eq 'add' ) {
        print $dog->add_account();
    }
    if( $dog->qParam('action') eq 'account_is_used' ){
        print $dog->user_used();
    }
    if( $dog->qParam('action') eq 'account_may_admin' ){
        print $dog->user_admin();
    }
    if( $dog->qParam('action') eq 'account_may_approve' ){
        print $dog->user_approve();
    }
    if( $dog->qParam('action') eq 'account_may_delete' ){
        print $dog->user_delete();
    }
}

exit();

