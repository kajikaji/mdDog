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

print "Content-type: application/json; charset=utf-8\n\n";
if( $ENV{'REQUEST_METHOD'} eq 'GET' ){
    return unless( $action );
    my $eid  = $dog->qParam('eid') + 0;
    print $dog->get_data($eid, $action);
} elsif( $ENV{'REQUEST_METHOD'} eq 'POST' ){
    if(    $action eq 'update' ){
        my $eid  = $dog->qParam('eid') + 0;
        my $data = $dog->qParam('data');
        print $dog->update_paragraph($eid, $data);
    }
    elsif( $action eq 'delete' ){
        my $eid  = $dog->qParam('eid') + 0;
        print $dog->delete_paragraph($eid);
    }
    elsif( $action eq 'rollback' ){
        my $revision = $dog->qParam('revision');
        print $dog->rollback_buffer($revision);
    }
    elsif( $action eq 'editLog' ){
        my $revision = $dog->qParam('revision');
        my $comment  = $dog->qParam('comment');
        print $dog->edit_log($revision, $comment);
    }
    elsif( $action eq 'merge' ){
        my $doc = $dog->qParam('doc');
        print $dog->restruct_document($doc);
    }
    elsif( $action eq 'bufferclear' ){
        print $dog->clear_user_buffer();
    }
}

exit();
