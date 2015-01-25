#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/14
#

use strict;no strict "refs";
use lib './lib';
use mdDog;

my $dog = mdDog->new();
$dog->setup_config();
unless($dog->login()){
    $dog->{t}->{error} = "この操作はログインする必要があります<br>create.cgi";
}else{
    if($dog->qParam('create')){
	$dog->create_file();
	print "Location: index.cgi\n\n";
	exit();
    }
}

$dog->print_page();
exit();
