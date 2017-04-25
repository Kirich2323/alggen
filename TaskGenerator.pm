package TaskGenerator;

use Archive::Zip;

use Constants;
use Task;
use ScalarTask;
use TestCase;
use Ans;

sub new {
    my $class = shift;
    my @scalar_tasks = (Average->new(), DifferentNumbers->new(), undef);
    my $self = {
        tasks => [ Relation->new(">") ],
        #tasks => [ Position->new() ],
        #tasks => [ Position->new(), Relation->new(">") ],
        test_number => $Constants::MIN_TEST_NUMBER,
        #scalar_task => @scalar_tasks[rand @scalar_tasks],
        scalar_task => DifferentNumbers->new(),
        zip => Archive::Zip->new()
    };
    bless $self, $class;
    $self;
}

sub gen_test_data {
    my ($n, $val) = @_;
    #print "\n$n";
    defined $n or $n = int(rand($Constants::MAX_N - $Constants::MIN_N)) + $Constants::MIN_N;
    defined $val and return [ map { $val } (1..$n) ];
    [ map { int(rand($Constants::MAX_VAL)) } (1..$n) ];
}

sub get_params() {
    my $self = shift;
    [  map { $_->get_params_val() } @{$self->{tasks}} ];
}

sub gen_test_set {
    my ($self) = @_;
    my @tests;
    for (1..$self->{test_number} - 4) {
        my $params = [ map { @$_ } ( map { $_->get_params_val() } @{$self->{tasks}} ) ];
        push @tests, TestCase->new( $self->get_params(), gen_test_data() );
    };
    push(@tests, TestCase->new( $self->get_params(), gen_test_data(1, 0) ));
    push(@tests, TestCase->new( $self->get_params(), gen_test_data(1, $Constants::MAX_VAL) ));
    push(@tests, TestCase->new( $self->get_params(), gen_test_data($Constants::MAX_N, 0) ));
    push(@tests, TestCase->new( $self->get_params(), gen_test_data($Constants::MAX_N, $Constants::MAX_VAL) ));
    $tests[0]->{array}->[0] = $tests[0]->{params}->[0] + 1;
    $tests[1]->{array}->[ $#{$tests[1]->{array}} ] =  $tests[1]->{params}->[0] + 1;
    $tests[2]->{array}->[0] = $tests[2]->{params}->[0];
    \@tests;
}

sub save_set {
    my ($self, $path, $elems, $type) = @_;
    ref $elems eq 'ARRAY' or die;
    for (0..$#{$elems}) {
        $self->{zip}->addString($elems->[$_]->to_string(), sprintf("$path\\%02d.$type", $_ + 1));
    }
}

sub save_tests {
    my ($self, $path) = @_;
    $self->save_set($path, $self->{tests}, "in");
}

sub generate {
    my $self = shift;
    my $constraints = {n => [$Constants::MIN_N, $Constants::MAX_N]};
    $self->{tests} = $self->gen_test_set();
}

sub save {
    my ($self, $path) = @_;
    $self->save_tests($path);
    $self->save_xml();
    $self->save_sol();
    $self->{zip}->writeToFileNamed('problem.zip');
}

sub save_sol {
    my $self = shift;
    my @vars_arr = map { keys %{$_->{constraints}} } @{$self->{tasks}};
    my $vars = join(', ', map {"\$$_"} @vars_arr);
    my $conditions = join(' && ', map $_->condition(), @{$self->{tasks}});
    my $scalar_code =  "";
    my $output_code = qq(print \$fo "\$s \\n";
print \$fo join(' ', \@ans););
    if (defined $self->{scalar_task}) {
        $scalar_code = $self->{scalar_task}->get_code();
        $output_code = qq(print \$fo \$scalar_ans;);
    }
    my $sol = qq(
open(my \$fi, "<", "input.txt");
open(my \$fo, ">", "output.txt");
my (\$n, $vars) = split (' ', <\$fi>);
my \@arr = split(' ', <\$fi>);
my \@ans;
my \$scalar_ans = 0;
for (0..\$#arr) {
    if ($conditions) {
        push \@ans, \@arr[\$_];
    }
}

my \$s = scalar \@ans;
if (\$s == 0) {
    print \$fo -1;
}
else {
    $scalar_code
    $output_code
}
close \$fi;
close \$fo;
);
    $self->{zip}->addString($sol, 'sol.pl');
}

sub save_xml {
    my $self = shift;
    my $task_text = join("\n", map {"<li>" . $_->get_text() . "</li>"} @{$self->{tasks}});
    my $tests_n = scalar @{$self->{tests}};

    my @vars_arr = map { keys %{$_->{constraints}} } @{$self->{tasks}};
    my $vars = join(', ', map {"\$$_\$"} @vars_arr);

    my @constraints =  map { $_->get_constraints() } @{$self->{tasks}};
    my @constrainst_blocks = map {qq(<p>
  $constraints[$_][0] \\le \$$vars_arr[$_]\$ \\le $constraints[$_][1]
</p>)} (0..$#constraints);
    my $constrainst_blocks_str = join("\n", @constrainst_blocks);

    my $xml_text = qq(<?xml version="1.0" encoding="UTF-8"?>
<CATS version="1.9">
<Problem title="Generated" lang="ru"
        author="Generator" tlimit="1" mlimit="256"
        inputFile="input.txt" outputFile="output.txt">
<ProblemStatement>
<p>
Дан массив \$a\$, состоящий из \$n\$ целых чисел. Требуется выписать все эелементы, которые:
    <ul>
        $task_text
    </ul>
</p>
<p>Если таких элементов нет, то следует выписать "-1" без кавычек.</p>
</ProblemStatement>

<InputFormat>
<p>
  В первой строчке находятся числа \$n\$, $vars. Во второй строчке следуют \$n\$ чисел \$a_i\$ - элементы массива \$a\$.
</p>
</InputFormat>

<OutputFormat>
<p>
  Первое число - количество элементов в ответе. Далее слуедуют числа через пробел.
</p>
</OutputFormat>

<ProblemConstraints>
<p>
  $Constants::MIN_N \\le \$n\$ \\le $Constants::MAX_N
</p>
$constrainst_blocks_str
</ProblemConstraints>

<Solution src="sol.pl" name="sol"/>
<Import guid="std.nums" type="checker"/>

<Test rank="1-$tests_n"><In src="tests/%0n.in" /></Test>

<Test rank="1-$tests_n"><Out use="sol"/></Test>

</Problem>
</CATS>);
    $self->{zip}->addString($xml_text, 'task.xml');
}

1;