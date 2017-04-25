package Average;

sub new {
    my $class = shift;
}

sub get_code {
    my $self = shift;
    qq(\$scalar_ans += \$_ for(\@ans);
\$scalar_ans /= \$s;
\$scalar_ans = int(\$scalar_ans);
);
}

package DifferentNumbers;

sub new {
    my $class = shift;
}

sub get_code {
    my $self = shift;
    qq(my \%numbers;
foreach (\@ans) {
    if(!exists \$numbers{\$_}) {
        \$scalar_ans++;
        \$numbers{\$_} = 1;
    }
});
}

1;