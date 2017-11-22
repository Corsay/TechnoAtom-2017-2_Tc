package DeepClone2;

use 5.010;
use strict;
use warnings;

=encoding UTF8
=head1 SYNOPSIS
Клонирование сложных структур данных
=head1 clone($orig)
Функция принимает на вход ссылку на какую либо структуру данных и отдаюет, в качестве результата, ее точную независимую копию.
Это значит, что ни один элемент результирующей структуры, не может ссылаться на элементы исходной, но при этом она должна в точности повторять ее схему.
Входные данные:
* undef
* строка
* число
* ссылка на массив
* ссылка на хеш
Элементами ссылок на массив и хеш, могут быть любые из указанных выше конструкций.
Любые отличные от указанных типы данных -- недопустимы. В этом случае результатом клонирования должен быть undef.
Выходные данные:
* undef
* строка
* число
* ссылка на массив
* ссылка на хеш
Элементами ссылок на массив или хеш, не могут быть ссылки на массивы и хеши исходной структуры данных.
=cut

sub clone2 {
	my $orig = shift;
	my $refs = shift;
	$refs //= { "undef" => 0};		
	return undef if($refs->{"undef"} == 1);

	my $cloned;	
	
	if(ref $orig eq "ARRAY"){
		unless(exists $refs->{$orig}){
			if( ref $orig eq "ARRAY" || ref $orig eq "HASH"){
				$cloned = [];#иначе запишется undef
				$refs->{$orig} = $cloned; #запоминаем, чтобы использовать ссылку, а не создавать новую копию
			}
			for my $v(@$orig){
					push @$cloned, clone2($v,  $refs);
			}
		}else{
			$cloned = $refs->{$orig};
		}
	}elsif(ref $orig eq "HASH"){ #аналогично массивам
		unless(exists $refs->{$orig}){
			if( ref $orig eq "ARRAY" || ref $orig eq "HASH"){
				$cloned = {};
				$refs->{$orig} = $cloned;
			}
			while( my ($k, $v) = each %$orig){				
					$cloned->{$k} = clone2($v, $refs);		
			}
		}else{
			$cloned = $refs->{$orig};
		}
		return undef if($refs->{"undef"} == 1);
	}elsif(ref $orig eq ""){
		$cloned = $orig;
		return undef if($refs->{"undef"} == 1);
	}else{
		$cloned = undef;
		$refs->{"undef"} = 1;
	}

	return undef if($refs->{"undef"} == 1);
	return $cloned;
}

1;