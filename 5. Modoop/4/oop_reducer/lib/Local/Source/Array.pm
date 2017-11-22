package Local::Source::Array;
use parent Local::Source;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Source::Array

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

# * `Local::Source::Array` — отдает поэлементно массив, который передается в конструктор в параметре `array`.
sub new {
	my ($class, %param) = @_;
	my $self = {array => $param{array}};
	$self->{lines} = 0;
	return bless $self, $class;
}

1;
