package ALGGEN::TestGenerator;

use ALGGEN::Constants;
use ALGGEN::Var;

sub new {
    my $class = shift;
    my $self = {
        vars => shift
    };
    bless $self, $class;
    $self;
}

sub gen_constaints {
    my ($self) = @_;
    my $txt = q(my %params;
my %constraints = );
    $txt .= '( ' . join(', ', map { " $_->{name} => [ $_->{constraints}->[0], $_->{constraints}->[1] ]" } values %{$self->{vars}}) . ' );';
}

sub generate {
    my ($self) = @_;
    $self->set_params();
    $self->gen();
}

sub gen_updates {
    my ($self) = @_;
    my @txt;
    push @txt, 'my $pos_facts';
    push @txt, 'my $val_facts';
    my $pos_mult_count = 0;
    my $val_mult_count = 0;
    foreach(values %{$self->{vars}}) {
        my $val = $self->{params}->{$_->{name}};
        my $op = $_->{op};
        if ($_->{type} eq $ALGGEN::Constants::POS_TYPE) {
            if ($op eq '==') {
                push @txt, "\$pos_facts = merge_factors(\$pos_facts, factorization(\$$_->{name}))";
                $pos_mult_count++;
            }
            else {
                push @txt, "update_positions(\$$_->{name}, '$op')";
            }
        }
        elsif ($_->{type} eq $ALGGEN::Constants::VAL_TYPE) {
            if ($op eq '==') {
                push @txt, "\$val_facts = merge_factors(\$val_facts, factorization(\$$_->{name}))";
                $val_mult_count++;
            }
            else {
               push @txt, "update_values(\$$_->{name}, '$op')";
            }
        }
    }
    if ($pos_mult_count > 0) {
        push @txt, "update_positions(build_number_from_factors(\$pos_facts), '==')";
    }
    if ($val_mult_count > 0) {
        push @txt, "update_values(build_number_from_factors(\$val_facts), '==')";
    }
    \@txt;
}

my $set_params_txt = q(sub set_params {
    my ($p) = @_;
    foreach(keys %constraints) {
        if(defined $p and exists($p->{$_})) {
            $params{$_} = $p{$_};
        }
        else {
            my $left = $constraints{$_}->[0];
            my $right = $constraints{$_}->[1];
            $params{$_} = int(rand($right - $left)) + $left;
        }
    }
});

my $prog_txt = q(
my $valid_values = [ [ $MIN_VAL, $MAX_VAL ] ];
my $valid_positions = [ [ $MIN_N, $MAX_N ] ];

my $return_val = sub { $_[0] };
my $to_val_coord = sub { $_[0] };
my $return_pos = sub { $_[0] };
my $to_pos_coord = sub { $_[0] };

my %val_updates = (
    '>' => sub {
        return [ $to_val_coord->($_[0] + $return_val->(1)), $_[1]->[1] ] if ($_[0] >= $return_val->($_[1]->[0]) &&
                                                                             $_[0] <= $return_val->($_[1]->[1]) &&
                                                                             $_[0] + $return_val->(1) <= $return_val->($_[1]->[1]));
        return $_[1] if ($_[0] <= $return_val->($_[1]->[0]));
        return undef;
     },
    '<' => sub {
        return [ $_[1]->[0], $to_val_coord->($_[0] - $return_val->(1)) ] if ($_[0] >= $return_val->($_[1]->[0]) &&
                                                                             $_[0] <= $return_val->($_[1]->[1]) &&
                                                                             $_[0] - $return_val->(1) >= $return_val->($_[1]->[0]));
        return $_[1] if ($_[0] >= $return_val->($_[1]->[1]));
        return undef;
      },
    '==' => sub {
        my $new_left = $to_val_coord->($_[1]->[0]);
        my $new_right = $to_val_coord->($_[1]->[1]);
        return [ $new_left, $new_right - ( ($return_val->($new_right) <= $_[1]->[1] ? 0 : 1) ) ] if($return_val->($new_left) <= $_[1]->[1]);
        return undef;
    }
);
my %pos_updates = (
    '>' => sub {
        return [ $to_pos_coord->($_[0] + $return_pos->(1)), $_[1]->[1] ] if ($_[0] >= $return_pos->($_[1]->[0]) &&
                                                                             $_[0] <= $return_pos->($_[1]->[1]) &&
                                                                             $_[0] + $return_pos->(1) <= $return_pos->($_[1]->[1]));
        return $_[1] if ($_[0] <= $return_pos->($_[1]->[0]));
        return undef;
     },
    '<' => sub {
        return [ $_[1]->[0], $to_pos_coord->($_[0] - $return_pos->(1)) ] if ($_[0] >= $return_pos->($_[1]->[0]) &&
                                                                             $_[0] <= $return_pos->($_[1]->[1]) &&
                                                                             $_[0] - $return_pos->(1) >= $return_pos->($_[1]->[0]));
        return $_[1] if ($_[0] >= $return_pos->($_[1]->[1]));
        return undef;
      },
    '==' => sub {
        my $new_left = $to_pos_coord->($_[1]->[0]);
        my $new_right = $to_pos_coord->($_[1]->[1]);
        return [ $new_left, $new_right - ( ( $return_pos->($new_right) <= $_[1]->[1] ) ? 0 : 1 ) ] if($return_pos->($new_left) <= $_[1]->[1]);
        return undef;
    }
);

sub update_values {
    my ($val, $sign) = @_;
    my @tmp_arr;
    if ($sign eq '==') {
        $return_val = sub { $_[0] * $val };
        $to_val_coord = sub { int(($_[0] + $val - 1) / $val) };
         foreach(@$valid_values) {
            my $new_constraints = $val_updates{$sign}->($val, $_);
            push @tmp_arr, $new_constraints if(defined $new_constraints);;
        }
    }
    else {
        foreach($valid_values) {
            my $new_constraints = $val_updates{$sign}->($val, @$_);
            push @tmp_arr, $new_constraints if(defined $new_constraints);
        }
    }
    $valid_values = \@tmp_arr;
}

sub update_positions {
    my ($val, $sign) = @_;
    my @tmp_arr;
    if ($sign eq '==') {
        $return_pos = sub { $_[0] * $val };
        $to_pos_coord = sub { int(($_[0] + $val - 1) / $val) };
         foreach(@$valid_positions) {
            my $new_constraints = $pos_updates{$sign}->($val, $_);
            push @tmp_arr, $new_constraints;
        }
    }
    else {
        foreach($valid_positions) {
            my $new_constraints = $pos_updates{$sign}->($val, @$_);
            if (defined $new_constraints) {
                push @tmp_arr, $new_constraints;
            }
        }
    }
    $valid_positions = \@tmp_arr;
}

sub check_prime {
    my ($val) = @_;
    for(2..int(sqrt($val))) {
        return undef if($val % $_ == 0);
    }
    return $val;
}
my @primes;
for (2..10**5) {
    push @primes, $_ if(defined check_prime($_));
}

sub factorization {
    my ($val) = @_;
    my %factors;
    foreach(@primes) {
        my $count = 0;
        my $tmp = $val;
        while($tmp % $_ == 0 && $tmp > 1) {
            $count++;
            $tmp = int($tmp / $_);
        }
        if ($count > 0) {
            $factors{$_} = $count;
        }
    }
    if (scalar (keys %factors) == 0) {
        $factors{$val} = 1;
    }
    \%factors;
}

sub merge_factors {
    my ($left, $right) = @_;
    my $factors = $right;
    foreach(keys %$left) {
        if(exists $factors->{$_}) {
            $factors->{$_} = max($left->{$_}, $right->{$_});
        }
        else {
            $factors->{$_} = $left->{$_};
        }
    }
    $factors;
}

sub build_number_from_factors {
    my ($factors) = @_;
    my $num = 1;
    foreach(keys %$factors) {
        $num *= $_**$factors->{$_};
    }
    $num;
}
sub rand_in_range {
    my ($left, $right) = @_;
    int(rand($right - $left + 1))  + $left;
}

sub rand_pick {
    my ($arr) = @_;
    $arr->[int(rand(scalar @$arr))];
}

sub get_and_split {
    my ($arr, $idx) = @_;
    my $elem = rand_in_range(@{$arr->[$idx]});
    my @list;
    push @list, [ $arr->[$idx]->[0], $elem - 1 ] if $elem != $arr->[$idx]->[0];
    push @list, [ $elem + 1, $arr->[$idx]->[1] ] if $elem != $arr->[$idx]->[1];
    splice @$arr, $idx, 1, @list;
    $elem;
}

sub get_valid_positions {
    my ($n) = @_;
    defined $n or $n = int rand(total_valid_pos() + 1);
    my @pos;
    my $tmp_arr = [ map { [ @$_ ] } @$valid_positions ];
    for (1..$n) {
        my $idx = int rand(scalar @$tmp_arr);
        if (@$tmp_arr > 0) {
            my $elem = get_and_split($tmp_arr, $idx);
            push @pos, $return_pos->($elem);
        }
        else {
            last;
        }
    }
    \@pos;
}

sub get_invalid_positions {
    my ($n) = @_;
    defined $n or $n = int rand(total_invalid_pos());
    my %valid_pos = map { $_ => 1 } @{ get_valid_positions(total_valid_pos()) };
    my %ans;
    for(1..$n) {
        my $init_pos = rand_in_range(( $MIN_N, $MAX_N ));
        my $pos = $init_pos;
        while(exists($valid_pos{$pos}) or exists($ans{$pos})) {
            $pos = $pos % $MAX_N + 1;
            if ($pos == $init_pos) {
                $pos = undef;
                last;
            }
        }
        if (defined $pos) {
            $ans{$pos} = 1;
        }
        else {
            last;
        }
    }
    [ keys %ans ];
}

sub get_valid_value {
    if (@$valid_values > 0) {
        my $value_range = rand_pick($valid_values);
        rand_in_range(@$value_range);
    }
    else {
        undef;
    }
}

sub get_invalid_value {
    if (@$valid_values > 0) {
        my $value_range = rand_pick($valid_values);
        my $values = rand_pick([ [ $value_range->[0] - 1, $value_range->[1] + 1], [ $value_range->[1] + 1, $value_range->[0] - 1 ] ]);
        return $values->[0] if ($values->[0] >= $MIN_VAL and $values->[0] <= $MAX_VAL);
        return $values->[1] if ($values->[1] >= $MIN_VAL and $values->[1] <= $MAX_VAL);
        return undef;
    }
    else {
        rand_in_range( ($MIN_VAL, $MAX_VAL) );
    }
}

sub total_valid_pos {
    my $ans = 0;
    for(@$valid_positions) {
        $ans += $_->[1] - $_->[0] + 1 for($_);
    }
    $ans;
}

sub total_invalid_pos {
    $MAX_N - total_valid_pos();
}

my %test_types = (
    tt => [ \&get_valid_positions,   \&get_valid_value   ],
    tf => [ \&get_valid_positions,   \&get_invalid_value ],
    ft => [ \&get_invalid_positions, \&get_valid_value   ],
    ff => [ \&get_invalid_positions, \&get_invalid_value ]
);

my %argv = @ARGV;

sub generate {
    my ($arr) = @_;
    my $type = $argv{'--type'};
    my ($pos_getter, $val_getter) = @{$test_types{$type}};
    foreach (@{$pos_getter->()}) {
        $arr->[ $_ - 1 ] = $return_val->($val_getter->());
    }
}

my @arr = map rand_in_range(@{$valid_values->[0]}), (1..$MAX_N);
);

my $output = q(open(my $fh, '>', 'input.txt');
print $fh join(' ', map { $params{$_} } sort(keys %params) ) . "\n";
print $fh join(' ', @arr ) . "\n";
close($fh);
);

sub gen {
    my ($self) = @_;
    my $constraints = $self->gen_constaints();
    my $param_names = '( ' . join(', ', map { "\$$_" } sort (keys %{$self->{vars}}) ) . ' )';
    my $param_values = '( ' . join(', ', map { "\$params{$_}" } sort(keys %{$self->{vars}}) ) . ' )';
    my $updates_text = join(";\n", @{$self->gen_updates()});
    my $text = qq(
$constraints
$set_params_txt
set_params();
my \$MAX_VAL = $ALGGEN::Constants::MAX_VAL;
my \$MIN_VAL = $ALGGEN::Constants::MIN_VAL;
my \$MIN_N = $ALGGEN::Constants::MIN_N;
my \$MAX_N = \$params{n};
$prog_txt
my $param_names = $param_values;
$updates_text;
generate(\\\@arr);
$output
);
}

1;