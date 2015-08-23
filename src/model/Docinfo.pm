package mdDog::model::Docinfo{
    use strict;
    use Mouse;
    use Mouse::Util::TypeConstraints;
    use Date::Manip;
    use DateTime;
    use DateTime::Format::Pg;
    use model::DocGroup;

    my $pgParser = DateTime::Format::Pg->new();

    class_type 'DateTime';

    coerce 'DateTime'
        => from 'Str'
        => via { $pgParser->parse_datetime($_) };

    has 'fid'             => (is => 'rw', isa => 'Int' );
    has 'doc_name'        => ( is => 'rw', isa => 'Str' );
    has 'file_name'       => ( is => 'rw', isa => 'Str' );
    has 'created_at'      => ( is => 'rw', isa => 'DateTime', coerce => 1 );
    has 'deleted_at'      => ( is => 'rw', isa => 'Maybe[DateTime]', coerce => 1 );
    has 'created_by'      => (is => 'rw', isa => 'Str');
    has 'is_public'       => (is => 'rw', isa => 'Bool');
    has 'is_approval'     => (is => 'rw', isa => 'Bool');
    has 'is_editable'     => (is => 'rw', isa => 'Bool');
    has 'is_used'         => (is => 'rw', isa => 'Bool');

    has 'is_owned'        => (is => 'rw', isa => 'Bool');
    has 'file_size'       => (is => 'rw', isa => 'Int');
    has 'last_updated_at' => (is => 'rw', isa => 'Str');
    has 'groups'          => (is => 'rw', isa => 'ArrayRef[DocGroup]');

    sub set_row{
        my ($self, $row) = @_;

        $self->{fid}         = $row->{id};
        $self->{created_by}  = $row->{nic_name};
        $self->{is_approval} = $row->{may_approve};
        $self->{is_editable} = $row->{may_edit};

        my @rows = qw/doc_name file_name is_used created_at deleted_at is_public/;
        foreach(@rows){
            $self->{$_}      = $row->{$_};
        }
    }

    sub format_created_at{
        my $self = shift;
        UnixDate($self->{created_at}, "%Y年%m月%d日 %H時%M分%S秒");
    }

    sub format_file_size{
        my $self = shift;
        MYUTIL::num_unit($self->{file_size});
    }

    __PACKAGE__->meta->make_immutable();
}
1;
