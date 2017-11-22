package Local::Reducer::Sum;
use parent Local::Reducer;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Reducer::Sum

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

# * `reduce_n($n)` — схлопнуть очередные `$n` строк, вернуть промежуточный результат.
sub reduce_n {
	my($self, $n) = @_;
	while (1) {
		if (defined($n)) { last if ($n-- == 0); }
		my $line = $self->{source}->next();
		last unless defined $line;

		if (my $row_obj = $self->{row_class}->new(str => $line)) {
			my $value = $row_obj->get($self->{field}, 0);
			$self->{reduced_value} += $value if ($value =~ /\d+/);
		}
	}
	return $self->reduced;
}

1;
