package MYUTIL;

# --------------------------------------------------------------------
# @Author Yoshiaki Hori
# @copyright 2014 Yoshiaki Hori gm2bv2001@gmail.com
#
# This file is part of mdDog.
#
# mdDog is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# mdDog is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------

use strict;
use NKF;
use Encode qw/encode decode/;
use Date::Manip;
use Data::Dumper;

sub adjust_diff_line {
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
      $str =~ s/\"(.*)\"/$1/g;
#      $str = nkf ('-m', $str);
    }

    $ret .= $str . "\n";
  }

  return $ret;
}

sub format_date1 {
  my $date = shift;
  $date =~ s/^(.*) \+0900/$1/;
  return  UnixDate(ParseDate($date), "%Y-%m-%d %H:%M:%S");
}

sub format_date2 {
  my $date = shift;
  $date =~ s/^(.*) \+0900/$1/;
  return  UnixDate(ParseDate($date), "%Y年%m月%d日 %H時%M分%S秒");
}

sub format_date3 {
  my $date = shift;
  $date =~ s/^(.*) \+0900/$1/;
  return  UnixDate(ParseDate($date), "%Y年%m月%d日");
}

sub num_unit {
  my $num = shift;
  $num =~ s/(\d{1,3})(?=(?:\d{3})+(?!\d))/$1,/g;
  return $num;
}

sub is_include {
  my $branches = shift;
  my $val = shift;
  my $ret = undef;

  my @ary = @$branches;
  foreach(@ary) {
    my $branch = $_;
    $branch =~ s/^[\s\*]*(.*)\s*$/$1/;
    if($branch =~ m/^${val}$/){
      $ret = 1;
      last;
    }
  }

  return $ret;
}

sub debug_exit {
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

sub _fread {
    my ($path) = @_;

    open my $h, '<', $path || die "Fail to read ${path}";
    my $pos = 0;
    my $doc;
    while( my $leng = sysread $h, $doc, 1024, $pos ){
      $pos += $leng;
    }
    close $h;
    return ($doc, $pos);
}

1;
