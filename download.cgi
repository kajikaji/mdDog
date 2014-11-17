#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use mdDog;
use Data::Dumper;

my $dog =mdDog->new();
$dog->setupConfig();

my $fid = $dog->qParam('fid');
my $rev = $dog->qParam('revision');

exit() unless($fid);

$dog->downloadFile($fid, $rev);
exit();
