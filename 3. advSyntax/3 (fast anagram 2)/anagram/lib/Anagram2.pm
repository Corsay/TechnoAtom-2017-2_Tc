package Anagram2;
# vim: noet:

use 5.016;
use warnings;
use open qw(:utf8 :std);

=encoding UTF8

=head1 SYNOPSIS

Поиск анаграмм

=head1 anagram($arrayref)

Функция поиска всех множеств анаграмм по словарю.

Входные данные для функции: ссылка на массив - каждый элемент которого - слово на русском языке в кодировке utf8

Выходные данные: Ссылка на хеш множеств анаграмм.

Ключ - первое встретившееся в словаре слово из множества
Значение - ссылка на массив, каждый элемент которого слово из множества, в том порядке в котором оно встретилось в словаре в первый раз.

Множества из одного элемента не должны попасть в результат.

Все слова должны быть приведены к нижнему регистру.
В результирующем множестве каждое слово должно встречаться только один раз.
Например

anagram(['пятак', 'ЛиСток', 'пятка', 'стул', 'ПяТаК', 'слиток', 'тяпка', 'столик', 'слиток'])

должен вернуть ссылку на хеш

{
	'пятак'  => ['пятак', 'пятка', 'тяпка'],
	'листок' => ['листок', 'слиток', 'столик'],
}

=cut

sub anagram {
	my $words_list = shift;
	# хэш результата, хэш связка
	my %result;
	my %relative;

	use POSIX qw(strftime);
	# Get current datatime
	my $last_time_start = strftime "%Y-%m-%d %H:%M:%S\n", localtime;

	#
	# Поиск анаграмм
	#
	# перебираем элементы списка(разименовывая ссылку на массив)
	foreach (@{$words_list}) {
		if (ref $_ ne "ARRAY") {
			# если в строке всего одно слово делаем из него ссылку на это слово
			$_ = [$_];
		}
		foreach (@{$_}) {
			# разбиваем слово на буквы
			my @word = split "", fc($_);
			# сортируем слово и объединяем его
			@word = sort {$a cmp $b} @word;
			my $word = join "", @word;
			# если есть ключ связка(сортированное слово) в хэш связке
			if (exists $relative{$word}) {
				# Проверяем на наличие записи в массиве
				my $key = $relative{$word};
				my $found = 0;
				for my $val (@{$result{"$key"}}) {
					if (fc($val) eq fc($_)) {
						$found = 1;
						last;
					}
				}
				unless ($found) {
					# то добавляем в хэш результат новую запись
					push @{$result{"$key"}}, fc($_);
				}
			}
			else {
				# если такого ключа связки нет, то добавим его и запись в хэш результата
				$relative{$word} = fc($_);
				$result{"\F$_\E"} = ["\F$_\E"];
			}
		}
	}
	
	# переносим все нужное в результирующий хеш
	my %pastresult;
	while (my ($k, $v) = each %result) {
		if (@{$v} != 1) {
			$pastresult{$k} = $v;
		}
	}

	# Get current datatime
	my $last_time_end = strftime "%Y-%m-%d %H:%M:%S\n", localtime;

	print "Start Script ".$last_time_start."\n";
	print "End Script ".$last_time_end."\n";

	return \%pastresult;
}

1;