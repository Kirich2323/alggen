#use strict;
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
    print $fo "$s \n";
    print $fo join(' ', @ans);
}
close $fi;
close $fo;