#!/usr/bin/env perl

use 5.016;
use warnings;
use locale;
use Getopt::Long;

# -ru = -r -u
# --ru = -ru 
use DDP;
Getopt::Long::Configure("bundling");

# Получаем ключи и параметры
my $param_k = 0; # по-умолчанию 0 (нумирация колонок с 1-го)
my $flag_n = ''; # false
my $flag_r = ''; # false
my $flag_u = ''; # false
my $flag_M = ''; # false
my $flag_b = ''; # false
my $flag_c = ''; # false
my $flag_h = ''; # false
GetOptions (
	'k=i' => \$param_k,	# сортировать по указанной колонке
	'n' => \$flag_n,	# сортировать по числовому значению
	'r' => \$flag_r,	# сортировать в обратном порядке
	'u' => \$flag_u,	# не выводить повторяющиеся строки
	'M' => \$flag_M,	# сортировать по названию месяца
	'b' => \$flag_b,	# игнорировать хвостовые пробелы
	'c' => \$flag_c,	# проверять отсортированны ли данные
	'h' => \$flag_h,	# сортировать по числовому значению с учётом суффиксов
);

# проверяем введенный номер колонки
if ($param_k) {	
	if ($param_k < 1) {
		die "Invalid column number '$param_k'";
	}
}
# Проверяем совместимость ключей
die "Key -M incompatible with keys -n -h" if ($flag_M and ($flag_n or $flag_h));
die "Key -h and -n incompatible"if ($flag_n and $flag_h);

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

# определяем тип сортировки (ключи h M r n)
my $sorttype = sub {return $_[0] cmp $_[1]}; # {$a cmp $b}; # по-умолчанию сортируем строки по возрастанию
if ($flag_h and $flag_r) {
	# сортировать по числовому значению с учётом суффиксов инверсная
	$sorttype = sub {return sufsort($_[1], $_[0])}; # {$b <=> $a};
}
elsif ($flag_h) {
	# сортировать по числовому значению с учётом суффиксов
	$sorttype = sub {return sufsort($_[0], $_[1])}; # {$a <=> $b};
}
elsif ($flag_M and $flag_r) {
	# сортировка по месяцам в инверсном порядке DEC < JAN (если не входит в месяца, кладем ниже -1)
	$sorttype = sub {return monthssort($_[1], $_[0])}; # {$b cmp $a};
}
elsif ($flag_M) {
	# сортировка по месяцам в прямом порядке JAN < DEC (если не входит в месяца, кладем выше 1)
	$sorttype = sub {return monthssort($_[0], $_[1])}; # {$a cmp $b};
}
elsif ($flag_n and $flag_r) {
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

# если запрощены только уникальные строки (ключ -u)
if ($flag_u) {
	my %uniq;
	@line = grep { !$uniq{$_}++ } @line;
}

# если запрошена проверка (ключ c)
if ($flag_c) {
	# проверяем
	for my $i (0..$#line-1) {
		my $rez = sortfunc($param_k, $flag_b, $sorttype, $line[$i], $line[$i+1]);
		if ($rez > 0) {
			die "Wrong order: $line[$i+1]";
		}
	}
}
else {
	# иначе сортируем (ключи - k b)
	my @sortedLine = sort {sortfunc($param_k, $flag_b, $sorttype, $a, $b)} @line;

	# вывод отсортированного массива
	for my $line (@sortedLine) {
		say $line;
	}
}


# функция сортировки
# принимает на вход: номер колонки(от 0), флаг b, тип сортировки(функция), 
# сравниваемые операнды(строки числа)
sub sortfunc {
	my ($param_k, $flag_b, $type, $a, $b) = @_;

	# если нужно сортировать по колонке помещаем в $a $b только содержимое колонки (ключ -k)
	if ($param_k) {
		$param_k--;
		# разделяем строки на слова(колонки) по разделителю " "
		my @a = split " ", $a;
		my @b = split " ", $b;
		# если колонка есть в строке то содержимое колонки, иначе пустую строку
		$a = defined $a[$param_k] ? $a[$param_k] : "";
		$b = defined $b[$param_k] ? $b[$param_k] : "";
	}

	# если запрошено отрезаем хвостовые пробелы (ключ -b)
	if ($flag_b) {
		$/ = " ";
		while (chomp($a)) {};
		while (chomp($b)) {};
	}

	# возвращаем результат сравнения $a и $b (в которых уже лежит нужная нам колонка)
	return $type->($a, $b);
}


# Функция сортировки по месяцам
# Принимает на вход: операнды для сравнения(строки)
sub monthssort {
	my ($a, $b) = @_;

	# Хеш месяцев (с их весами)
	my %months = qw(JAN 0 FEB 1 MAR 2 APR 3 MAY 4 JUN 5 JUL 6 AUG 7 SEP 8 OCT 9 NOV 10 DEC 11);

	# избавимся от пробелов в начале
	$a = join " ", split " ", $a;
	$b = join " ", split " ", $b;

	# возьмем первые три символа у слов
	my $monA = uc(substr($a,0,3));
	my $monB = uc(substr($b,0,3));
	# если оба слова есть в хеше месяцев
	if (exists $months{$monA} and exists $months{$monB}) {
		# то сравним их числовые эквиваленты и вернем результат
		return $months{$monA} <=> $months{$monB};
	}
	elsif (exists $months{$monA}) {
		return -1;
	}
	elsif (exists $months{$monB}) {
		return 1;
	}
	# в остальных случаях просто сравниваем
	return $a cmp $b;
}


# Функция сортировки по числам с суффиксом
# Принимает на вход: операнды для сравнения(числа и числа с суффиксом)
sub sufsort {
	my ($a, $b) = @_;

	# избавимся от пробелов в начале
	$a = join " ", split " ", $a;
	$b = join " ", split " ", $b;

	# разбиваем полученную строку на число, суффикс и остаток
	my @a = split //, $a;
	my @b = split //, $b;

	# собираем числа суффикс и остаток
	# 0 - число 1 - вес суффикс 2 - остаток
	@a = getDigSufOst(@a);
	@b = getDigSufOst(@b);	

	# "умная сортировка (по весу суффикса по числу и по остатку(строковое сравнение))
	return ($a[1] <=> $b[1] || $a[0] <=> $b[0] || $a[2] cmp $b[2]);
}

# функция получения числа суффикса и остатка 
# получает на массив символов
sub getDigSufOst {
	my (@letters) = @_;

	# хеш суффиксов (с их весами) (-1 для обычного числа)
	my %suf =  qw(K 0 M 1 G 2 T 3 P 4 E 5 Z 6 Y 7);

	my $digit = 0;
	my $sufdig = -2;
	my $ostdig = "";
	my $f_point = 0;
	foreach my $val (@letters) {
		# проверяем что у нас число (учитывая считали мы суффикс или нет!)
		# ord(0) = 48  ord(9) = 57 ord(".") = 46  ord(",") = 44
		my $ord = ord($val);
		if ($sufdig == -2 and ($ord < 58 and $ord > 47 or $ord == 44 or $ord == 46)) {
			# если цифра
			if ($ord != 44 and $ord != 46) {
				if ($f_point) {
					# если дробная часть (приписываем к ней цифру)
					$digit .= $val;
				}
				else {
					# если целая часть
					$digit = $digit * 10 + $val;
				}
			}
			else {
				if ($f_point) {
					# если точка(или запятая) уже есть, то добавляем этот символ в остаток 
					# и говорим что число без суффикса
					$ostdig .= $val;
					$sufdig = -1;
				}
				else {
					# Иначе добавляем точку к числу(временно переведем его в строку) и ставим флаг
					$digit .= ".";
					$f_point = 1; 
				}
			}

		}
		elsif ($sufdig == -2) {
			# если не числовой символ встречается в первый раз, проверяем на существование его в хеше
			if (exists $suf{$val} and $digit != 0) {
				# если есть (и наше число не 0) записываем вес суффикса
				$sufdig = $suf{$val};
			}
			else {
				# иначе сохраняем символ в остаток а число считаем без суффикса
				$ostdig .= $val;
				$sufdig = -1;
			}
		}
		else {
			# забираем остальные символы
			$ostdig .= $val;
		}
	}
	$sufdig = -1 if ($sufdig == -2);

	return ($digit, $sufdig, $ostdig);
}