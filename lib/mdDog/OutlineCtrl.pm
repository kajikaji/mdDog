package OutlineCtrl;

use strict; no strict "refs"; no strict "subs";
use base mdDog;
use constant A_DIV => "DIVIDE";
use constant A_INDT => "INDENT";

############################################################
# outline.datを編集する
#  フォーマット
#  [要素No]:[DIVIDE|INDENT|SIZEUP|SIZEDOWN|CENTER]:[COMMENT]
#

sub new {
  my $pkg = shift;
  my $workdir = shift;

  my $hash = {
    filename => "outline.dat",
    workdir  => $workdir,
  };

  return bless $hash, $pkg;
}

sub init {
  my $self = shift;
  my $datpath = "$self->{workdir}/$self->{filename}";

  unless(-f $datpath) {
    open my $hF, ">", $datpath || die "can't create $datpath";
    close($hF);
  }

  my $document;
  my $pos = 0;
  open my $hF, '<', $datpath || die "can't open $datpath";
  while(my $length = sysread $hF, $document, 1024, $pos) {
    $pos += $length;
  }
  close $hF;

  foreach(split(/\n/, $document)){
    my @cols = splic(/:/, $_);
    my $num = ${cols}[0];
    my $action = ${cols}[1];
    my $comment = ${cols}[2];

    $self->{$action}->{$num} = $comment;
  }
}


1;
