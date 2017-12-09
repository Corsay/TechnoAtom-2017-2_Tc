#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use DBD::mysql;

my $upload_dir = 'note';
# конфиг "для создания" mysql бд
my $driver   = "mysql";
my $dbname = "TCnotes";
my $dbd = "DBI:$driver:";
my $username = "root";
my $password = "";

# попытка подключения к бд
my $dbh = DBI->connect($dbd, $username, $password, { RaiseError => 1 })
  or die "Can't connect to $driver: ".$DBI::errstr;

eval {
  $dbh->begin_work; # Открытие транзакции

  my ($stmt, $ret);
=head2
  # Заходим в mysql под root
  mysql -u root -p
  password:
  # Создание БД
  create database TCnotes charset utf8;
  # Создание пользователя
  create user TCnotes IDENTIFIED BY 'TCnotes';
  # выдача ему всех прав доступа к этой базе
  GRANT ALL ON TCnotes.* to TCnotes;
=cut

  # Создание БД
  $stmt = "create database $dbname charset utf8;";  $ret = $dbh->do($stmt);
  # Создание пользователя
  $stmt = "create user $dbname IDENTIFIED BY '$dbname';";  $ret = $dbh->do($stmt);
  # выдача ему всех прав доступа к этой базе
  $stmt = "GRANT ALL ON $dbname.* to $dbname;";  $ret = $dbh->do($stmt);

  $dbh->commit;	# Успешное завершение транзакции
};
$dbh->disconnect(); # завершение работы с БД

#
# Создание таблиц
#
$dbd = "DBI:$driver:dbname=$dbname";

# попытка подключения к бд
$dbh = DBI->connect($dbd, $username, $password, { RaiseError => 1 })
  or die "Can't connect to $driver: ".$DBI::errstr;

eval {
  $dbh->begin_work; # Открытие транзакции

  my ($stmt, $ret);
=head2
  # Создание таблиц
  # 1. user - пользователь
  login - уникальный никнейм пользователя (строка (50 бит)), Первичный ключ
  pass - пароль пользователя (строка (50 бит)) -> md5 введенного пользователем пароля
  name - имя (для приветсвия) (строка (100 бит))

  # 2. note - заметка
  id - уникальный код записи (64 бит число), Первичный ключ
  owner - логин пользователя, создателя заметки (строка (50 бит)), внешний ключ
  create_time - время создания (время)
  expire_time - время жизни (время) (опционально)
  title - заголовок заметки (строка (255 бит)) (опционально)
  create_time_idx - индекс по времени создания (основной параметр для поиска)
  expire_time_idx - индекс по времени жизни    (для того чтобы вычищать старые заметки)

  # 3. user_note - допуски к заметке
  login - логин допущенного пользователя (строка (50 бит)), (не внешний ключ - доступ дать можно но посмотрят только когда зарегистрируются) (FOREIGN KEY (login) REFERENCES user(login) ON DELETE CASCADE,)
  note_id - id заметки (64 бит число), внешний ключ
  Первичный ключ -> (login, note_id)
=cut

  $stmt = qq(CREATE TABLE user (
    login VARCHAR(50) PRIMARY KEY NOT NULL,
    pass VARCHAR(100) NOT NULL,
    name VARCHAR(100)
  ) charset utf8;);  $ret = $dbh->do($stmt);

  $stmt = qq(CREATE TABLE note (
    id BIGINT PRIMARY KEY NOT NULL,
    owner VARCHAR(50) NOT NULL,
    create_time TIMESTAMP NOT NULL,
    expire_time TIMESTAMP NULL,
    title VARCHAR(255),
    FOREIGN KEY (owner) REFERENCES user(login) ON DELETE CASCADE,
    index create_time_idx (create_time),
    index expire_time_idx (expire_time)
  ) charset utf8;);  $ret = $dbh->do($stmt);

  $stmt = qq(CREATE TABLE user_note (
    login VARCHAR(50) NOT NULL,
    note_id BIGINT NOT NULL,
    FOREIGN KEY (note_id) REFERENCES note(id) ON DELETE CASCADE,
    PRIMARY KEY (login, note_id)
  ) charset utf8;);  $ret = $dbh->do($stmt);

  $dbh->commit; # Успешное завершение транзакции
};
$dbh->disconnect(); # завершение работы с БД

# создаем директорию для заметок
mkdir "$dbname/$upload_dir" unless (-e "$dbname/$upload_dir");
