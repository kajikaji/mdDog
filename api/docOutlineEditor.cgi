#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/14
#

use strict;no strict "refs";
use lib '../lib', '../src';
use mdDog::Doc::API;
use MYUTIL;

my $dog    = mdDog::Doc::API->new('api');
my $fid    = $dog->qParam('fid');
return unless( $fid );
$dog->init($fid);
$dog->login();
$dog->check_auths("is_edit", "is_admin");

my $action = $dog->qParam('action');
my $num    = $dog->qParam('num');

print "Content-type: application/json; charset=utf-8\n\n";
if($ENV{'REQUEST_METHOD'} eq 'GET'){
} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    if(   $action eq 'divide' &&  $num){
        print $dog->outline_add_divide($num);
    }
    elsif($action eq 'undivide' &&  $num ){
        print $dog->outline_remove_divide($num);
    }
}

exit();
