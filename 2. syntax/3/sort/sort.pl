#!/usr/bin/env perl

use 5.016;
use warnings;

use DDP;
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

# отступ (Для удобства при вводе через <STDIN>)
say "";

# еcли массив пустой (допустим пользователь передал пустой файл или не передал вовсе введя вручную сtrl+D ) 
die "Nothing to sort" unless @line; 

# Определяем сортируемый столбец (по-умолчанию 0 - по всей строке)

# определяем тип сортировки
my $sorttype = sub {return $_[1] cmp $_[0]}; # {$b cmp $a};

# функция сортировки
my $sortf    = sub {
	my ($type, @line) = @_;
	return sort {$type->($a, $b)} @line;
};

# Определяем функцию сортировки
my $sortfunc = sub {
		my ($column, @line) = @_;
		return sort {$a cmp $b} @line;
	};	# по-умолчанию сортируем строки по возрастанию
if ($flag_n and $flag_r) {
	$sortfunc = sub {
		no warnings; 
		my ($column, @line) = @_;
		return sort {$b <=> $a} @line;
	}	# сортируем числа по убыванию
}
elsif ($flag_n) {
	$sortfunc = sub {
		no warnings; 
		my ($column, @line) = @_;
		return sort {$a <=> $b} @line;
	}	# сортируем числа по возрастанию
}
elsif ($flag_r) {
	$sortfunc = sub {
		my ($column, @line) = @_;
		return sort {$b cmp $a} @line;
	}	# сортируем строки по убыванию
}

# если запрощены только уникальные строки
if ($flag_u) {
	my %uniq;
	@line = grep { !$uniq{$_}++ } @line;
}

# сортируем
my @sortedLine = $sortf->($sorttype,@line);#$sortfunc->($param_k, @line);

# вывод отсортированного массива
for my $line (@sortedLine) {
	say $line;
}

# функция обрезает часть строки
# принимает на вход строку и сколько слов от начала обрезать
sub cutpart {
	my $str = shift;
	my $cuts = shift;

	# заменить все многопробельные части строки на одиночные пробелы:
	while (index($str, "  ") != -1) {
		substr($str, index($str, "  "), 2) = " ";
	}

	# вырезаем
	while ($cuts--) {
		$str = index($str," ");
	}

	# возвращаем отрез
	return $str;
}