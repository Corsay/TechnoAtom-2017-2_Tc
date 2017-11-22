package Local::Reducer::MinMaxAvgRez;
use parent Local::Reducer;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Reducer::MinMaxAvgRez

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

sub new {
	# qw (field top bottom source row_class initial_value)
	my ($class, %param) = @_;
	my $self;
	$self->{$_} = $param{$_} foreach qw (field top bottom source row_class);
	$self->{'reduced_value'} = $param{initial_value};
	#$self->{'reducer_MinMaxAvg'} = 	# объект для MinMaxAvg
	return bless $self, $class;
}

# * `reduce_n($n)` — схлопнуть очередные `$n` строк, вернуть промежуточный результат.
sub reduce_n {
	my($self, $n) = @_;
	for (1..$n) {
		my $line = $self->{source}->next();
		last unless defined $line;

		if (my $row_obj = $self->{row_class}->new(str => $line)) {
			my $value = $row_obj->get($self->{field}, 0);
			$self->{reduced_value} += $value if ($value =~ /\d+/);
		}
	}
	return $self->reduced;
}

# * `reduce_all()` — схлопнуть все оставшиеся строки, вернуть результат.
sub reduce_all {
	my ($self) = @_;
	while (my $line = $self->{source}->next()) {
		if (my $row_obj = $self->{row_class}->new(str => $line)) {
			my $value = $row_obj->get($self->{field}, 0);
			$self->{reduced_value} += $value if ($value =~ /\d+/);
		}
	}
	return $self->reduced;
}

# Результат (`reduced`) отдается в виде объекта с методами `get_max`, `get_min`, `get_avg`
sub reduced {
	return $_[0]->{'reduced_value'};
}

1;
