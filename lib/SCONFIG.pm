package SCONFIG;

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
