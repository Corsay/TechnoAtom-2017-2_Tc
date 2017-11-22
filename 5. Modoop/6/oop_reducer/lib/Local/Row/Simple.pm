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
	my ($class, %str) = @_;
	my $self = {data => $str{str}};
	return bless $self, $class;
}

# * `get($name, $default)` — возвращает значение поля `$name` строки лога или `$default`, если таковое отсутствует.
sub get {
	my ($self, $name, $default) = @_;
	$self->{data} =~ m/$name\s?:\s?(\w+)/;
	return $1 // $default;	# if (defined $1) {return $1;} else {return $default;}
}

1;
