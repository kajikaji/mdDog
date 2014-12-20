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

####################################################################
# ハッシュをクリアしてデータファイルから解析して新たに生成
sub init {
  my $self = shift;
  my $datpath = "$self->{workdir}/$self->{filename}";

  foreach ('DIVIDE','INDENT','SIZEUP','SIZEDOWN','CENTER') {
    $self->{$_} = undef;
  }
  return unless(-f $datpath);

  my $document;
  my $pos = 0;
  open my $hF, '<', $datpath || die "can't open $datpath";
  while(my $length = sysread $hF, $document, 1024, $pos) {
    $pos += $length;
  }
  close $hF;

  foreach(split(/\n/, $document)){
    my @cols = split(/:/, $_);
    my $num = ${cols}[0];
    my $action = ${cols}[1];
    my $comment = ${cols}[2];

    $self->{$action}->{$num} = $comment;
  }
}

####################################################################
#
sub insertDivide {
  my $self = shift;
  my $num = shift;
  my $comment = shift;

  #読込＆解析
  $self->init();

  unless($self->{'DIVIDE'}->{$num}){
    my $datpath = "$self->{workdir}/$self->{filename}";
    open my $hF, '>>', $datpath || die "can't open ${datpath}";
    #書込み
    my $line = "${num}:DIVIDE:${comment}\n";
    print $hF $line;
    close $hF;
  }
}

####################################################################
#
#
sub removeDivide {
  my $self = shift;
  my $num = shift;

  $self->init();

  if($self->{'DIVIDE'}->{$num}){
    my $datpath = "$self->{workdir}/$self->{filename}";
    open my $hF, '>', $datpath || die "can't open ${datpath}";
    foreach (keys %{$self->{'DIVIDE'}}) {
      if($_ ne $num) {
        my $cnum = $_;
        my $ccomment = $self->{'DIVIDE'}->{$cnum};
        my $line = "${cnum}:DIVIDE:${ccomment}\n";
        print $hF $line;
      }
    }
    close $hF;
  }
}

####################################################################
#
# !! 配列で返します
sub getDivide {
  my $self = shift;
  my $ret;
  my @divides = keys %{$self->{'DIVIDE'}};
  for (sort { $a > $b } @divides){
    push @$ret, $_;
  }
  return $ret;
}

1;
