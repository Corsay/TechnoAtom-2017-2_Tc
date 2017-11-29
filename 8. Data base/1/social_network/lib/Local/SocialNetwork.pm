package Local::SocialNetwork;

use strict;
use warnings;

use parent 'Local::Object';


=encoding utf8

=head1 NAME

Local::SocialNetwork - social network user information queries interface

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

# инициализация объекта класса
sub init {
	my ($self, $data) = @_;

    $self->{_data} = $data;

    return;
}

sub print {
    my ($self) = @_;
	print "$self->{_data}\n";
}

# * Общий список друзей для двух заданных пользователей
sub mutual_friends {
	my ($self, $from, $to) = @_;

	return;
}

#  * Список пользователей, у которых нет друзей
sub nofriends {
    my ($self) = @_;

	return;
}

# * Количество рукопожатий между двумя заданными пользователями. 
# Более формально: требуется найти длину кратчайшего пути 
# между заданными двумя пользователями на графе дружбы социльной сети. 
sub handshakes {
	my ($self, $from, $to) = @_;

	return;
}

1;
