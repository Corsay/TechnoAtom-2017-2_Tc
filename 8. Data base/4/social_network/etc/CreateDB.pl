#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use DBD::SQLite;
use Archive::Zip;
use open qw(:utf8 :std);  # для корректной загрузки из файлов (utf8)

use DDP;
use 5.16.0;

# конфиг
my $driver   = "SQLite";
my $db_name = "../bin/users_relation.db";
my $dbd = "DBI:$driver:dbname=$db_name";
my $username = "";  # не ожидает логин и пароль
my $password = "";

# попытка cоздания бд и подключения к ней
my $dbh = DBI->connect($dbd, $username, $password, { RaiseError => 1 })
  or die "can not create/connect to DB: ".$DBI::errstr;
$dbh->begin_work;	# Открытие транзакции

# создание и заполнение таблиц
my ($stmt, $ret, $zip, $sth, $fh);  # запрос, результат, обьект архива, prepare-execute, файл деск
my %counter;  # тут будем держать количество друзей для каждого пользователя
#---------------- USER_RELATION
# удаление таблицы
$stmt = 'DROP TABLE IF EXISTS user_relation';
$ret = $dbh->do($stmt);
die "Can not drop 'USER_RELATION' table: ".$DBI::errstr if($ret < 0);
# создание таблицы
$stmt = qq(CREATE TABLE user_relation (
              user_id	INT,
              friend_id INT
        ));
$ret = $dbh->do($stmt);
die "Can not create 'USER_RELATION' table: ".$DBI::errstr if($ret < 0);
# заполнение таблицы данными из zip архива
$zip = Archive::Zip->new('user_relation.zip');	# открываем архив
$zip->extractMember('user_relation');	# извлекаем файл из архива
# читаем распакованный файл
open ($fh, '<', 'user_relation') or die "can't open file 'user_relation': $!";
$sth = $dbh->prepare(
  "INSERT INTO user_relation (user_id, friend_id) VALUES (?, ?);"
);
while (<$fh>) {
  chomp(); # отрезаем
  $_ =~ /(.*)\s(.*)/;
  $sth->execute($1, $2);  # вносим данные в таблицу 'USER'
  # уведичиваем счётчики количества друзей
  if (exists $counter{$1}) { $counter{$1}++; }
  else { $counter{$1} = 1; }
  if (exists $counter{$2}) { $counter{$2}++; }
  else { $counter{$2} = 1; }
}
close($fh);
# удаляем распакованный файл
unlink('user_relation');


#---------------- USER
# удаление таблицы
$stmt = 'DROP TABLE IF EXISTS user';
$ret = $dbh->do($stmt);
die "Can not drop 'USER' table: ".$DBI::errstr if($ret < 0);
# создание таблицы
$stmt = qq(CREATE TABLE user (
              ID      int PRIMARY KEY,
              first_name  varchar NOT NULL,
              last_name   varchar NOT NULL,
              friend_count  int  NOT NULL
        ));
$ret = $dbh->do($stmt);
die "Can not create 'USER' table: ".$DBI::errstr if($ret < 0);
# заполнение таблицы данными из zip архива
$zip = Archive::Zip->new('user.zip'); # открываем архив
$zip->extractMember('user');  # извлекаем файл из архива
# читаем распакованный файл
open ($fh, '<', 'user') or die "can't open file 'user': $!";
$sth = $dbh->prepare(
  "INSERT INTO user (id, first_name, last_name, friend_count) VALUES (?, ?, ?, ?);"
);
while (<$fh>) {
  chomp(); # отрезаем
  $_ =~ /(.*)\s(.*)\s(.*)/;
  # если нет записи о количестве друзей для текущего пользователя, то считаем что их 0
  my $count = $counter{$1} // 0;
  $sth->execute($1, $2, $3, $count);  # вносим данные в таблицу 'USER'
}
close($fh);
# удаляем распакованный файл
unlink('user');


$dbh->commit;	# Успешное завершение транзакции
# завершение работы с БД
$dbh->disconnect();
