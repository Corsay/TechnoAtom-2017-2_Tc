package Local::Object;

use strict;
use warnings;

sub new {
	my ($class, @params) = @_;

	my $object = bless {}, $class;
	$object->init(@params);

	return $object;
}

sub init {
	my ($self, @params) = @_;

	return;
}

=head2
	Перегрузка операторов
=cut
use overload
	# контексты
	'""' => '_string_con',	# строковый
	# сложение/вычитание
	'+' => '_add',	# числовой контекст (в случае добавления числа)
	'-' => '_subtract',
	# Сложение/вычитание с присваиванием
	'+=' => '_add_assign',
	'-=' => '_sub_assign',
	# операции инкремента/декремента
	'++' => '_inc',
	'--' => '_dec',
	# операции сравнения
	'<' => '_sort_digit',
	'<=' => '_sort_digit',
	'>' => '_sort_digit',
	'>=' => '_sort_digit',
	'==' => '_sort_digit',
	'!=' => '_sort_digit',
	'<=>' => '_sort_digit',
	fallback => 1;

=head2
	Операции сравнения.
	* Должна быть возможность сравнивать объекты между собой, а так же с временем заданным как количество секунд (*unix timestamp*).
	* Так же объекты должны корректно сортироваться функцией *sort*.
=cut
sub _get_seconds {
	return 0;	# обязательно реализовать в наследующем классе
}
sub _sort_digit {	# сортировка как чисел (<=>)
	my ($date1, $date2, $inverted) = @_;
	my ($sec1, $sec2) = _get_seconds($date1, $date2);
	return -$inverted || 1 unless ($sec2);	# если подали что-то не то то делаем как сортировка
	return $sec1 <=> $sec2;
}

1;
