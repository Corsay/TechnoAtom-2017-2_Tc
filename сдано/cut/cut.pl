#!/usr/bin/env perl

use 5.016;
use warnings;
use utf8;
use open qw(:utf8 :std);
use Getopt::Long;

# -ru = -r -u
# --ru = -ru 
Getopt::Long::Configure("bundling");

# значения по умолчанию
my $def_TAB = "\t";

# Получаем ключи и параметры
my $f_list = '';	# пустая строка для параметров - чисел
my $TAB = $def_TAB;	# значение по умолчанию 
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

# еcли нам передали пустой параметр для опции -d или не одиночный разделитель
die "Разделитель должен быть одним символом" if (length($TAB) > 1);
if ($TAB eq "") {
	# Если установлена опция -s то выходим
	if ($flag_s) {
		exit;
	}
	else {	
		# иначе выводим все и выходим
		while (<STDIN>) {
			say $_;
		}
		exit;
	}
}

# выводим нужные нам колонки (опция -f) (если в строке нет колонки, считаем что колонка пуста)
while (<STDIN>) {
	chomp;
	# убираем строку без разделителя (опция -s)
	if ($_ !~ /$TAB/) {
		if ($flag_s) { next; }
		else { say $_; next; }	# вывод как в cut
	}
	my @strtab = /([^$TAB]+)$TAB?/g;
	foreach (@f_list) {
		last unless defined $strtab[$_-1];
		print "$TAB" unless ($f_list[0] == $_);
		print $strtab[$_-1];
	}
	print "\n";
}
