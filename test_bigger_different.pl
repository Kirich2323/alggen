
open(my $fi, "<", "input.txt");
open(my $fo, ">", "output.txt");
my ($n, $k) = split (' ', <$fi>);
my @arr = split(' ', <$fi>);
my @ans;

for (0..$#arr) {
    if ($arr[$_] > $k) {
        push @ans, $arr[$_];
    }
}

my $s = scalar @ans;
if ($s == 0) {
    print $fo -1;
}
else {
    my $sans = 0;
    my %hash;
    foreach (@ans) {
        if (!exists $hash{$_}) {
            $sans++;
            $hash{$_} = 1;
        }
    }
    print $fo $sans;
}
close $fi;
close $fo;