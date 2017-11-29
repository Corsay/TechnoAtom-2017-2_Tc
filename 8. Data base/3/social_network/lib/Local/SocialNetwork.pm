package Local::SocialNetwork;

use strict;
use warnings;

use DBI;
use DBD::SQLite;
use JSON::XS;		# * Ответ приложения `bin/social_network.pl` должен быть в формате `JSON`

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

	my $driver   = "SQLite";
	my $db_name = "users_relation.db";
	my $dbd = "DBI:$driver:dbname=$db_name";
	my $username = "";  # не ожидает логин и пароль
	my $password = "";

	# создаем и запоминаем соединение с БД
	$self->{dbh} = DBI->connect($dbd, $username, $password, { RaiseError => 1 })
  		or die "can not connect to DB '$db_name': ".$DBI::errstr;

    return;
}

# деструктор, при уничтожении объекта закрываем соединение с БД
sub DESTROY {
	my ($self) = @_;
	$self->{dbh}->disconnect();
}

# Возможные возвращаемые значения:
# undef - ошибка во время выполнения
# результирующий JSON
# пустой результирующий JSON

# * Общий список друзей для двух заданных пользователей
sub friends {
	my ($self, $from, $to) = @_;

	# контроль параметров
	return undef unless (defined $from and defined $to);
	return undef if ($from !~ /^\d+$/);
	return undef if ($to !~ /^\d+$/);

	# обработка
	my $json = "friends";
	print "$json\n";
	my $djson = {'first_name' => 'Игорь', 'last_name' => 'Федотов', 'id' => 1};
	return JSON::XS::encode_json([$djson]);
}

#  * Список пользователей, у которых нет друзей
sub nofriends {
    my ($self) = @_;
	my $djson = $self->{dbh}->selectall_arrayref("SELECT * FROM user where id == 49968", { Slice => {} });
	return JSON::XS::encode_json([$djson]);
}

# * Количество рукопожатий между двумя заданными пользователями.
# Более формально: требуется найти длину кратчайшего пути
# между заданными двумя пользователями на графе дружбы социльной сети.
sub num_handshakes {
	my ($self, $from, $to) = @_;

	# контроль параметров
	return undef unless (defined $from and defined $to);
	return undef if ($from !~ /^\d+$/);
	return undef if ($to !~ /^\d+$/);

	# обработка
	my $json = "num_handshakes";
	print "$json\n";
	my $djson = "-1";
	return JSON::XS::encode_json([$djson]);
}

1;
