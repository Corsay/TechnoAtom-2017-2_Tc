#!/usr/bin/env perl

use 5.016;
use warnings;

# пример 1 1 2 3 5 8 13 21 34 55
# входные данные от 1
# 1477, 1478 - Inf, 1479... - NaN

# Проверяем наличие и количество аргументов
die "Bad arguments: Need one argument" if not @ARGV;
warn "Warning: Too much arguments" if @ARGV > 1;

# принятый параметр
my ($N) = @ARGV;

# проверяем что N - натуральное число (допустим что пользователь может написать знак + перед числом)
die "Bad arguments: Argument is not a natural number" if $N !~ /^[+]?\d+$/;
die "Bad arguments: Argument is not a natural number" if not $N;

say Fib($N);

sub Fib {
	my $N = shift;
	# F(n-1)
	my $fibx = 0;
	# F(n)
	my $fiby = 1;
	for (my $i = 0; $i < $N; $i++) {
		$fibx = $fibx + $fiby;
		$fiby = $fibx - $fiby;
	}
	return $fibx;
}