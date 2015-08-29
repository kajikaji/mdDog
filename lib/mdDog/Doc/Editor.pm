package mdDog::Doc::Editor;

use strict; no strict "subs";
use parent mdDog::Doc;
use Text::Markdown::MdDog qw/markdown paragraph_html paragraph_raw alter_paragraph paragraphs/;

# @summary MDドキュメントの編集バッファをテンプレートにセットする
#
sub set_buffer_md{
    my ($self, $uid, $fid) = @_;
    return unless($uid);

    my $document = $self->_get_user_document($uid, $fid);
    my $raws     = paragraphs($document);
    my $md       = markdown($document);
    $md =~ s#"plugin/image_viewer\.cgi\?(.*)"#"plugin/image_viewer.cgi?tmp=1&$1" #g;

    return ($md, $raws);
}

# @summary アウトラインの改ページ情報の取得
#
sub set_outline_buffer{
    my ($self, $uid, $fid) = @_;
    return unless($uid);

    $self->{git}->attach_info($uid);
    $self->{outline}->init();
    $self->{git}->detach_local();

    my $divides = $self->{outline}->get_divides();
    return $divides;
}


1;
