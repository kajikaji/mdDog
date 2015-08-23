package mdDog::model::DocGroup {
    use Mouse;

    has 'gid'      => (is => 'rw', isa => 'Int');
    has 'name'     => (is => 'rw', isa => 'Str');
    has 'selected' => (is => 'rw', isa => 'Bool', default => 0);

    __PACKAGE__->meta->make_immutable();
}
1;
