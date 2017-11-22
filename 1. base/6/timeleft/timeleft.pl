#!/usr/bin/env perl

use 5.016;
use warnings;

#    0    1    2     3     4    5     6     7     8
# ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
# секунд до конца часа
# секунд до конца дня
# секунд до конца недели

# при передаче аргумента предупреждаем что аргументы не нужны
warn "Arguments not need" if @ARGV;

# текущее время
my @curtime = localtime();

# вычисляем количество секунд до конца часа
# полный час = 60 * 60 = 3600
# прошедшее время = минуты*60 + секунды
my $hour = 3600 - ($curtime[1] * 60 + $curtime[0]);
say "Seconds until hour end = " . $hour;
# вычисляем количество секунд до конца дня
# полныйдень день = 24 * 60 * 60 = 86400
# прошедшее время = часы * 3600 + минуты * 60 + секунды
my $day = 86400 - ($curtime[2] * 3600 + $curtime[1] * 60 + $curtime[0]);
say "Seconds until day end = " . $day;
# вычисляем количество секунд до конца недели
# до конца сегодняшнего дня + оставшиеся дни недели
# или
# дней до конца недели * 86400 - уже прошедшее за сегодня время
my $week = (7 - $curtime[6]) * 86400 - ($curtime[2] * 3600 + $curtime[1] * 60 + $curtime[0]);
say "Seconds until week end = " . $week;
say $day + (6 - $curtime[6]) * 86400;

say "";
my $curtime = localtime();
say $curtime;
say $curtime[6];