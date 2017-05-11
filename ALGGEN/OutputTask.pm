package ALGGEN::OutputTask::Print;

sub new {
    my $class = shift;
}

sub get_code {
    my $self = shift;
    q(print $fo "$size \n";
print $fo join(' ', @ans);
);
}

sub output_text {
    'выводит эелементы';
}

sub output_format {
    'Требуется вывести число - количество элементов в ответе. Затем через пробел требуется вывести сами элементы.';
}

package ALGGEN::OutputTask::Average;

sub new {
    my $class = shift;
}

sub get_code {
    my $self = shift;
    q($scalar_ans += $_ for(@ans);
$scalar_ans /= $size;
$scalar_ans = int($scalar_ans);
print \$fo \$scalar_ans;
);
}

sub output_text {
    'выводит целую часть среднеарефметического элементов';
}

sub output_format {
    'Требуется вывести в выходной файл единственное число - целую часть среднеарефметического элементов.';
}

package ALGGEN::OutputTask::DifferentNumbers;

sub new {
    my $class = shift;
}

sub get_code {
    my $self = shift;
    q(my %numbers;
foreach (@ans) {
    if(!exists $numbers{$_}) {
        $scalar_ans++;
        $numbers{$_} = 1;
    }
}
print \$fo \$scalar_ans;
);
}

sub output_text {
    'выводит количество различных элементов';
}

sub output_format {
    'Требуется вывести в выходной файл единственное число - количество различных элементов.';
}

1;