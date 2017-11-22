#!/usr/bin/env perl

use 5.016;
use warnings;
use utf8;
use open qw(:utf8 :std);
use Getopt::Long;

# -ru = -r -u
# --ru = -ru 
Getopt::Long::Configure("bundling");
use DDP;

# значения по умолчанию
my $def_TAB = '\t';

# Получаем ключи и параметры
my $f_list = '';	# пустая строка для параметров - чисел
my $TAB = $def_TAB;	# по умолчанию - пробельные символы
my $flag_s = '';	# false (без параметров)
GetOptions (
	'f=s' => \$f_list,	# -f - fields - выбрать поля(колонки)
	'd=s' => \$TAB,		# -d - delimeter - использовать другой разделитель (вместо пробела по-умолчанию)(один параметр - символ)
	's' => \$flag_s,	# -s - separated - только строки с разделителем (отсеить строки без разделителя, учесть опцию -d)	
);
# получаем номера колонок и если не введено не одной говорим что нужно задать список полей
my @f_list = $f_list =~ /(\d+)/g;	
die "Вы должны задать список полей" unless @f_list;
# оставляем только уникальные номера колонок и сортируем
{
	my %uniq;
	@f_list = grep { !$uniq{$_}++ } @f_list;
}
@f_list = sort {$a <=> $b} @f_list;

# читаем стандартный ввод
my @line;	# в @line будем иметь строки сортируемого текста
while (<STDIN>) {
	chomp;	# отсекаем \n
	push @line, $_;
}

# еcли массив пустой (допустим пользователь передал пустой файл или не передал вовсе введя вручную сtrl+D ) 
die "Нечего вырезать" unless @line; 

# еcли нам передали пустой параметр для опции -d и при этом не установлена опция -s то выводим все и выходим
if ($TAB eq "") {
	if ($flag_s) {
		exit;
	}
	else {
		foreach (@line) {
			say $_;
		}
		exit;
	}
}

# убираем строки без разделителя (опция -s)
if ($flag_s) {
	@line = grep {$_ =~ /.*$TAB.*/} @line;
}

# выводим нужные нам колонки (опция -f) (если в строке нет колонки, считаем что колонка пуста)
# когда разбираем строку запоминаем какие табы там были и в каком порядке
foreach (@line) {
	my @strtab = /([^$TAB]+|)($TAB)?/g;
	# если строка не содержит раделителя то тупо выводим её (как в cut)
	unless (defined $strtab[1]) {
		print $_;
	}
	# иначе работаем со строкой состоящей из колонок и выводим нужные колонки
	else {
		foreach (@f_list) {
			my $strpos = ($_ - 1) * 2;
			last unless (defined $strtab[$strpos]);	# так как параметры отсортированны по возрастанию
			my $tabpos = $strpos + 1;
			print $strtab[$strpos];
			print $strtab[$tabpos] if (defined $strtab[$tabpos] and @f_list > 1 and $f_list[$#f_list] != $_);
		}
	}
	print "\n";
}
