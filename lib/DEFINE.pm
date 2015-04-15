package DEFINE;

#
# author: gm2bv
# date: 2015/1/14
#

use strict; no strict "refs";
no warnings "uninitialized";
use Date::Manip;

sub param {
    my $hash = shift;
    my $relative = shift;

    my $myhash = {
        maintitle   => 'mdDog',
        subtitle    => '',
        description => 'is a MarkDown Document system On Git',
        author      => 'gm2bv',
        copyright   => 'gm2bv <gm2bv2001@gmail.com>',
        program     => 'mdDog',
        version     => 20150416,
        company     => '',
        repodir     => "${relative}work",
        paging_top  => 3,
    };

    $hash = {%{$hash}, %{$myhash}};
    return $hash;
}

1;
