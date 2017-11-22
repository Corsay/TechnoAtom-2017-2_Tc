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

sub new {
	my ($class, %param) = @_;
	my $self = Local::Reducer->SUPER::new(%param);
	$self->{reduced_value} = Local::Reducer::MinMaxAvgRez->new();
	$self->{sum} = 0;
	$self->{count} = 0;
	return bless $self, $class;
}

# * `reduce_n($n)` — схлопнуть очередные `$n` строк, вернуть промежуточный результат.
sub reduce_n {
	my($self, $n) = @_;
	while (1) {
		if (defined($n)) { last if ($n-- == 0); }
		my $line = $self->{source}->next();
		last unless defined $line;

		if (my $row_obj = $self->{row_class}->new(str => $line)) {
			my $value = $row_obj->get($self->{field});
			if ($value =~ /\d+/) {
				my $MMA = $self->{reduced_value};
				$MMA->get_max($value) if (not defined $MMA->get_max or $MMA->get_max < $value);
				$MMA->get_min($value) if (not defined $MMA->get_min or $MMA->get_min > $value);
				$self->{sum} +=  $value;
				$self->{count}++;
				$MMA->get_avg($self->{sum} / $self->{count});
			}
		}
	}
	return $self->reduced;
}


package Local::Reducer::MinMaxAvgRez;
use Class::XSAccessor
	constructor => 'new',
	accessors => [ 'get_min', 'get_max', 'get_avg' ];

1;
