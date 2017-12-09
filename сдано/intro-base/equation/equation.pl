#!/usr/bin/env perl

use 5.016;
use warnings;

# если нам передали некорректное количество параметров
if (not @ARGV or @ARGV > 3) {
	die "Bad arguments";
}

# принятые параметры
my ($a, $b, $c) = @ARGV;

# Если не ввели 2 и 3 параметр считать их равными 0
# if (not ...) = unless
unless (defined $b) {
	$b = 0;
}
unless (defined $c) {
	$c = 0;
}

# Проверка на то что ввели числа
unless ($a =~ /^[+-]?\d+$/ and $b =~ /^[+-]?\d+$/ and $c =~ /^[+-]?\d+$/) {
	die "Bad arguments";
}

# если уравнение не квадратное
if ($a == 0) {
	die "Not a quadratic equation";
}

# D = b^2 - 4 * a * c
# D - дескриминант
# D < 0 - нет корней в области действительных чисел
# D = 0 - один корень X = -b / (2 * a)
# D > 0 - два корня X = (-b +- sqrt(D)) / (2 * a)
my $D = $b * $b - 4 * $a * $c;

if ($D < 0) {
	# нет корней в области действительных чисел
	say "There are no solution in the valid number domain";
}
elsif ($D == 0) {
	# один корень
	my $X = -$b / (2 * $a);
	say $X;
}
else {
	# два корня
	$D = sqrt($D);
	my $X1 = -$b + $D / (2 * $a);
	my $X2 = -$b - $D / (2 * $a);
	say $X1 . ", " . $X2;
}