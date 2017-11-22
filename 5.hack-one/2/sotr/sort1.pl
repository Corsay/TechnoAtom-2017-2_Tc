#!/usr/bin/perl
use strict;
use Getopt::Long;
no warnings "experimental::smartmatch";
my @array;
my @result;


my $rev = 0;
my $column = 0;
my $number = 0;
my $unique = 0;

GetOptions('r' => \$rev, 'k=i' => \$column, 'n' => \$number, 'u' => \$unique); #обрабатываем входные данные

while(my $string = <STDIN>) { #разделяем STDIN на строки
  chomp($string); # отсекаем символ \n
  push(@array, $string);
}
print "@array\n";
#если не задана ни одна опция
if($rev == 0 && $column == 0 && $number == 0 && $unique == 0){	
	@result = sort { $a cmp $b } @array;
}

if($column){
	my $temp_ref;G
	my @split_arr;
	my @temp_result;
	for my $var(@array){
		my @temp_arr = split / /, $var; #разделяем строки на колонки
		$temp_ref = \@temp_arr; #делаем 
		push (@split_arr, $temp_ref);
	}
	print "@split_arr sfdsg\n";
	if ($number){
		@temp_result = sort { spec_sort($a, $b, $column-1, 1) } @split_arr;
	}
	else{
		@temp_result = sort { spec_sort($a, $b, $column-1, 0) } @split_arr;
	}
	print "@temp_result\n";
	#представляем результат сортировки в виде массива строк
	for my $var (@temp_result){
		my $tempstr = join " ", @{$var};
		push (@result, $tempstr);
	}
}
my $len = @result;

if($unique){
	my %uniq;
	@result = grep { !$uniq{$_}++ } @result;
}

if($rev){
	@result = reverse @result;
}

# если подключена опция сортировки по числам. но не по колонкам
if( $number && !($column) ){
	@result = sort { $a <=> $b } @array;
	
}


for my $var (@result){
	print "$var\n"
}

#функция, сравнивающая строки по колонке
#функция принимает ссылки на строки (str1, str2), номер сортируемой колонки и модификатор чсортировки по числам (0 - по строкам, 1 - по числам)
sub spec_sort{
	my $temp; # возвращаемая переменная
	my ( $str1, $str2, $k, $n) = @_;
#определяем длины массива	
	my $length1 = @{$str1};
	my $length2 = @{$str2};

	if ( $length1 <= $k && $length2 <= $k) { #если колонка выходит за границу обеих строк
		# конкатенируем обратно в строки
		my $f_str1 = join " ", @{$str1};
		my $f_str2 = join " ", @{$str2};
		if($n) { #если сортировка по числам

			return $f_str1 <=> $f_str2;
		}
		else { #если сортировка по строкам
			$temp = $f_str1 cmp $f_str2;

			return $temp;
		}
	}
	else{ #если колонка определена хотя бы в одной строке 
		if($n){ #если сортировка по числам
			$temp = $str1->[$k] <=> $str2->[$k];
			if ($temp == 0){

				return spec_sort($str1, $str2, ($k+1), 1);
			}
			else{

				return $temp;
			}
		}
		else{ #если сортировка по строкам
			$temp = $str1->[$k] cmp $str2->[$k];
			if ($temp == 0){
				return spec_sort($str1, $str2, ($k+1), 0);
			}
			else{
				return $temp;
			}
		}
	}

}
