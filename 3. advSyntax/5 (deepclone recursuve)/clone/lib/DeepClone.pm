package DeepClone;
# vim: noet:

use 5.016;
use warnings;
use DDP;

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
	$cloned = dumperClone($orig);

	return $cloned;
}

# читаем переданную структуру и возвращаем ссылку
sub dumperClone {
	my $what = shift; 
	my $clone;

	if (my $ref = ref $what) {
		# если ссылка на массив
		if ($ref eq 'ARRAY') {
			push @{$clone}, dumperClone($_) for @{$what};
			# Еcли массив пустой
			unless (@{$what}) {
				$clone = [];
			}
		}
		# если ссылка на хэш
		elsif ($ref eq 'HASH') {
			my $i = 0;
			while (my ($k,$v) = each %{$what}) {
				$clone->{$k} = dumperClone($v);
				$i++;
			}
			# Еcли хэш пустой
			unless ($i) {
				$clone = {};
			}
		}
		# Если ссылка на нечто иное и undef
		else { 
			$clone = undef;
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
