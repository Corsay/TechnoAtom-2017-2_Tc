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
use DDP;

# head -70 bigdict.txt | perl grep.pl "ре" -nC2

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
# при этом экранируем спецсимволы если не установлена опция -F
if ($flag_F) {
	$pattern = decode_utf8($ARGV[0]);
}
else {
	$pattern = quotemeta(decode_utf8($ARGV[0]));
}
die "Ожидается наличие шаблона" unless ($pattern);

# Проверяем корректность числовых параметров
if ($param_C ne '') { die "$param_C: Неверный аргумент длины контекста" if ($param_C < 0); }
if ($param_B ne '') { die "$param_B: Неверный аргумент длины контекста" if ($param_B < 0); }
if ($param_A ne '') { die "$param_A: Неверный аргумент длины контекста" if ($param_A < 0); }

# читаем стандартный ввод
my @line;
while (<STDIN>) {
	chomp;	# отсекаем \n
	push @line, $_;
}

# еcли массив пустой (допустим пользователь передал пустой файл или не передал вовсе введя вручную сtrl+D ) 
die "Нечего фильтровать" unless @line; 

# обрабатываем опции -A -B (выше приоритет) если установлена опция -С (ниже приоритет)
if ($param_C ne '') {
	$param_A = $param_C if ($param_A eq '');
	$param_B = $param_C if ($param_B eq '');
}

# если установлен флаг -c игнорируем -A -B
if ($flag_c) {
	$param_A = 0;
	$param_B = 0;
}

# обрабатываем опции -F -i -v 
my $check_sub;
if ($flag_F) {
	# то ищем через вхождение подстроки в строку
	$check_sub = sub {
		return;
	};
	# если установлены опции -v отрицание -i игнорировать регистр
	if ($flag_v and $flag_i) {
		say;
	}
	elsif ($flag_v) {
		say;
	}
	elsif ($flag_i) {
		say;
	}
}
else {
	# ищем через паттерн
	# если установлена опция -i игнорировать регистр
	if ($flag_i) {
		$pattern = qr/$pattern/i;
	}
	else {
		$pattern = qr/$pattern/;
	}

	# если установлена опция -v исключать
	$check_sub = sub {
			@{$_[2]} = $_[0] =~ /(.*)($_[1])(.*)/g;	# 0 - $_ 1 - pattern 2 - куда поместить результат
			return $_[0] =~ /.*$_[1].*/;
		};
	if ($flag_v) {
		$check_sub = sub {
			@{$_[2]} = $_[0] !~ /(.*)($_[1])(.*)/g;	# 0 - $_ 1 - pattern 2 - куда поместить результат
			return $_[0] !~ /.*$_[1].*/;
		};
	}
}

# перебираем строки и находим соответствующие паттерну
my @outA;
my $countA = 0;	
my $needOutA = 0;
my @outB; 
my $outDelim = 0;	# выводить ли -- для опций -B
my $first = 1;		# для опция -A -B
my $linenum = 1;	# к опции -n
my $linecount = 0;	# к опции -c
foreach (@line) {
	my @elem;
	if ($check_sub->($_, $pattern, \@elem)) {
		# если установлена опция -с не выводим текстовую информацию
		unless ($flag_c) {
			# Вывод согласно опции -ABC
				foreach my $val (@outA) { print "$val\n"; }
				if (($outDelim or $outDelim) and not $first) { print "\x1b[36m--\x1b[0m\n"; }
				foreach my $val (@outB) { print "$val\n"; }
				# очищаем массивы и флаги
				@outA = ();
				$needOutA = 1; # ожидаем вывода N строк после
				$countA = 0;
				@outB = ();
				$outDelim = 0;
			# если установлена опция -n выводим с номером строки
			if ($flag_n) {
				print "\x1b[32m$linenum\x1b[36m:\x1b[0m";
			}
			# если не установлена опция -v выделяем найденное
			unless ($flag_v) {
				print "$elem[0]";
				print "\x1b[1;31m$elem[1]\x1b[0m";
				print "$elem[2]";
			}
			else {
				print "$_";
			}
			print "\n";
			$first = 0; # первое значение выведено
		}
		else {
			# количество совпадений
			$linecount++;
		}
	}
	else {
		# Если применен флаг -v проверяем переданный параметр на наличие искомого слова в нём
		if ($flag_v) {
			# подумать, выходит страшно, надо использовать обратную функцию, перейти на функциональное программирование
		}
		# если установлена опция -n выводим с номером строки
		if ($flag_n) {
			$_ = "\x1b[32m$linenum\x1b[36m-\x1b[0m" . $_;
		}
		if ($needOutA) {
			# работаем с выводом для -A (постконтекст)
			if ($param_A ne '') {
				if ($countA < $param_A) {
					print "$_\n";
					$countA++;
				}
				else {
					$outDelim = 1;
					$needOutA = 0;
				} 
			}
			else { $needOutA = 0; }
		}
		else {
			# работаем с выводом для -B (преконтекст)
			if ($param_B ne '') {
				if (@outB < $param_B) {
					push @outB, $_;
				}
				else {
					$outDelim = 1; # говорим что нам нужен разделитель
					if ($param_B > 0) {
						shift @outB;
						push @outB, $_;
					}
				}
			}
		}	
	}
	# номер текущей строки
	$linenum++;
}

if ($flag_c) {
	say $linecount;
}