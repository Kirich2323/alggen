package Collection;

sub new {
    my $class = shift;
    my $self = {
        array => shift
    };
    bless $self, $class;
    $self;
}

sub to_string { die; }

sub push_front {
    my ($self, $elem) = @_;
    unshift @{$self->{array}}, $elem;
}

sub push_back {
    my ($self, $elem) = @_;
    push @{$self->{array}}, $elem;
}

package Ans;
use base "Collection";

sub new {
    my $class = shift;
    my $self = {};
    my $param = shift;
    $self = $class->SUPER::new(shift);
    $self->{param} = $param;
    bless $self, $class;
    $self;
}

sub to_string {
    my $self = shift;
    my $size = scalar @{$self->{array}};
    if ($size > 0) {
        "$size " . join(" ", @{$self->{array}});
    }
    else {
        "NO";
    }
}

package TestCase;
use base "Collection";

sub new {
    my $class = shift;
    my $self = {};
    $self = $class->SUPER::new(shift);
    bless $self, $class;
    $self;
}

sub to_string {
    my $self = shift;
    my $size = scalar @{$self->{array}};
    "$self->{param}\n" . "$size " . join(" ", @{$self->{array}});
}

1;