package Local::Row::Simple;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Row::Simple

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

# Параметры конструктора:
# * `str` — строка из источника.
sub new {
	my ($class, $str) = @_;
	my $self = {data => {$str =~ /(\w+)\s?:\s?(\d+),?/g}};
	return bless $self, $class;
}

# * `get($name, $default)` — возвращает значение поля `$name` строки лога или `$default`, если таковое отсутствует.
sub get {
	my ($self, $name, $default) = @_;
	return $self->{data}{$name} // $default;	# if (defined $self->{data}{$name}) {return $self->{data}{$name};} else {return $default;}
}

1;
