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
my $action = $dog->qParam('action');
my $num    = $dog->qParam('num');
$dog->check_auths($uid, $fid, "is_edit", "is_admin");

print "Content-type: application/json; charset=utf-8\n\n";
if($ENV{'REQUEST_METHOD'} eq 'GET'){
} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    return unless( $fid || $action );

    if(   $action eq 'divide' &&  $num){
        print $dog->outline_add_divide();
    }
    elsif($action eq 'undivide' &&  $num ){
        print $dog->outline_remove_divide();
    }
}

exit();
