package ALGGEN::TaskGenerator;

use Archive::Zip;
use ALGGEN::Constants;
use ALGGEN::OutputTask;
use ALGGEN::Prog qw(make_expr);
use ALGGEN::TestGenerator;
use ALGGEN::Conditions;
use ALGGEN::Var;

my @output_tasks = (ALGGEN::OutputTask::Average->new(), ALGGEN::OutputTask::DifferentNumbers->new(), ALGGEN::OutputTask::Print->new());

sub new {
    my $class = shift;
    my $self = {
        output_task => @output_tasks[rand @output_tasks],
        zip => Archive::Zip->new(),
        text => [],
        vars => { n => ALGGEN::Var->new( 'n', [ $ALGGEN::Constants::MIN_N, $ALGGEN::Constants::MAX_N ], $ALGGEN::Constants::DEF_TYPE) },
        updates => {}
    };
    bless $self, $class;
    $self;
}

my $reserved_vars = { a => 1, i => 1, n => 1 };
my %op_to_text = ( '>' => 'больше', '<' => 'меньше', '==' => 'кратно' );

sub search_expr_for {
    my ($cond, $target) = @_;
    return $cond if (ref $cond eq $target);
    return undef if (ref $cond ne 'ALGGEN::Prog::BinOp');
    return search_expr_for($cond->{left}, $target) or search_expr_for($cond->{right}, $target);
}

sub get_expr_var {
    my ($expr) = @_;
    my $vars = {};
    $expr->gather_vars($vars);
    foreach (keys %{$vars}) {
        return $_ if (!exists($reserved_vars->{$_}));
    }
}

sub update_positions {
    my ($self, $val) = @_;
    $return_pos = sub { $_[0] * $val + $val - 1 };
    foreach(@{$self->{valid_positions}}) {
        my $new_left = int(($_->[0] + $val - 1) / $val);
        if($new_left * $val + $val - 1 <= $_->[1]) {
            $_ = [ $new_left, int(($_->[1] + $val - 1) / $val) ];
        }
    }
}

sub set_vars_constractions {
    my ($self, $cond) = @_;
    if ($cond->{op} eq '&&') {
        $self->set_vars_constractions($cond->{left});
        $self->set_vars_constractions($cond->{right});
    }
    else {
        my $type_text;
        my $constraints;
        my $type;
        if (search_expr_for($cond, 'ALGGEN::Prog::Index')) {
            $type_text = 'значение';
            $constraints = [ $ALGGEN::Constants::MIN_VAL, $ALGGEN::Constants::MAX_VAL ];
            $type = $ALGGEN::Constants::VAL_TYPE;
        }
        else {
            $type_text = 'положение';
            $constraints = [ $ALGGEN::Constants::MIN_N, $ALGGEN::Constants::MAX_N ];
            $type = $ALGGEN::Constants::POS_TYPE;
        }
        my $var = get_expr_var($cond);
        $self->{vars}->{$var} = ALGGEN::Var->new($var, $constraints, $type, $cond->{op});
        push (@{$self->{text}}, $type_text . ' которых ' . $op_to_text{$cond->{op}} . " \$$var\$");
    }
}

sub generate {
    my $self = shift;
    my $conditions = ALGGEN::Conditions->new();
    $self->{conditions} = $conditions->generate();
    $self->set_vars_constractions($self->{conditions});
}

sub save_gen() {
    my $self = shift;
    my $generator = ALGGEN::TestGenerator->new($self->{vars});
    $self->{zip}->addString($generator->gen(), 'gen.pl');
}

sub save {
    my ($self, $path, $n) = @_;
    $self->save_xml();
    $self->save_sol();
    $self->save_gen();
    my $n_txt = $n > 1 ? $n : '';
    my $fname = 'problem' . $n_txt . '.zip';
    defined $path or $path = $fname;
    if (-e $path) {
        if (-d $path) {
            $path .= $fname;
        }
        else {
            $path =~ /.zip/ or $path .= $fname;
        }
    }
    else {
        if (!($path =~ /.zip/)) {
            mkdir $path;
            $path .= $fname;
        }
    }
    $self->{zip}->writeToFileNamed($path);
}

sub save_sol {
    my $self = shift;
    my $vars = join(', ', map {"\$$_"} sort(keys %{$self->{vars}}));
    my $conditions = $self->{conditions}->to_lang();
    #my $scalar_code =  "";
    my $output_code = $self->{output_task}->get_code();
    #if (defined $self->{output_task}) {
    #    $scalar_code = $self->{output_task}->get_code();
    #    $output_code = qq(print \$fo \$scalar_ans;);
    #}
    my $sol = qq(
open(my \$fi, "<", "input.txt");
open(my \$fo, ">", "output.txt");
my ($vars) = split (' ', <\$fi>);
my \@a = split(' ', <\$fi>);
my \@ans;
my \$scalar_ans = 0;
for \$i (0..\$#a) {
    if ($conditions) {
        push \@ans, \$a[\$i];
    }
}

my \$size = scalar \@ans;
if (\$size == 0) {
    print \$fo -1;
}
else {
    $output_code
}
close \$fi;
close \$fo;
);
    $self->{zip}->addString($sol, 'sol.pl');
}

sub num_to_exp {
    my $num = shift;
    my $n = $num;
    my $base = 10;
    my $exp = 0;
    return $num if ($n % $base != 0 or $n == 0);
    while($n > 1) {
        return $num if ($n % $base != 0 or $n == 0);
        $exp++;
        $n = int($n / $base);
    }
    "$base^$exp";
}

sub save_xml {
    my $self = shift;
    my $task_text = join("\n", map {"<li>" . $_ . "</li>"} @{$self->{text}});
    my $vars = join(', ', map {"\$$_\$"} sort(keys %{$self->{vars}}));
    my @constrainst_blocks = map {"<p>
  \$" . num_to_exp($self->{vars}->{$_}->{constraints}->[0]) . " \\le $_ \\le " .  num_to_exp($self->{vars}->{$_}->{constraints}->[1]) . "\$
</p>"} sort(keys %{$self->{vars}});
    my $constrainst_blocks_str = join("\n", @constrainst_blocks);
    my $output_txt = $self->{output_task}->output_text;
    my $output_format = $self->{output_task}->output_format;
    my $xml_text = qq(<?xml version="1.0" encoding="UTF-8"?>
<CATS version="1.9">
<Problem title="Generated" lang="ru"
        author="Generator" tlimit="1" mlimit="256"
        inputFile="input.txt" outputFile="output.txt">
<ProblemStatement>
<p>
Дан массив \$a\$, состоящий из \$n\$ целых чисел. Требуется написать программу, которая $output_txt:
    <ul>
        $task_text
    </ul>
</p>
<p>Если таких элементов нет, то следует вывести "-1" без кавычек.</p>
</ProblemStatement>

<InputFormat>
<p>
  В первой строчке находятся числа $vars. Во второй строчке следуют \$n\$ чисел \$a_i\$ - элементы массива \$a\$.
</p>
</InputFormat>

<OutputFormat>
<p>
  $output_format
</p>
</OutputFormat>

<ProblemConstraints>
$constrainst_blocks_str
</ProblemConstraints>

<Solution src="sol.pl" name="sol"/>
<Generator src="gen.pl" name="gen"/>
<Import guid="std.nums" type="checker"/>

<Test rank="1-10"><In use="gen" param="--type tt" /></Test>
<Test rank="11-20"><In use="gen" param="--type tf" /></Test>
<Test rank="21-30"><In use="gen" param="--type ft" /></Test>
<Test rank="31-40"><In use="gen" param="--type ff" /></Test>
<Test rank="1-40"><Out use="sol"/></Test>

</Problem>
</CATS>);
    $self->{zip}->addString($xml_text, 'task.xml');
}

1;