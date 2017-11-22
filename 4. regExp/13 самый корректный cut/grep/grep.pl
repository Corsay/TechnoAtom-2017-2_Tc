#!/usr/bin/env perl

use 5.016;
use warnings;
use locale;
use utf8;
use open qw(:utf8 :std);
use Encode qw(decode_utf8);
use Getopt::Long;

# -ru = -r -u
# --ru = -ru 
Getopt::Long::Configure("bundling");

# Получаем ключи и параметры
my $pattern = ""; # пустой паттерн(или точные данные для поиска)
my $param_A = ''; # по-умолчанию 0
my $param_B = ''; # по-умолчанию 0
my $param_C = ''; # по-умолчанию 0
my $flag_c = ''; # false
my $flag_i = ''; # false
my $flag_v = ''; # false
my $flag_F = ''; # false
my $flag_n = ''; # false
GetOptions (
	'A=i' => \$param_A,	# -A - after - печатать +N строк после совпадения (один параметр - число)
	'B=i' => \$param_B,	# -B - before - печатать +N до совпадения	(один параметр - число)
	'C=i' => \$param_C,	# -C - context - печатать +N строк до и после совпадения (опции -A и -B) (один параметр - число)
	'c' => \$flag_c,	# -c - count - количество строк (без параметра)
	'i' => \$flag_i,	# -i - ignore-case - игнорировать регистр (без параметра)
	'v' => \$flag_v,	# -v - invert - вместо совпадения исключать	(без параметра)
	'F' => \$flag_F,	# -F - fixed - точное совпадение со строкой, не паттерн (Like) (без параметра)
	'n' => \$flag_n,	# -n - line num - печатать номер строки (без параметра)
);
# получаем из ARGV шаблон (самый первый, остальное отбрасываем, grep пытается открыть как файл)
$pattern = decode_utf8($ARGV[0]);
die "Ожидается наличие шаблона" unless ($pattern);

# Проверяем корректность числовых параметров
if ($param_C ne '') { die "$param_C: Неверный аргумент длины контекста" if ($param_C < 0); }
if ($param_B ne '') { die "$param_B: Неверный аргумент длины контекста" if ($param_B < 0); }
if ($param_A ne '') { die "$param_A: Неверный аргумент длины контекста" if ($param_A < 0); }

# обрабатываем опции -A -B (выше приоритет) если установлена опция -С (ниже приоритет)
if ($param_C ne '') {
	$param_A = $param_C if ($param_A eq '');
	$param_B = $param_C if ($param_B eq '');
}

# если установлен флаг -c игнорируем -A -B
if ($flag_c) {
	$param_A = '';
	$param_B = '';
}

# обрабатываем опции -F -i -v 
# функция выделения найденного по умолчанию по паттерну # 0 - str 1 - pattern
my $paint_sub = sub { GetColoredPatternStr($_[0], $_[1]); };
# функция сравнения по умолчанию по паттерну # 0 - str 1 - pattern (возвращает 1 - соответствует, -1 - не соответствует)
my $check_sub = sub { $_[0] =~ /$_[1]/ ? return 1 : return -1; };
my $check_sub_F = sub { return index($_[0], $_[1]); };
if ($flag_F) {
	# то ищем через вхождение подстроки в строку # 0 - str 1 - substr
	$check_sub = sub { return index($_[0], $_[1]); };
	# функция выделения найденного по точному совпадению # 0 - str 1 - substr 2 - check_sub
	$paint_sub = sub { GetColoredSubstrStr($_[0], $_[1], $_[2]); };
	# если установлены опции -v отрицание -i игнорировать регистр
	if ($flag_v and $flag_i) {
		$check_sub = sub { index(fc($_[0]), fc($_[1])) == -1 ? return 1 : return -1; };
		$check_sub_F = sub { return index(fc($_[0]), fc($_[1])); };
	}
	elsif ($flag_v) {
		# если вхождение не найдено, то вернем истину, иначе ложь
		$check_sub = sub { index($_[0], $_[1]) == -1 ? return 1 : return -1; };
	}
	elsif ($flag_i) {
		$check_sub = sub { return index(fc($_[0]), fc($_[1])); };
		$check_sub_F = sub { return index(fc($_[0]), fc($_[1])); };
	}
}
else {
	# ищем через паттерн
	# если установлена опция -i игнорировать регистр
	if ($flag_i) { $pattern = qr/$pattern/i; }
	else { $pattern = qr/$pattern/;	}
	# если установлена опция -v исключать, то проверяем на не совпадение паттерну
	if ($flag_v) {	# 0 - str 1 - pattern
		$check_sub = sub { $_[0] !~ /$_[1]/ ? return 1 : return -1;	};
	}
}

# перебираем строки и находим соответствующие паттерну
my @outA;			# для опций -AB
my $countA = 0;	
my $needOutA = 0;
my @outB; 
my $outDelim = 0;	# выводить ли -- 
my $inAB = 0;		# полезно при пересечении -- от А и вывода В
my $first = 1;		
my $linenum = 1;	# к опции -n
my $linecount = 0;	# к опции -c
while (<STDIN>) {
	chomp;
	my $elem = $_;
	if ($check_sub->($elem, $pattern) != -1) {
		# если установлена опция -с не выводим текстовую информацию
		unless ($flag_c) {
			# Вывод согласно опции -ABC
			if ($param_A ne '' or $param_B ne '') {
				foreach my $val (@outA) { print "$val\n"; }
				if ($outDelim and not $first) { print "\x1b[36m--\x1b[0m\n"; }
				foreach my $val (@outB) { print "$val\n"; }
				# очищаем массивы и флаги опций -ABC
				@outA = ();
				$countA = 0;
				$needOutA = 1;
				@outB = ();
				$outDelim = 0;
			}
			# если установлена опция -n выводим с номером строки
			if ($flag_n) { print "\x1b[32m$linenum\x1b[36m:\x1b[0m"; }
			# если не установлена опция -v выводим с выделением искомого, иначе просто выводим и не тратим сил
			# Третий параметр для работы с опцией -F
			unless ($flag_v) { print $paint_sub->($elem, $pattern, $check_sub_F);	}
			else { print "$elem"; }
			print "\n";
			$first = 0; # первое значение выведено
		}
		# количество совпадений
		else { $linecount++; }
	}
	else {
		# Если применен флаг -v проверяем переданный параметр на наличие искомого в нём
		# Третий параметр для работы с опцией -F
		if ($flag_v) { $elem = $paint_sub->($elem, $pattern, $check_sub_F); }
		# если установлена опция -n выводим с номером строки
		if ($flag_n) { $elem = "\x1b[32m$linenum\x1b[36m-\x1b[0m" . $elem; }
		if ($needOutA) {
			# работаем с выводом для -A (постконтекст)
			if ($param_A ne '') {
				if ($countA < $param_A) {
					print "$elem\n";
					$countA++;
				}
				else {
					$outDelim = 1;
					$needOutA = 0;
					$inAB = $elem; 	# говорим что А хочет вывести -- дойдя до элемента $elem, который может войти в -B
				}
			}
			else { $needOutA = 0; }
		}
		unless ($needOutA) {
			if ($inAB eq $elem) { $outDelim = 0; $inAB = 0; }
			# работаем с выводом для -B (преконтекст)
			if ($param_B ne '') {
				if (@outB < $param_B) { push @outB, $elem; }
				else {
					$outDelim = 1; # говорим что нам нужен разделитель
					if ($param_B > 0) {
						shift @outB;
						push @outB, $elem;
					}
				}
			}
		}	
	}
	# номер текущей строки
	$linenum++;
}
if ($flag_c) { say $linecount; }

# функция используемая при опции -P (по-умолчанию) (рекурсивная)
# функция принимающая на вход: строку, паттерн по которому отмечать цветом нахождение
# на выход отдает обработанную(окрашенную) строку
sub GetColoredPatternStr {
	# принимаем параметры
	my $str = shift;
	my $pattern = shift;

	# обрабатываем
	my $rezult = '';
	my @rezult = $str =~ /(.*)($pattern)(.*)/;

	if ($rezult[0] =~ /(.*)($pattern)(.*)/) { $rezult .= GetColoredPatternStr($rezult[0], $pattern); }
	else { $rezult .= $rezult[0]; }	# если строка не содержит паттерн, она может содержать стрроку без паттерна или пустоту
	if (defined $rezult[1]) { $rezult .= "\x1b[1;31m$rezult[1]\x1b[0m"; }	# либо найденная согласно паттерну строка, либо Undef
	$rezult .= $rezult[2];	# в любом случае либо пустая строка либо текст без вхождения

	# возвращаем значение
	return $rezult;
}

# функция используемая при опции -F (рекурсивная)
# функция принимающая на вход: строку, подстроку которую отмечать цветом и функцию проверки вхождения подстроки
# на выход отдает обработанную(окрашенную) строку
sub GetColoredSubstrStr {
	# принимаем параметры
	my $str = shift;
	my $substring = shift;
	my $check_sub = shift;
	my $subslen = length($substring);

	# обрабатываем
	my $rezult = '';
 
	my $index = $check_sub->($str,$substring);
	if ($index != -1) {
		# забираем то что до искомой строки
		if ($index > 0) { $rezult .= substr($str, 0, $index); }
		# забираем саму найденную информацию
		$rezult .= "\x1b[1;31m" . substr($str, $index, $subslen) . "\x1b[0m";
		if ($index+$subslen < length($str)) { $rezult .= GetColoredSubstrStr(substr($str, $index+$subslen), $substring, $check_sub); }
	}
	else {
		if ($str ne '') {
			$rezult .= $str;
		}
	}

	# возвращаем значение
	return $rezult;
}