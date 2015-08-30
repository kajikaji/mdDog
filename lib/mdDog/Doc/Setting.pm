package mdDog::Doc::Setting;

use strict; no strict "subs";
use parent mdDog::Doc;
use SQL;
use model::User;

sub get_document_users {
    my ($self) = @_;
    my @users;
    my @unallows;

    my $sth = $self->{dbh}->prepare(SQL::document_auth_infos);
    $sth->execute($fid);
    while( my $row = $sth->fetchrow_hashref() ){
        my $user = mdDog::model::User->new(
            uid          => $row->{uid},
            account      => $row->{account},
            nic_name     => $row->{nic_name},
            mail         => $row->{mail},
            is_admin     => $row->{may_admin},
            is_live      => $row->{is_used},
            doc_editable => $row->{may_edit},
            doc_approval => $row->{may_approve},
            doc_owned    => $row->{is_owned}
        );
        push @users, $user;
    }
    $sth->finish();

    $sth = $self->{dbh}->prepare(SQL::document_unallow_users);
    $sth->execute($self->{fid});
    while( my $row = $sth->fetchrow_hashref() ){
        my $user = mdDog::model::User->new();
        $user->{uid}      = $row->{id};
        $user->{account}  = $row->{account};
        $user->{nic_name} = $row->{nic_name};
        push @unallows, $user;
    }
    $sth->finish();

    return \@users, \@unallows;
}


# @summary ドキュメントの名称を変更
#
sub change_doc_name {
    my ($self, $doc_name)     = @_;
    return 0 unless( $doc_name );

    $self->{teng}->update('docx_infos' => {
        doc_name => $doc_name
    }, {
        id => $self->{fid}
    });

    $self->dbCommit();
    return 1;
}

1;
