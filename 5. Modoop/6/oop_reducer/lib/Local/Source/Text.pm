package Local::Source::Text;
use parent Local::Source;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Source::Text

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

# * `Local::Source::Text` — отдает построчно текст, который передается в конструктор в параметре `text`. 
# Разделитель — `\n`, но можно изменить параметром конструктора `delimiter`.
sub new {
	my ($class, %param) = @_;

	$param{delimiter} = $param{delimiter} // '\n'; # $param{delimiter} = '\n' unless exists $param{delimiter}
	$param{text} = [split $param{delimiter}, $param{text}];

	my $self = {array => $param{text}};
	$self->{lines} = 0;
	return bless $self, $class;
}

1;
