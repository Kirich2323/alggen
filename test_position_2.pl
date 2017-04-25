#use strict;
open(my $fi, "<", "input.txt");
open(my $fo, ">", "output.txt");
my ($n, $P) = split (' ', <$fi>);
my @arr = split(' ', <$fi>);
my @ans;
for (0..$#arr) {
    if ($_ % $P == $P - 1) {
        push @ans, @arr[$_];
    }
}

my $s = scalar @ans;
if ($s == 0) {
    print $fo -1;
}
else {
    print $fo "$s \n";
    print $fo join(' ', @ans);
}
close $fi;
close $fo;