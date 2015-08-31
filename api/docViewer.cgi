#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/14
#

use strict;no strict "refs";
use lib '../lib', '../src';
use mdDog::Doc::API;
use MYUTIL;

my $dog = mdDog::Doc::API->new('api');
my $fid = $dog->qParam('fid');
return unless($fid);
$dog->init($fid);
$dog->login();

print "Content-type: application/json; charset=utf-8\n\n";
if($ENV{'REQUEST_METHOD'} eq 'GET'){
} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    my $action   = $dog->qParam('action');

    if(    $action =~ m/show/ ){
        my $revision = $dog->qParam('revision');
        my $user     = $dog->qParam('user');
        print $dog->get_revisiondata($revision, $user);
    }
    elsif( $action =~ m/diff/ ){
        my $revision = $dog->qParam("revision");
        my $dist     = $dog->qParam('dist');
        print $dog->get_diff($revision, $dist);
    }
}

exit();
