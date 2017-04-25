use TaskGenerator;

my $taskgen = TaskGenerator->new();
$taskgen->generate();
$taskgen->save("tests");