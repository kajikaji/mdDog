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
} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    ## ?fid=[fid]&action=[action]&....
    return unless($dog->qParam('fid')
                  || $dog->qParam('action'));

    if($dog->qParam('action') eq 'divide' &&  $dog->qParam('num')){
        print $dog->api_outline_addDivide();
    }
    elsif($dog->qParam('action') eq 'undivide' &&  $dog->qParam('num')){
        print $dog->api_outline_removeDivide();
    }
}

exit();