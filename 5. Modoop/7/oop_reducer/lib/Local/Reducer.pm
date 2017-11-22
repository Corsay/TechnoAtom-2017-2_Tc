package Local::Reducer;

use strict;
use warnings;
use utf8;

=encoding utf8

=head1 NAME

Local::Reducer - base abstract reducer

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

# Параметры конструктора:
# * `source` — объект, выдающий строки из лога (см. ниже);
# * `row_class` — имя класса, с помощью которого создаются объекты из каждой строки логов (см. ниже);
# * `initial_value` — инициализационое значение для операции схлопывания.
sub new {
	my ($class, %param) = @_;
	my $self;
	$self->{$_} = $param{$_} foreach qw (field top bottom source row_class);
	$self->{reduced_value} = $param{initial_value};
	return bless $self, $class;
}

# * `reduced` — промежуточный результат.
sub reduced {
	return $_[0]->{reduced_value};
}

# * `reduce_all()` — схлопнуть все оставшиеся строки, вернуть результат.
sub reduce_all {
	return $_[0]->reduce_n;
}

1;
