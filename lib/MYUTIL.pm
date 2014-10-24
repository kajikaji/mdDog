package MYUTIL;

use strict;
use NKF;
use Encode qw/encode decode/;

sub adjustDiffLine {
  my $line = shift;
  my $ret;

  my @ary = split(/ /, $line);
  for (@ary)
  {
    my $str = $_;

    $str =~ s/ //g;
    $str =~ s/\t//g;
    next if($str =~ m/^$/);

    if( $str =~ m/\".*\"/){
      $str =~ s/\"(.*)\"/\1/g;
#      $str = nkf ('-m', $str);
    }

    $ret .= $str . "\n";
  }

  return $ret;
}

1;
