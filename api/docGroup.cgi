#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/7/7
#

use strict;no strict "refs";
use lib '../lib', '../src';
use mdDog::Doc::API;

my $dog = mdDog::Doc::API->new('api');
my $fid = $dog->qParam('fid');
return unless( $fid );
$dog->init($fid);
$dog->login();
$dog->check_auths("is_edit", "is_admin");

print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){
    print $dog->get_doc_groups;
}elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ){
    if( my $search = $dog->qParam('search') ){
        print $dog->search_groups($search);
    }
    if( $dog->qParam('action') eq 'editGroup' ){
        my @groups = $dog->qParam('groups[]');
        print $dog->add_groups(\@groups);
    }
}

exit();
