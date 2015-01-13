#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/14
#

use strict; no strict "refs";
use lib './lib/';
use mdDog;
use Data::Dumper;

my $dog =mdDog->new();
$dog->setup_config();

my $fid = $dog->qParam('fid');
my $rev = $dog->qParam('revision');

exit() unless($fid);

$dog->download_file($fid, $rev);
exit();
