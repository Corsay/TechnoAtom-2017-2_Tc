package Local::Source::FileHandle;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Source::FileHandler

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

# * `Local::Source::FileHandler` — отдает поэлементно массив, который передается в конструктор в параметре `array`.
sub new {
	my ($class, %param) = @_;
	my $self = {fh => $param{fh}};
	return bless $self, $class;
}

sub next {
	my $self = shift;
	my $fh = $self->{fh};
	return undef if eof($fh);
	# gодразумеваем что файл открыт для чтения
	my $data = <$fh>;
	chomp($data);
	return $data;
}

1;
