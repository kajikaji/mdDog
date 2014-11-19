package MYUTIL;

use strict;
use NKF;
use Encode qw/encode decode/;
use Date::Manip;
use Data::Dumper;

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

sub formatDate1 {
  my $date = shift;
  $date =~ s/^(.*) \+0900/\1/;
  return  UnixDate(ParseDate($date), "%Y-%m-%d %H:%M:%S");
}

sub formatDate2 {
  my $date = shift;
  $date =~ s/^(.*) \+0900/\1/;
  return  UnixDate(ParseDate($date), "%Y年%m月%d日 %H時%M分%S秒");
}

sub isInclude {
  my $branches = shift;
  my $val = shift;
  my $ret = undef;

  my @ary = @$branches;
  foreach(@ary) {
    my $branch = $_;
    $branch =~ s/^[\s\*]*(.*)\s*$/\1/;
    if($branch =~ m/^${val}$/){
      $ret = 1;
      last;
    }
  }

  return $ret;
}

sub DebugExit {
  my $obj    = shift;
  my $dumper = shift;

  print "Content-type: text/html\n\n";
  if($dumper){
    print Dumper $obj;
  }else{
    print $obj;
  }
  exit;
}

1;
