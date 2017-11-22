#!/usr/bin/env perl

use 5.016;
use warnings;
use Getopt::Long;

# -ru = -r -u
# --ru = -ru 
Getopt::Long::Configure("bundling");

# Получаем ключи и параметры
my $param_k = 0; # по-умолчанию 0 (нумирация колонок с 1-го)
my $flag_n = ''; # false
my $flag_r = ''; # false
my $flag_u = ''; # false
GetOptions (
	'k=i' => \$param_k,	# сортировать по указанной колонке
	'n' => \$flag_n,	# сортировать по числовому значению
	'r' => \$flag_r,	# сортировать в обратном порядке
	'u' => \$flag_u,	# не выводить повторяющиеся строки
);

# проверяем введенный номер колонки
if ($param_k) {	
	if ($param_k < 1) {
		die "Invalid column number '$param_k'";
	}
}

# читаем стандартный ввод
my @line;	# в @line будем иметь строки сортируемого текста
my $i = 0;
while (<STDIN>) {
	chomp;	# отсекаем \n
	@line[$i++] = $_;
}

# отступ (Для удобства просмотра результата при вводе через <STDIN>)
say "";

# еcли массив пустой (допустим пользователь передал пустой файл или не передал вовсе введя вручную сtrl+D ) 
die "Nothing to sort" unless @line; 

# определяем тип сортировки (ключи r n)
my $sorttype = sub {return $_[0] cmp $_[1]}; # {$a cmp $b}; # по-умолчанию сортируем строки по возрастанию
if ($flag_n and $flag_r) {
	$sorttype = sub {
		no warnings; 
		return $_[1] <=> $_[0]
	}; # {$b <=> $a}; # сортируем числа по убыванию
}
elsif ($flag_n) {
	$sorttype = sub {
		no warnings; 
		return $_[0] <=> $_[1]
	}; # {$a <=> $b}; # сортируем числа по возрастанию	
}
elsif ($flag_r) {
	$sorttype = sub {return $_[1] cmp $_[0]}; # {$b cmp $a}; # сортируем строки по убыванию
}

# функция сортировки (ключи - k)
my $sortf = sub {
	my ($param_k, $type, @line) = @_;
	if ($param_k) {
		# если передали номер колонки то сортируем по этой колонке
		# если в какой-то строке не будет данной колонки, считаем что колонка является пустой
		return sort {sortfuncK($param_k-1, $type, $a, $b)} @line;
	}
	else {
		# иначе просто сортируем
		return sort {$type->($a, $b)} @line;
	}
};

# если запрощены только уникальные строки (ключ -u)
if ($flag_u) {
	my %uniq;
	@line = grep { !$uniq{$_}++ } @line;
}

# сортируем
my @sortedLine = $sortf->($param_k, $sorttype, @line);

# вывод отсортированного массива
for my $line (@sortedLine) {
	say $line;
}


# функция сортировки по колонке
# принимает на вход номер колонки(от 0), 
sub sortfuncK {
	my ($param_k, $type, $a, $b) = @_;
	my $str = shift;
	my $cuts = shift;

	# заменить все многопробельные части строки на одиночные пробелы:
	while (index($a, "  ") != -1) {
		substr($a, index($a, "  "), 2) = " ";
	}
	while (index($b, "  ") != -1) {
		substr($b, index($b, "  "), 2) = " ";
	}

	# разделяем строки на слова(колонки) по разделителю " "
	my @a = split / /, $a;
	my @b = split / /, $b;
	# если колонка есть в строке то содержимое колонки, иначе пустую строку
	$a = defined $a[$param_k] ? $a[$param_k] : "";
	$b = defined $b[$param_k] ? $b[$param_k] : "";

	# возвращаем результат сравнения $a и $b (в которых уже лежит нужная нам колонка)
	return $type->($a, $b);
}