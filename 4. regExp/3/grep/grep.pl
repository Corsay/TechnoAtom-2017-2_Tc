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

# Получаем ключи и параметры

my $pattern = ""; # пустой паттерн(или точные данные для поиска)
my $param_A = 0; # по-умолчанию 0
my $param_B = 0; # по-умолчанию 0
my $param_C = 0; # по-умолчанию 0
my $flag_c = ''; # false
my $flag_i = ''; # false
my $flag_v = ''; # false
my $flag_F = ''; # false
my $flag_n = ''; # false
GetOptions (
	'A=i' => \$param_A,	# -A - after - печатать +N строк после совпадения (один параметр - число)
	'B=i' => \$param_B,	# -B - before - печатать +N до после совпадения	(один параметр - число)
	'C=i' => \$param_C,	# -C - context - печатать +N строк до и после совпадения (опции -A и -B) (один параметр - число)
	'c' => \$flag_c,	# -c - count - количество строк (без параметра)
	'i' => \$flag_i,	# -i - ignore-case - игнорировать регистр (без параметра)
	'v' => \$flag_v,	# -v - invert - вместо совпадения исключать	(без параметра)
	'F' => \$flag_F,	# -F - fixed - точное совпадение со строкой, не паттерн (Like) (без параметра)
	'n' => \$flag_n,	# -n - line num - печатать номер строки (без параметра)
);
# получаем из ARGV шаблон (самый первый, остальное отбрасываем, grep пытается открыть как файл) при этом экранируем спецсимволы
$pattern = quotemeta(decode_utf8($ARGV[0]));
die "Ожидается наличие шаблона" unless ($pattern);

# Проверяем корректность числовых параметров
die "$param_C: Неверный аргумент длины контекста" if ($param_C < 0);
die "$param_B: Неверный аргумент длины контекста" if ($param_B < 0);
die "$param_A: Неверный аргумент длины контекста" if ($param_A < 0);

# Если установлена опция -F, то переданный паттерн воспринимается как просто строка текста (игнорируются спецсимволы)
# Если установлена опция -с, то игнорируем -A -B -C

# читаем стандартный ввод
my @line;
while (<STDIN>) {
	chomp;	# отсекаем \n
	push @line, $_;
}

# еcли массив пустой (допустим пользователь передал пустой файл или не передал вовсе введя вручную сtrl+D ) 
die "Нечего фильтровать" unless @line; 

# обрабатываем опции -A -B (выше приоритет) если установлена опция -С (ниже приоритет)
if ($param_C) {
	$param_A = $param_C unless $param_A;
	$param_B = $param_C unless $param_B;
}

# если установлена опция -i игнорировать регистр
if ($flag_i) {
	$pattern = qr/$pattern/i;
}
else {
	$pattern = qr/$pattern/;
}

# если установлена опция -v исключать
my $check_sub = sub {
		@{$_[2]} = $_[0] =~ /(.*)($_[1])(.*)/;	# 0 - $_ 1 - pattern 2 - куда поместить результат
	};
if ($flag_v) {
	$check_sub = sub {
		@{$_[2]} = $_[0] !~ /(.*)($_[1])(.*)/;	# 0 - $_ 1 - pattern 2 - куда поместить результат
	};
}


# перебираем строки и находим соответствующие паттерну
my $linenum = 1;	# к опции -n
my $linelastnum = 1;# к опциям -A -B -C (последний найденный элемент - чтобы добавлять в строчки где был разрыв --)
my $linecount = 0;	# к опции -c
foreach (@line) {
	my @elem;
	if ($check_sub->($_, $pattern, \@elem)) {
		# если установлена опция -с не выводим текстовую информацию
		unless ($flag_c) {
			# если установлена опция -n выводим с номером строки
			if ($flag_n) {
				print "\x1b[32m$linenum";
				print "\x1b[36m:";
				# если не установлена опция -v выделяем нужное нам текстом
				unless ($flag_v) {
					print "\x1b[0m$elem[0]";
					print "\x1b[1;31m$elem[1]";
					print "\x1b[0m$elem[2]";
				}
				else {
					print "\x1b[0m$_";
				}
			}
			else {
				# иначе без номера строки
				# если не установлена опция -v выделяем нужное нам текстом
				unless ($flag_v) {
					print "\x1b[0m$elem[0]";
					print "\x1b[1;31m$elem[1]";
					print "\x1b[0m$elem[2]";
				}
				else {
					print "\x1b[0m$_";
				}
			}
			print "\n";
		}
		else {
			# количество совпадений по шаблону
			$linecount++;
		}
	}
	# Номер текущей строки
	$linenum++;
}

if ($flag_c) {
	say $linecount;
}