#!/usr/bin/env perl

use 5.016;
use warnings;

# 171... - Inf

# Проверяем наличие и количество аргументов
die "Bad arguments: Need one argument" if not @ARGV;
warn "Warning: Too much arguments" if @ARGV > 1;

# принятый параметр
my ($N) = @ARGV;

# проверяем что N - натуральное число (допустим что пользователь может написать знак + перед числом)
die "Bad arguments: Argument is not a natural number" if $N !~ /^[+]?\d+$/;
die "Bad arguments: Argument is not a natural number" if not $N;

say Fact($N);

sub Fact {
	my $N = shift;
	my $fact = 1;
	for (my $i = 1; $i <= $N; $i++) {
		$fact *= $i;
	}
	return $fact;
}