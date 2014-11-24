package DEFINE;

use strict; no strict "refs";
no warnings "uninitialized";
use Date::Manip;

sub param {
    my $hash = shift;
    my $relative = shift;

    my $myhash = {
        maintitle   => 'docxLog',
        subtitle    => 'made by gm2bv',
        description => '',
        aution      => 'gm2bv',
        copyright   => 'Copyright by gm2bv',
        program     => 'docxlog',
        version     => 20141021,
        company     => '',
        repodir     => "${relative}work",
    };

    $hash = {%{$hash}, %{$myhash}};
    return $hash;
}

1;
