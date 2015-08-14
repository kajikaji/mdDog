package mdDog::Doc::Image;

use strict; no strict "subs";
use parent mdDog::Doc;
use Image::Magick;

# @summary MDドキュメントで管理している画像一覧を取得
#
sub set_md_image{
    my $self   = shift;

    my $uid    = $self->{s}->param("login");
    return unless($uid);
    my $fid    = $self->qParam('fid');
    my $imgdir = "$self->{repodir}/${fid}/image";

    unless(-d $imgdir){
        mkdir $imgdir, 0774 || die "can't make image directory.";
    }

    $self->{git}->attach_local_tmp($uid);
    my @images = glob "$imgdir/*";
    $self->{git}->detach_local();

    my @imgpaths;
    foreach (@images) {
        my $path = $_;
        $path =~ s#$self->{repodir}/${fid}/image/(.*)$#$1#g;
        push @imgpaths, $path;
    }

    $self->{t}->{images} = \@imgpaths;
    $self->{t}->{uid}    = $self->{s}->param("login");
}

# @summary 画像をアップロードしてユーザーの編集バッファにコミット
#
sub upload_image {
    my $self     = shift;

    my $fid      = $self->qParam('fid');
    my $uid      = $self->{s}->param("login");
    return 0 unless($fid && $uid);

    my $hF       = $self->{q}->upload('imagefile');
    my $filename = basename($hF);

    $self->{git}->attach_local_tmp($uid, 1);

    my $imgdir   = "$self->{repodir}/${fid}/image";
    unless(-d $imgdir){
        mkdir $imgdir, 0774 || die "can't make image directory.";
    }
    my $tmppath  = $self->{q}->tmpFileName($hF);
    my $filepath = "${imgdir}/${filename}";
    move ($tmppath, $filepath) || die "Upload Error!. $filepath";
    close($hF);

    my $thumbnail = $self->_add_thumbnail($fid, $filename);

    my $author = $self->_get_author($self->{s}->param('login'));
    $self->{git}->add_image($filepath, $author);
    $self->{git}->add_image($thumbnail, $author);

    $self->{git}->detach_local();
    push @{$self->{t}->{message}->{info}},  "画像をアップロードしました";
    return 1;
}

# @summary 画像を削除
#
sub delete_image {
    my $self = shift;

    my $fid  = $self->qParam('fid');
    my $uid  = $self->{s}->param("login");
    return 0 unless($uid && $fid);

    my @selected = ($self->qParam('select_image'));

    $self->{git}->attach_local_tmp($uid);
    my $author = $self->_get_author($self->{s}->param('login'));
    $self->{git}->delete_image([@selected], $author);
    $self->{git}->detach_local();
    push @{$self->{t}->{message}->{info}}, "画像を削除しました";
    return 1;
}

# @summary 画像のサムネイルを作成
# @param1 fid
# @param2 ファイル名
#
sub _add_thumbnail {
    my $self     = shift;
    my $fid      = shift;
    my $filename = shift;

    my $imgpath  = "$self->{repodir}/${fid}/image/${filename}";
    my $thumbdir = "$self->{repodir}/${fid}/thumb";
    unless(-d $thumbdir){
        mkdir $thumbdir, 0774 || die "can't make thumbnail directory.";
    }

    my $mImg = Image::Magick->new();
    $mImg->Read($imgpath);
    my ($w, $h) = $mImg->get('width', 'height');
    my ($rw, $rh);
    if ($w > THUMBNAIL_SIZE || $h > THUMBNAIL_SIZE) { #サイズが大きいときだけリサイズ
        if ($w >= $h) {
            $rw = THUMBNAIL_SIZE;
            $rh = THUMBNAIL_SIZE / $w * $h;
        } else {
            $rh = THUMBNAIL_SIZE;
            $rw = THUMBNAIL_SIZE / $h * $w;
        }
        $mImg->Resize(width=>$rw, height=> $rh);
    }
    $mImg->Write("${thumbdir}/${filename}");
    return "${thumbdir}/${filename}";
}

1;
