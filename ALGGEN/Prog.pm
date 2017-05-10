use strict;
use warnings;
use utf8;

package ops;

sub power { '**' }
sub mult { '*', '/', '%', '//' }
sub add { '+', '-' }
sub comp { '>', '<', '==', '!=', '>=', '<=' }
sub logic { '&&', '||', '^', '=>', 'eq' }

package ALGGEN::Prog::SynElement;

sub new {
    my ($class, %init) = @_;
    my $self = { %init };
    bless $self, $class;
    $self;
}

sub to_lang { die; }
sub gather_vars {}
sub needs_parens { 0 }

sub prio_list {
    [ ops::power ], [ ops::mult ], [ ops::add ],
    [ ops::comp ], [ '^', '=>' ], [ '&&' ], [ '||' ],
}

my $priorites = {};

my @raw = prio_list;
for my $prio (1 .. @raw) {
    $priorites->{$_} = $prio for @{$raw[$prio - 1]};
}

package ALGGEN::Prog::Index;
use base 'ALGGEN::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    sprintf '%s[%s]',
        $self->{array}->to_lang(),
        join ', ', map $_->to_lang(), @{$self->{indices}};
}

package ALGGEN::Prog::Op;
use base 'ALGGEN::Prog::SynElement';

sub new {
    my $self = shift->SUPER::new(@_);
    die "Bad op: $self->{op}" if defined $self->{op} && ref $self->{op} || !$self->{op};
    $self;
}

sub _children {}
sub children { @{$_[0]}{$_[0]->_children} }

sub prio { $priorites->{$_[0]->{op}} or die "prio: $_[0]->{op}" }

sub operand {
    my ($self, $operand) = @_;
    my $t = $operand->to_lang();
    $operand->needs_parens($self->prio()) ? "($t)" : $t;
}

sub to_lang {
    my ($self) = @_;
    sprintf
        $self->to_lang_fmt($self->{op}),
        map $self->operand($_), $self->children;
}

sub needs_parens {
    my ($self, $parent_prio) = @_;
    $parent_prio < $self->prio();
}

sub gather_vars { $_->gather_vars($_[1]) for $_[0]->children; }
sub to_lang_fmt {}

package ALGGEN::Prog::BinOp;
use base 'ALGGEN::Prog::Op';
use List::Util;

sub to_lang_fmt {
    my ($self) = @_;
    my $fmt = "%s $self->{op} %s";
    $fmt = "%s %% %s" if ($self->{op} eq '%');
    $fmt;
}

sub _children { qw(left right) }

package ALGGEN::Prog::UnOp;
use base 'ALGGEN::Prog::Op';

sub prio { $_[1]->{prio}->{'`' . $_[0]->{op}} or die $_[0]->{op} }

sub to_lang_fmt {
    my ($self, $lang) = @_;
    $lang->get_fmt('un_op_fmt', $self->{op});
}

sub _children { qw(arg) }

package ALGGEN::Prog::Var;
use base 'ALGGEN::Prog::SynElement';

sub to_lang {
    my ($self) = @_;
    qq(\$$self->{name});
}

sub gather_vars { $_[1]->{$_[0]->{name}} = 1 }

package ALGGEN::Prog::Const;
use base 'ALGGEN::Prog::SynElement';

sub to_lang {
    my ($self) = @_;
    $self->{value};
}

package ALGGEN::Prog::CompoundStatement;
use base 'ALGGEN::Prog::SynElement';

sub to_lang_fields {}

sub to_lang {
    my ($self, $lang) = @_;
    my $body_is_block = @{$self->{body}->{statements}} > 1;
    no strict 'refs';
    my ($fmt_start, $fmt_end) =
        map $lang->get_fmt($_, $body_is_block || $lang->{body_is_block}), $self->get_fmt_names;

    if (ref $lang->{html} eq 'HASH' && defined(my $c = $lang->{html}->{coloring})) {
        my $s = { ALGGEN::Html::html->style(color => shift @$c) };
        $_ =~ s/([^\n]+)/ALGGEN::Html::html->tag('span', $1, $s)/ge for ($fmt_start, $fmt_end);
    }

    my $body = $self->{body}->to_lang($lang);
    $body =~ s/^/  /mg if !$lang->{unindent} && $fmt_start =~ /\n$/; # отступы
    sprintf
        $fmt_start . $self->to_lang_fmt . $fmt_end,
        map($self->{$_}->to_lang($lang), $self->to_lang_fields), $body;
}

sub _visit_children { my $self = shift; $self->{$_}->visit_dfs(@_) for $_->to_lang_fields, 'body' }

package ALGGEN::Prog;
use base 'Exporter';
our @EXPORT_OK = qw(make_expr);

sub tail { @_[1..$#_] }

sub make_expr {
    my ($src) = @_;
    defined $src or die 'empty argument';
    ref($src) =~ /^ALGGEN::Prog::/ and return $src;
    if (ref $src eq 'ARRAY') {
        @$src or return undef;
        my $op = $src->[0] // '';
        $op ne '' or die 'bad op';
        if (@$src >= 2 && $op eq '[]') {
            my @p = tail @$src;
            $_ = make_expr($_) for @p;
            my $array = shift @p;
            return ALGGEN::Prog::Index->new(array => $array, indices => \@p);
        }
        #if (@$src == 2) {
        #    return ALGGEN::Prog::UnOp->new(
        #        op => $op, arg => make_expr($src->[1]));
        #}
        if (@$src == 3) {
            return ALGGEN::Prog::BinOp->new(
                op => $op,
                left => make_expr($src->[1]),
                right => make_expr($src->[2])
            );
        }
        die "make_expr: @$src";
    }
    if ($src =~ /^[[:alpha:]][[:alnum:]_]*$/) {
        return ALGGEN::Prog::Var->new(name => $src);
    }
    return ALGGEN::Prog::Const->new(value => $src);
}

1;