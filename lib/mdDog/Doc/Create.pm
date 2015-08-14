package mdDog::Doc::Create;

use strict; no strict "subs";
use NKF;
use parent mdDog::Doc;

# @summary MDファイルを作る
#
sub create_file {
    my $self = shift;
    my $uid  = $self->{s}->param("login");

    my $docname = nkf("-w", $self->qParam('doc_name'));
    my $filename = nkf("-w", $self->qParam('file_name'));
    $docname =~ s/^\s*(.*)\s*$/$1/;
    $docname =~ s/^(.*)\..*$/$1/;
    return unless($docname);
    unless( $filename ){
        $filename = $docname;
    } else {
        $filename =~ s/^\s*(.*)\s*$/$1/;
        $filename =~ s/^(.*)\..*$/$1/;
    }
    $filename =~ s/　/ /g;
    $filename =~ s/\s/_/g;

    my $fname = $filename . "\.md";
    my $fid      = $self->_setup_new_file($docname, $fname, $uid);
    my $workdir  = "$self->{repodir}/${fid}";
    my $filepath = "${workdir}/${fname}";
    open my $hF, ">", $filepath || die "Create Error!. $filepath";
    close($hF);

    $self->{git}     = GitCtrl->new($workdir);
#    $self->{outline} = OutlineCtrl->new($workdir);
    $self->{git}->init($fid, [$fname], $self->_get_author($uid));

    $self->dbCommit();
}

# @summary ドキュメントの新規作成
# @param1 filename
# @param2 uid
#
sub _setup_new_file{
    my $self     = shift;
    my $docname  = shift;
    my $filename = shift;
    my $uid      = shift;

    my $fid = $self->{teng}->fast_insert('docx_infos' => {
        'doc_name'   => $docname,
        'file_name'  => $filename,
        'created_at' => 'now()',
        'created_by' => $uid,
    });

    mkdir("./$self->{repodir}/$fid",0776)
      || die "Error:_setup_new_file can't make a directory($self->{repodir}/$fid)";

    $self->{teng}->fast_insert('docx_auths', => {
        'info_id'     => $fid,
        'user_id'     => $uid,
        'may_approve' => 'true',
        'may_edit'    => 'true',
        'created_at'  => 'now()',
        'created_by'  => $uid,
        'updated_at'  => 'now()'
    });

    return $fid;
}

1;
