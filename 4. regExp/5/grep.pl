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
die "$param_C: Неверный аргумент длины контекста" if ($param_C < 0);
die "$param_B: Неверный аргумент длины контекста" if ($param_B < 0);
die "$param_A: Неверный аргумент длины контекста" if ($param_A < 0);

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
			@{$_[2]} = $_[0] =~ /(.*)($_[1])(.*)/;	# 0 - $_ 1 - pattern 2 - куда поместить результат
			return $_[0] =~ /.*$_[1].*/;
		};
	if ($flag_v) {
		$check_sub = sub {
			@{$_[2]} = $_[0] !~ /(.*)($_[1])(.*)/;	# 0 - $_ 1 - pattern 2 - куда поместить результат
			return $_[0] !~ /.*$_[1].*/;
		};
	}
}

# перебираем строки и находим соответствующие паттерну
my $curcountA = 0;
my $needOutA = 0;	# запрос на вывод последующих A строк
my $outDelimA = 0;	# выводить ли -- для опций -A
my @outB = []; 
my $outDelimB = 0;	# выводить ли -- для опций -B
my $first = 1;		# для опция -A -B
my $linenum = 1;	# к опции -n
my $linecount = 0;	# к опции -c
foreach (@line) {
	my @elem;
	if ($check_sub->($_, $pattern, \@elem)) {
		# если установлена опция -с не выводим текстовую информацию
		unless ($flag_c) {
			# Вывод согласно опции -A
			# Вывод согласно опции -B
			{
				# выводим -- и массив
				if ($outDelimB and not $first) { print "\x1b[36m--\x1b[0m\n"; }
				foreach my $val (@outB) { print "$val\n"; }
				
				# очищаем массив и флаг
				@outB = [];
				$outDelimB = 0;
			}
			# если установлена опция -n выводим с номером строки
			if ($flag_n) {
				print "\x1b[32m$linenum";
				print "\x1b[36m:";
			}
			# если не установлена опция -v выделяем найденное
			unless ($flag_v) {
				print "\x1b[0m$elem[0]";
				print "\x1b[1;31m$elem[1]";
				print "\x1b[0m$elem[2]";
			}
			else {
				print "\x1b[0m$_";
			}
			print "\n";
			$first = 0; # первое значение выведено
			# обрабатываем вывод A
			#{
				#$needOutA = 1; # ожидаем вывода N строк после
				#$curcountA = 0;
				#$outDelimA = 0;
			#}
		}
		else {
			# количество совпадений
			$linecount++;
		}
	}
	else {
		# если установлена опция -n выводим с номером строки
		if ($flag_n) {
			$_ = "\x1b[32m$linenum\x1b[36m:\x1b[0m" . $_;
		}
		# работаем с выводом для -B (преконтекст)
		if (@outB < $param_B) {
			push @outB, $_;
		}
		else {
			$outDelimB = 1; # говорим что нам нужен разделитель
			shift @outB;
			push @outB, $_;
		}
		#if ($needOutA) {
			# работаем с выводом для -A (постконтекст)
		#	if ($curcountA < $param_A) {
		#		print "$_\n"
		#	}
		#	else {
		#		unless ($outDelimB) {
		#			$outDelimB = 1;
		#			print "\x1b[36m--\x1b[0m\n";
		#		}
		#		$needOutA = 0;
		#	}
		#}
	}
	# номер текущей строки
	$linenum++;
}

if ($flag_c) {
	say $linecount;
}