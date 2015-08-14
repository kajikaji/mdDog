package mdDog::Doc::Editor;

use strict; no strict "subs";
use parent mdDog::Doc;
use Text::Markdown::MdDog qw/markdown paragraph_html paragraph_raw alter_paragraph paragraphs/;

# @summary MDドキュメントの編集バッファをテンプレートにセットする
#
sub set_buffer_md{
    my $self     = shift;

    my $uid      = $self->{s}->param("login");
    return unless($uid);
    my $fid      = $self->qParam('fid');
    my $document = $self->_get_user_document($uid, $fid);
    my $md       = markdown($document);
    $md =~ s#"plugin/image_viewer\.cgi\?(.*)"#"plugin/image_viewer.cgi?tmp=1&$1" #g;

    $self->{t}->{markdown} = $md;
    $self->{t}->{raws} = paragraphs($document);
}

# @summary アウトラインの改ページ情報の取得
#
sub set_outline_buffer{
    my $self = shift;

    my $uid = $self->{s}->param("login");
    return unless($uid);

    $self->{git}->attach_info($uid);
    $self->{outline}->init();
    $self->{git}->detach_local();

    my $divides = $self->{outline}->get_divides();
    $self->{t}->{divides} = $divides;
}


1;
