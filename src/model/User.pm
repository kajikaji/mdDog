package mdDog::model::User {
    use strict;
    use Mouse;

    has 'uid'       => ( is => 'rw', isa => 'Int');
    has 'account'   => ( is => 'rw', isa => 'Str' );
    has 'nic_name'  => ( is => 'rw', isa => 'Str' );
    has 'mail'      => ( is => 'rw', isa => 'Str');
    has is_admin    => ( is => 'rw', isa => "Bool", default => 0 );
    has is_live     => ( is => 'rw', isa => 'Bool' ,default => 1);

    has 'doc_editable' => ( is => 'rw', isa => 'Bool', default => 0);
    has 'doc_approval' => ( is => 'rw', isa => 'Bool', default => 0);
    has 'doc_owned'    => ( is => 'rw', isa => 'Bool', default => 0);

    sub set_docACL {
        my ($self, $row, $uid) = @_;
        $self->{doc_editable} = $row->{may_edit};
        $self->{doc_approval} = $row->{may_approve};
        $self->{doc_owned}    = $row->{created_by}==$uid?1:0;
    }

    sub is_Admin   { shift->{is_admin}; }
    sub is_Editable{ shift->{doc_editable}; }
    sub is_Approval{ shift->{doc_approval}; }
    sub is_Owned   { shift->{doc_owned}; }

    sub set_row{
        my ($self, $row) = @_;
        $self->{uid}      = $row->{id};
        $self->{is_admin} = $row->{may_admin};

        my @rows = qw/account mail nic_name is_live/;
        foreach (@rows){
            $self->{$_}   = $row->{$_};
        }
    }

    __PACKAGE__->meta->make_immutable();
}

1;

