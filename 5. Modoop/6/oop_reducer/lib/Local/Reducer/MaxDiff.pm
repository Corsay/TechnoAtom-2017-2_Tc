package Local::Reducer::MaxDiff;
use parent Local::Reducer;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Reducer::MaxDiff

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
			my $top = $row_obj->get($self->{top});
			my $bottom = $row_obj->get($self->{bottom});
			# В случае, если соответствующие поля не содержат числовые значения, строка игнорируется.
			if (defined ($top) && defined($bottom) && ($top =~ /\d+/) && ($bottom =~ /\d+/)) {
				my $value = $top - $bottom;
				$self->{reduced_value} = $value if $value > $self->{reduced_value};
			}
		}
	}
	return $self->reduced;
}

# * `reduce_all()` — схлопнуть все оставшиеся строки, вернуть результат.
sub reduce_all {
	my ($self) = @_;
	while (my $line = $self->{source}->next()) {
		if (my $row_obj = $self->{row_class}->new(str => $line)) {
			my $top = $row_obj->get($self->{top});
			my $bottom = $row_obj->get($self->{bottom});
			# В случае, если соответствующие поля не содержат числовые значения, строка игнорируется.
			if (defined ($top) && defined($bottom) && $top =~ /\d+/ && $bottom =~ /\d+/) {
				my $value = $top - $bottom;
				$self->{reduced_value} = $value if $value > $self->{reduced_value};
			}
		}
	}
	return $self->reduced;
}

1;
