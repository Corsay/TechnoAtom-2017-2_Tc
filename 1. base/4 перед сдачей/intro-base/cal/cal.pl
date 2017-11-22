#!/usr/bin/env perl

use 5.016;
use warnings;
use Time::Local;
# perldoc -f time
# perldoc -f localtime
# perldoc -f sprintf
# use Time::Local 'timelocal'; # может помочь в вычислении time для заданного месяца

my @time = localtime();	# берем текущий месяц и год

if (@ARGV == 1) {
	my ($month) = @ARGV;

	# проверим что ввели число
	unless ($month =~ /^[+-]?\d+$/) {
		die "Bad arguments";
	}
	
	# проверяем номер месяца (от 1 до 12)
	unless (0 < $month and $month < 13) {
		die "Month is out of range (1..12)";
	}

	# печатаем календарь на выбранный месяц
	printMonth($month-1, $time[5]+1900);
}
elsif (not @ARGV) {
	# печатаем календарь на текущий месяц
	printMonth($time[4], $time[5]+1900);
}
else {
	# неверное количество аргументов
	die "Bad arguments";
}

# Функция вывода календаря на текущий месяц
sub printMonth {
    # получаем переданный месяц и год(текущий)
    my $mon = shift;
    my $year = shift;
 	# заполняем массивы месяцев, дней недели и получаем первый день выбранного месяца
	my @months = qw(January February March April May June July August September October November December);
	my @days = qw(Su Mo Tu We Th Fr Sa);

	# выводим текущий месяц, год и дни недели
	my $msg = $months[$mon] . " " . ($year);
	my $size = 20 - int((20 - length($msg)) / 2);
	$msg = sprintf ('%'.$size.'s', $msg);
	say $msg;	
	say "Su Mo Tu We Th Fr Sa";
	
	# получаем первый день месяца
	# $day[3] - День месяца
	# $day[4] - месяц
	# $day[6] - День недели
	my @day = localtime(timelocal(00, 00, 00, 01, $mon, $year));
	# $last_day[3]-1 - последний день месяца
	my @last_day;
	if ($mon == 11) {
		@last_day = localtime(timelocal(00, 00, 00, 01, 01, $year+1) - 86400);
	}
	else {
		@last_day = localtime(timelocal(00, 00, 00, 01, $mon+1, $year) - 86400);
	}

	my $text = "";
	# добавляем изначальный отступ
	for (my $i = 0; $i < $day[6]; $i++) {
		$text = $text . "   ";
	}
	# пока текущий день($day) не равен последнему в месяце
	my $day = 1;
	while ($day <= $last_day[3]) {
		@day = localtime(timelocal(00, 00, 00, $day, $mon, $year));
		$text = sprintf("%s%2d ", $text, $day[3]);
		if ($day[6] eq "6" or $day+1 > $last_day[3]) {
			say $text;
			$text = "";
		}
		$day++;
	}

	return undef;
}