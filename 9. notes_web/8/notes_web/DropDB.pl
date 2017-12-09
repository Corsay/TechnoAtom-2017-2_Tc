#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use DBD::mysql;

# конфиг "для создания" mysql бд
my $driver   = "mysql";
my $dbname = "TCnotes";
my $dbd = "DBI:$driver:dbname=$dbname";
my $username = "root";
my $password = "";

# попытка подключения к бд
my $dbh = DBI->connect($dbd, $username, $password, { RaiseError => 1 })
  or die "Can't connect to $driver: ".$DBI::errstr;

=head2
  # для удаления пользователя и БД
  DROP user TCnotes;
  DROP database TCnotes;
=cut

eval {
  $dbh->begin_work; # Открытие транзакции

  my ($stmt, $ret);

  # удаление таблиц
  foreach (qw(user_note note user)) {
    $stmt = "DROP TABLE IF EXISTS $_";
    $ret = $dbh->do($stmt);
  }

  # для удаления пользователя и БД
  $stmt = "DROP user $dbname;";  $ret = $dbh->do($stmt);
  $stmt = "DROP database $dbname;";  $ret = $dbh->do($stmt);

  $dbh->commit;	# Успешное завершение транзакции
};
$dbh->disconnect(); # завершение работы с БД
