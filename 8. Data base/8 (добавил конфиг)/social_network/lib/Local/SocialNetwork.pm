package Local::SocialNetwork;

use strict;
use warnings;
use experimental 'smartmatch';	# for smartmatch ~~

use DBI;
use DBD::SQLite;
use JSON::XS;		# * Ответ приложения `bin/social_network.pl` должен быть в формате `JSON`
use Config::YAML;

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

	# получаем конфиг
	$self->{config} = Config::YAML->new(config => $data->{config});

	my $driver = $self->{config}{Database}{driver};
	my $db_name = $self->{config}{Database}{dbname};
	my $dbd = "DBI:$driver:dbname=$db_name";
	my $username = $self->{config}{Database}{username};
	my $password = $self->{config}{Database}{password};

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

	my %from_fr = map { $_->[0] => 0 } @$from_fr; 	# перевод первого массива в хэш
	my @combined = grep { exists $from_fr{$_->[0]}; } @{$to_fr};	# слияние массивов
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

	# проверяем что у пользователя есть хотябы один друг
	if (_get_friend_count($self, $to)) {
		my %viewed_users;			# просмотренные пользователи
		my $handshakes = 0;			# количество рукопожатий
		my @search = ($from);		# массив в котором будем хранить список друзей на уровне

		# пока есть хоть один возможный претендент имеющий в друзьях искомого пользователя
		while (@search) {
			#   если id есть в массиве, то вернем количество рукопожатий
			if ($to ~~ @search) {
				return JSON::XS::encode_json([{num_handshakes => $handshakes}]);
			}
			# если не нашли забираем всех друзей текущих пользователей в новый список
			my @search_tmp = @{ _get_friends($self, @search) };
			@search = ();	# обнуляем массив
			# перезаполняем массив теми пользователями которых еще не проверили
			foreach (@search_tmp) {
				$_ = $_->[0];
				unless (exists $viewed_users{$_}) {
					$viewed_users{$_} = 1;
					push @search, $_;
				}
			}
			# инкремент количества рукопожатий
			$handshakes++;
		}
	}
	# если совсем нет друзей
	return JSON::XS::encode_json([{num_handshakes => -1}]);
}

# получение количества друзей у выбранного пользователя
sub _get_friend_count {
	my ($self, $id) = @_;
	my $select = "SELECT friend_count FROM user WHERE ID == $id";
	my $friends_count = $self->{dbh}->selectall_arrayref($select);
	return $friends_count->[0]->[0];
}

# получение id всех друзей для конкретного пользователя
sub _get_friends {
	my ($self, @id) = @_;
	my @friends; my $friend;
	my %get = (0 => 'friend_id', 1 => 'user_id');
	for my $i (0..1) { # формируем нужный селект запрос и забираем данные
		my $select = "SELECT ".$get{$i}." FROM user_relation WHERE ".$get{1 - $i}." IN (".(join ",", @id).")";
		$friend = $self->{dbh}->selectall_arrayref($select);
		push @friends, $_ foreach (@$friend);
	}
	return \@friends;
}

1;
