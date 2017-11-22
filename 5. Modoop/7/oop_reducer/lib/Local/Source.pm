package Local::Source;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Source

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

# * `next` — возвращает очередную строку или `undef`, если лог исчерпан.
sub next {
	my $self = shift;
	if (@{$self->{array}} > $self->{lines})
	{
		return @{$self->{array}}[$self->{lines}++];
	}
	return undef;
}

1;
