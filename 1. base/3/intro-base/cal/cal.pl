#!/usr/bin/env perl

use 5.016;
use warnings;
# perldoc -f time
# perldoc -f localtime
# perldoc -f sprintf
# use Time::Local 'timelocal'; # может помочь в вычислении time для заданного месяца

if (@ARGV == 1) {
	my ($month) = @ARGV;
	# нам передали номер месяца. проверяем параметр и
	# печатаем календарь на этот месяц

	say $month;
}
elsif (not @ARGV) {
	# печатаем календарь на год
}
else {
	# неверное количество аргументов
}
