#!/usr/bin/env perl

use 5.016;
use warnings;

# Если передано не два параметра
if (@ARGV != 2) {
	die "Not enough arguments";
}

# принятые параметры
my ($haystack, $needle) = @ARGV;

# индекс первого вхождения подстроки справа
# или -1 при отсутствии вхождения
my $index = index($haystack, $needle);

# если нет вхождения выводим сообщение
if ($index == -1) {
	warn "Not found";
	exit; 
}

# если есть вхождение то выводим позицию вхождения (от 0)
say $index;
# и выводим остальную часть строки
say substr($haystack, $index)
