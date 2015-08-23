package mdDog::model::GitLog{
    use strict;
    use Mouse;
    use Mouse::Util::TypeConstraints;
    use Date::Manip;

    has 'rev'       => (is => 'rw', isa => 'Str');
    has 'message'   => (is => 'rw', isa => 'Str');
    has 'author'    => (is => 'rw', isa => 'Str');
    has 'date'      => (is => 'rw', isa => 'Str');

    sub sha1_name {
        my $self = shift;
        my $sha1_name = $self->{rev};
        $sha1_name =~ s/^(.{7}).*/$1/;
        return $sha1_name;
    }

    sub html_message{
        my $self = shift;
        my $html = $self->{message};
        $html =~ s/</&lt;/g;
        $html =~ s/>/&gt;/g;
        $html =~ s/\n/<br>/g;
        $html =~ s/(.*)git-svn-id:.*/$1/;
        return $html;
    }

    sub author_name {
        my $self = shift;
        my $name = $self->{author};
        $name =~ s/(.*) <.*>/$1/;
        return $name;
    }

    sub format_datetime{
        my $self = shift;
        MYUTIL::format_date2($self->{date});
    }

    sub format_date{
        my $self = shift;
        MYUTIL::format_date3($self->{date});
    }
}
1;
