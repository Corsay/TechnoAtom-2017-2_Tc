#!/usr/bin/env perl

use 5.016;
use warnings;

# Проверяем наличие и количество аргументов
die "Bad arguments: Need one argument" if not @ARGV;
warn "Bad arguments: Too much arguments" if @ARGV > 1;

# принятый параметр
my ($N) = @ARGV;

# проверяем что N - натуральное число (допустим что пользователь может написать знак + перед числом)
die "Bad arguments: Argument is not a natural number" if $N !~ /^[+]?\d+$/;

say Fact($N);

sub Fact {
	my $N = shift;
	if ($N < 2) {
		return 1;
	}
	else {
		return $N * Fact($N - 1);
	}
}