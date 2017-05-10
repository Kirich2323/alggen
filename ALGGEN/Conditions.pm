package ALGGEN::Conditions;

use ALGGEN::Constants;
use ALGGEN::Prog qw(make_expr);

sub value { [ '[]', 'a', 'i' ] }
sub position { 'i' }

sub new {
    my $class = shift;
    my $self = {
        var_names => [ 'b'..'h', 'j'..'m', 'o'..'z', 'A'..'Z' ],
        val_signs => [ qw(> <) ],
        pos_signs => [ qw(> <) ]
    };
    bless $self, $class;
    $self;
}

sub get_var {
    my ($self) = @_;
    my $n = rand(int(scalar @{$self->{var_names}}));
    splice @{$self->{var_names}}, $n, 1;
}

sub get_val_sign {
    my ($self) = @_;
    my $n = rand(int(scalar @{$self->{val_signs}}));
    splice @{$self->{val_signs}}, $n, 1;
}

sub get_pos_sign {
    my ($self) = @_;
    my $n = rand(int(scalar @{$self->{pos_signs}}));
    splice @{$self->{pos_signs}}, $n, 1;
}

sub generate {
    my ($self, $n) = @_;
    defined $n or $n = int(rand($ALGGEN::Constants::MAX_CONDITIONS)) + 1;
    $n = 1;
    $self->{conditions} = [
        sub { [ $self->get_val_sign, value, $self->get_var ] },
        sub { [ '==', [ '%', [ '+', value, '1' ], $self->get_var ], '0' ] },
        sub { [ $self->get_pos_sign, position, $self->get_var ] },
        sub { [ '==', [ '%', [ '+', position, '1' ] , $self->get_var, ], '0' ] },
    ];
    my @conds;
    for(1..$n) {
        my $idx = int rand(@{$self->{conditions}});
        push @conds, make_expr($self->{conditions}->[$idx]->());
        if (@{$self->{val_signs}} == 0) {
            splice @{$self->{conditions}}, $idx, 1;
            push @{$self->{val_signs}}, 1;
        }
        if (@{$self->{pos_signs}} == 0) {
            splice @{$self->{conditions}}, $idx, 1;
            push @{$self->{pos_signs}}, 1;
        }
    }
    my $left = shift @conds;
    foreach(0..$#conds) {
        my $tmp_left = ALGGEN::Prog::BinOp->new(
            op => '&&',
            left => $left,
            right => $conds[$_]
        );
        $left = $tmp_left;
    }
    $left;
}

1;