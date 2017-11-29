package Local::SocialNetwork;

use strict;
use warnings;

use DBI;
use DBD::SQLite;
use JSON::XS;		# * Ответ приложения `bin/social_network.pl` должен быть в формате `JSON`

use parent 'Local::Object';

use DDP;

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

	# получение id друзей для каждого из пользователей
	my $from_fr = _get_friends($self, $from);
	my $to_fr = _get_friends($self, $to);

	my %from_fr = map { $_[0] => 0 } @$from_fr; 	# перевод первого массива в хэш
	my @combined = grep { exists $from_fr{$_[0]} } @$to_fr;	# слияние массивов
	my @rez = map { $_->[0] } @combined;			# разворот ссылочности полученного массива

	my $select = "SELECT ID, first_name, last_name FROM user WHERE ID IN (".(join ",", @rez).")";
	my $json = $self->{dbh}->selectall_arrayref($select, { Slice => {} });
	return JSON::XS::encode_json($json);
}

#  * Список пользователей, у которых нет друзей
sub nofriends {
    my ($self) = @_;
    my $select = qq(
    	SELECT ID, first_name, last_name 
    		FROM user 
    		WHERE friend_count == 0
    );
	my $json = $self->{dbh}->selectall_arrayref($select, { Slice => {} });
	return JSON::XS::encode_json($json);
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

# получение id всех друзей для конкретного пользователя
sub _get_friends {
	my ($self, $id) = @_;
	my $select = "SELECT friend_id FROM user_relation WHERE user_id == $id";
	my $friends = $self->{dbh}->selectall_arrayref($select);
	$select = "SELECT user_id FROM user_relation WHERE friend_id == $id";
	$friends = \(@{ $friends }, @{ $self->{dbh}->selectall_arrayref($select) });
	return $friends;
}

1;
