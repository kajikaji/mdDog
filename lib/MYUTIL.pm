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

sub isInclude {
  my $branches = shift;
  my $val = shift;
  my $ret = undef;

  my @ary = @$branches;
  foreach(@ary) {
    my $branch = $_;
    $branch =~ s/^\s*(.*)\s*$/\1/;
    if($branch =~ m/${val}/){
      $ret = 1;
      last;
    }
  }

  return $ret;
}

1;
