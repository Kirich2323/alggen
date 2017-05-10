use ALGGEN::TaskGenerator;

my %argv = @ARGV;
my $n = %argv{'--n'};
defined $n or $n = 1;
for(1..$n) {
    my $taskgen = ALGGEN::TaskGenerator->new();
    $taskgen->generate();
    $taskgen->save($argv{'--path'}, $_);
}