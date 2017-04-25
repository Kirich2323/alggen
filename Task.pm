use Constants;

package Relation;

sub new {
    my $class = shift;
    my $self->{sign} = check_sign(shift);
    $self->{sign_text} = 'Больше';
    $self->{var} = 'K';
    $self->{constraints} = { 'K' => [ $Constants::MIN_VAL + 1, $Constants::MAX_VAL - 1 ] };
    bless $self, $class;
    $self;
}

sub check_sign {
    my ($sign) = @_;
    my @signs = qw(< >);
    $_ eq $sign and return $_ for @signs;
    die "Invalid sign";
}

sub get_params_val() {
    my $self = shift;
    map { int(rand($_->[1] - $_->[0])) + $_->[0] } values %{$self->{constraints}};
}

sub condition {
    my $self = shift;
    "\@arr[\$_] $self->{sign} \$$self->{var}";
}

sub get_constraints {
    my $self = shift;
    values %{$self->{constraints}};
}

sub get_text {
    my $self = shift;
    "$self->{sign_text} \$$self->{var}\$";
}

package Position;

sub new {
    my $class = shift;
    $self->{var} = 'P';
    $self->{constraints} = { 'P' => [ $Constants::MIN_N + 1, $Constants::MAX_N ] };
    bless $self, $class;
    $self;
}

sub get_params_val {
    my $self = shift;
    int( rand($Constants::MAX_N) );
    #[ 1 ];
}

sub condition {
    my $self = shift;
    "\$_ % \$$self->{var} == \$$self->{var} - 1";
}

sub get_constraints {
    my $self = shift;
    values %{ $self->{constraints} };
}

sub get_text {
    my $self = shift;
    "Стоят на \$$self->{var}\$-ой позиции";
}


1;