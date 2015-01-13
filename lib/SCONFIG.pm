package SCONFIG;

#
# author: gm2bv
# date: 2015/1/14
#

use strict; no strict "refs";
no warnings "uninitialized";
use Date::Manip;

sub param {
  my $hash = shift;

  my $myhash = {
    dsn         => 'dbi:Pg:host=[DBHOST] dbname=[DBNAME]',
    duser       => '[DBUSER]',
    dpass       => '[DBPASS]',
  };

  $hash = {%{$hash}, %{$myhash}};
  return $hash;
}

1;
