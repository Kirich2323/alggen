package TestCase;

sub new {
    my $class = shift;
    my $self = {
        params => shift,
        array => shift
    };
    bless $self, $class;
    $self;
};

sub to_string {
    my $self = shift;
    my $size = scalar @{$self->{array}};
    "$size " . join(' ', @{$self->{params}}) . "\n" . join(" ", @{$self->{array}});
}

sub push_front {
    my ($self, $elem) = @_;
    unshift @{$self->{array}}, $elem;
}

sub push_back {
    my ($self, $elem) = @_;
    push @{$self->{array}}, $elem;
}

1;