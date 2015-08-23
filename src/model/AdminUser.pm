package model::AdminUser {
    use strict;
    use Mouse;
    extends 'model::User';

    __PACKAGE__->meta->make_immutable();
}
1;
