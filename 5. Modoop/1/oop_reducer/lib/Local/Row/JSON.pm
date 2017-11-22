package Local::Row::JSON;

use strict;
use warnings;
use JSON::XS;

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
	eval { 
		my $self = {json => JSON::XS::decode_json($str)}; 
		return bless $self, $class;
	} or do { return undef; };	# если формат строки не распознается данным классом как допустимый, конструктор не создает объект и возвращает `undef`
}

# * `get($name, $default)` — возвращает значение поля `$name` строки лога или `$default`, если таковое отсутствует.
sub get {
	my ($self, $name, $default) = @_;
	return $self->{json}{$name} // $default;
}

1;
