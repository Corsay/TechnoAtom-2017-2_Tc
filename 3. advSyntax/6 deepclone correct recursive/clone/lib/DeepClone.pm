package DeepClone;
# vim: noet:

use 5.016;
use warnings;
use DDP;
use Data::Dumper;

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

sub clone {
	my $orig = shift;
	my $cloned;

	# ...
	# deep clone algorithm here
	# ...
	#say Dumper($orig);
	#p $orig;
	eval { # try
		$cloned = dumperClone($orig);

		return $cloned;
	}
	or do {	# catch
		return undef;
	}
}

# читаем переданную структуру и возвращаем ссылку
sub dumperClone {
	my $what = shift; 
	my $refs = shift;	# cохраняем ссылки (чтобы их использовать когда можно и не пересоздавать обьекты)
	my $clone;

	if (my $ref = ref $what) {
		# если ссылка не добавлена в хэш ссылок
		unless (exists $refs->{$what}) {
			# если ссылка на массив
			if ($ref eq 'ARRAY') {
				$clone = [];
				$refs->{$what} = $clone;
				push @{$clone}, dumperClone($_, $refs) for @{$what};
			}
			# если ссылка на хэш
			elsif ($ref eq 'HASH') {
				$clone = {};
				$refs->{$what} = $clone;
				while (my ($k,$v) = each %{$what}) {
					$clone->{$k} = dumperClone($v, $refs);
				}
			}
			# если undef то запишем как undef
			elsif ($ref eq '') {
				$clone = undef;
			}
			# Если ссылка на нечто иное то в итоге не скопируем вовсе выдав ошибку (обязательно оборачиваем вызов в try catch (eval or do))
			else { 
				die "unsupported: $ref";
			}
		}
		else {
			# если ссылка уже добавлена в хэш ссылок
			$clone = $refs->{$what};
		}
	}
	# если не ссылка
	else {
		$clone = $what;
	}

	# возвращаем ссылку на структуру
	return $clone;
}

1;
