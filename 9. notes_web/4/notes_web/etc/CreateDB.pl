#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use DBD::mysql;

# конфиг "для создания" mysql бд
my $driver   = "mysql";
my $dbd = "DBI:$driver:";
my $username = "root";
my $password = "";

# попытка подключения к бд
my $dbh = DBI->connect($dbd, $username, $password, { RaiseError => 1 })
  or die "Can't connect to $driver: ".$DBI::errstr;

=head2
  # заходим в mysql под root
  mysql -u root -p 
  password: 
  # Создание БД
  create database TC_notes charset utf8;
  # Создание пользователя
  create user TC_notes IDENTIFIED BY 'TC_notes';
  # выдача ему всех прав доступа к этой базе
  GRANT ALL ON TC_notes.* to TC_notes;
=cut
eval {
  $dbh->begin_work; # Открытие транзакции

  my ($stmt, $ret);
  # Создание БД
  $stmt = 'create database TC_notes charset utf8;';  $ret = $dbh->do($stmt);
  # Создание пользователя
  $stmt = "create user TC_notes IDENTIFIED BY 'TC_notes';";  $ret = $dbh->do($stmt);
  # выдача ему всех прав доступа к этой базе
  $stmt = 'GRANT ALL ON TC_notes.* to TC_notes;';  $ret = $dbh->do($stmt);

  $dbh->commit;	# Успешное завершение транзакции
};
$dbh->disconnect(); # завершение работы с БД

=head2 
  # для удаления пользователя и БД
  DROP user TC_notes;
  DROP database TC_notes;
=cut
