package Local::Reducer::MinMaxAvg;
use parent Local::Reducer;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Reducer::MinMaxAvg

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

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
