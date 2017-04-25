package Ans;

sub new {
    my $class = shift;
    my $self = {
        array => shift
    };
    bless $self, $class;
    $self;
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