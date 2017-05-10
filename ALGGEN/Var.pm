package ALGGEN::Var;

sub new {
    my $class = shift;
    my $self = {
        name => shift,
        constraints => shift,
        type => shift,
        op => shift
    };
    bless $self, $class;
    $self;
}

1;