#!/usr/bin/env perl

use 5.016;
use warnings;

# 2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97 101 103 107 109 113

# Проверяем наличие и количество аргументов
die "Bad arguments: Need one argument" if not @ARGV;
warn "Warning: Too much arguments" if @ARGV > 1;

# принятый параметр
my ($N) = @ARGV;

# проверяем что N - натуральное число (допустим что пользователь может написать знак + перед числом)
die "Bad arguments: Argument is not a natural number" if $N !~ /^[+]?\d+$/;
die "Bad arguments: Argument is not a natural number" if not $N;

say Prime($N);

sub Prime {
	my $N = shift;
	# сюда будем помещать найденные числа
	my $rezult = "";
	# Добавим двойку 
	$rezult = "2" if $N >= 2;
	# += 2 т.к только 2-ка из четных чисел является простой
	for (my $i = 3; $i <= $N; $i += 2) {
		# флаг проверки на простоту текущего числа $i
		my $primeFlag = 1;
		# цикл проверки делителей текущего числа $i (с ускорением)
		for (my $j = 3; $j**2 <= $i; $j += 2) {
			# Если попался хоть один делитель
			if ($i != $j and $i % $j == 0) {
				$primeFlag = 0;
				last;
			}
		}
		$rezult = $rezult . " " . $i if $primeFlag;
	}
	# вывод результата
	return $rezult;
}