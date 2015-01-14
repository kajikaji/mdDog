package mdDogAPI;

#
# author: gm2bv
# date: 2015/1/14
#

use strict; no strict "subs";
use base mdDog;
#use Git::Wrapper;
#use Data::Dumper;
#use File::Copy;
#use File::Basename;
#use File::Path;
#use Date::Manip;
use Text::Markdown::Discount qw(markdown);
#use NKF;
#use Cwd;
#use Image::Magick;
#use JSON;
#use MYUTIL;
#use mdDog::GitCtrl;
#use mdDog::OutlineCtrl;


############################################################
#[API] JSONを返す
#
sub get_data {
  my $self = shift;
  my $uid = $self->{s}->param("login");
  return unless($uid);
  my $fid = $self->qParam('fid');
  my $eid = $self->qParam('eid');

  if($self->qParam('action') eq 'image_list'){
      $self->{git}->attach_local_tmp($uid);
      my $data;
      my $imgdir = "$self->{repodir}/${fid}/image";
      if( -d $imgdir){
          my @images = glob "$imgdir/*";
          $self->{git}->detach_local();

          foreach (@images) {
              my $path = $_;
              $path =~ s#$self->{repodir}/${fid}/image/(.*)$#\1#g;
              push @$data, {filename => $path};
          }
      }
      my $json = JSON->new();
      return $json->encode($data);
  } else {
      my $document = $self->get_user_document($uid, $fid);
      my ($rowdata, @partsAry) = $self->split_for_md($document);
      my $cnt = 0;
      my $data;

      foreach (@partsAry) {
          if ($eid) {
              if ($eid == $cnt) {
                  $data = [{eid => ${cnt}, data => $_}];
                  last;
              }
          } else {
              push @$data, { eid => ${cnt}, data => $_ };
          }
          $cnt++;
      }

      my $json = JSON->new();
      return $json->encode($data);
  }
}

############################################################
#[API]
#
sub post_data {
  my $self = shift;
  my $uid = $self->{s}->param("login");
  return unless($uid);
  my $fid = $self->qParam('fid') + 0;
  my $eid = $self->qParam('eid') + 0;
  my $data = $self->qParam('data');
  $data .= "\n" if( $data !~ m/(.*)\n$/);
  $data .= "\n" if( $data !~ m/(.*)\n\n$/);
  my $document = $self->get_user_document($uid, $fid);
  my ($rowdata, @partsAry) = $self->split_for_md($document);

  $self->{git}->attach_local_tmp($uid, 1);

  #ファイル書き込み
  # TODO: ファイル名取得ルーチンが重複！
  my $sql = "select file_name from docx_infos where id = ${fid};";
  my @ary = $self->{dbh}->selectrow_array($sql);
  return unless(@ary);
  my $filename = $ary[0];
  my $filepath = "$self->{repodir}/${fid}/${filename}";

  open my $hF, '>', $filepath || return undef;
  my $cnt = 0;
  my @newAry;
  my $line;
  foreach(@partsAry) {
    if($eid == $cnt){
      $line = $data . "\n";
    }else{
      $line = $_ . "\n";
    }
    syswrite $hF, $line, length($line);
    $cnt++;
  }
  close $hF;

  my $author = $self->get_author($self->{s}->param('login'));
  $self->{git}->commit($filename, $author, "temp saved");
  $self->{git}->detach_local();

  my $json = JSON->new();
  my $md;# = markdown($data);
  my ($row, @parts) = $self->split_for_md($data, $eid);
  $cnt = $eid;
  foreach(@parts){
    my $conv .= markdown($_)    if($_ !~ m/^\n*$/);
    $conv =~ s/^<([a-z1-9]+)>/<\1 id=\"md${cnt}\" class=\"Md\">/;
    $conv =~ s#^<([a-z1-9]+) />#<\1 id=\"md${cnt}\" class=\"Md\" />#;
    $conv =~ s#"md_imageView\.cgi\?(.*)"#"md_imageView.cgi?tmp=1&\1"#g;
    $conv =~ s/^(.*)\n$/\1/;
    $md .= $conv;
    $cnt++;
  }
  return $json->encode({eid => ${eid}, md => ${md}, row => ${row}});
}

############################################################
#[API]
#
sub delete_data {
  my $self = shift;
  my $uid = $self->{s}->param("login");
  return unless($uid);
  my $fid = $self->qParam('fid') + 0;
  my $eid = $self->qParam('eid');

  my $document = $self->get_user_document($uid, $fid);
  my ($rowdata, @partsAry) = $self->split_for_md($document);

  $self->{git}->attach_local_tmp($uid, 1);

  #ファイル書き込み
  # TODO: ファイル名取得ルーチンが重複！
  my $sql = "select file_name from docx_infos where id = ${fid};";
  my @ary = $self->{dbh}->selectrow_array($sql);
  return unless(@ary);
  my $filename = $ary[0];
  my $filepath = "$self->{repodir}/${fid}/${filename}";

  open my $hF, '>', $filepath || return undef;
  my $cnt = 0;
  foreach(@partsAry) {
    if($eid != $cnt){
      my $line = $_ . "\n";
      syswrite $hF, $line, length($line);
    }
    $cnt++;
  }
  close $hF;

  my $author = $self->get_author($self->{s}->param('login'));
  $self->{git}->commit($filename, $author, "temp saved");
  $self->{git}->detach_local();

  my $json = JSON->new();
  return $json->encode({eid => ${eid}});
}

############################################################
#[API] アウトラインで改ページを加える
#
sub outline_add_divide {
  my $self = shift;

  my $uid = $self->{s}->param("login");
  return unless($uid);
  my $fid = $self->qParam('fid') + 0;

  my $num = $self->qParam('num');
  my $author = $self->get_author($self->{s}->param('login'));
  my $comment = "INSERT DIVIDE";
  $self->{git}->attach_local_tmp($uid, 1);
  $self->{outline}->insert_divide($num, $comment);
  $self->{git}->commit($self->{outline}->{filename}, $author, $comment);
  $self->{git}->detach_local();
  my $json = JSON->new();
  return $json->encode({action => 'divide',num => ${num}});
}

############################################################
#[API] アウトラインに設定された改ページを削除する
#
sub outline_remove_divide {
  my $self = shift;

  my $uid = $self->{s}->param("login");
  return unless($uid);
  my $fid = $self->qParam('fid') + 0;

  my $num = $self->qParam('num');
  my $author = $self->get_author($self->{s}->param('login'));
  my $comment = "REMOVE DIVIDE";
  $self->{git}->attach_local_tmp($uid, 1);
  $self->{outline}->remove_divide($num);
  $self->{git}->commit($self->{outline}->{filename}, $author, $comment);
  $self->{git}->detach_local();
  my $json = JSON->new();
  return $json->encode({action => 'undivide',num => ${num}});
}

############################################################
#[API] 指定のrevisionのJSONデータを返す
#
sub get_revisiondata {
  my $self = shift;

  my $fid = $self->qParam('fid');
  my $sql = "select file_name from docx_infos where id = ${fid};";
  my @ary = $self->{dbh}->selectrow_array($sql);
  return unless(@ary);

  my $filename = $ary[0];
  my $filepath = "$self->{repodir}/${fid}/${filename}";
  my $document;
  my $revision = $self->qParam('revision');
  my $user = $self->qParam('user');
  $user = undef if($user == 0);

  my $gitctrl = $self->{git};

  my $user_root = $gitctrl->get_branch_latest($user);
  $revision = $user_root unless($revision);
  my $oneLog = $gitctrl->one_log($revision);

  $gitctrl->attach_local($user);
  $gitctrl->checkout_version($revision);

  open my $hF, '<', $filepath || die "failed to read ${filepath}";
  my $pos = 0;
  while (my $length = sysread $hF, $document, 1024, $pos) {
    $pos += $length;
  }
  close $hF;

  $gitctrl->detach_local();
  my $json = JSON->new();
  return $json->encode({
      name => $filename,
      document => markdown($document),
      revision => $revision,
      commitDate => MYUTIL::format_date1($oneLog->{attr}->{date}),
      commitMessage => $oneLog->{message},
  });
}

############################################################
#[API] 指定のrevisionの差分を返す
#
sub get_diff {
  my $self = shift;

  my $fid = $self->qParam('fid');
  my $sql = "select file_name from docx_infos where id = ${fid};";
  my @ary = $self->{dbh}->selectrow_array($sql);
  return unless(@ary);

  my $filename = $ary[0];
  my $revision = $self->qParam('revision');
  my $dist = $self->qParam('dist');
  my $diff = $self->{git}->get_diff($revision, $dist);

  my $json = JSON->new();
  return $json->encode({
      name => $filename,
      revision => $revision,
      dist => $dist?$dist:'ひとつ前',
      diff => $diff,
  });

}

1;
