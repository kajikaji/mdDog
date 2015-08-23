#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/14
#

use strict;no strict "refs";
use lib '../lib', '../src';
use mdDog::API;
use MYUTIL;

my $dog = mdDog::API->new('api');
$dog->setup_config();
$dog->login();
$dog->check_auths("is_edit", "is_admin");

print "Content-type: application/json; charset=utf-8\n\n";
if($ENV{'REQUEST_METHOD'} eq 'GET'){
} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    ## ?fid=[fid]&action=[action]&....
    return unless($dog->qParam('fid')
                  || $dog->qParam('action'));

    if($dog->qParam('action') eq 'divide' &&  $dog->qParam('num')){
        print $dog->outline_add_divide();
    }
    elsif($dog->qParam('action') eq 'undivide' &&  $dog->qParam('num')){
        print $dog->outline_remove_divide();
    }
}

exit();
