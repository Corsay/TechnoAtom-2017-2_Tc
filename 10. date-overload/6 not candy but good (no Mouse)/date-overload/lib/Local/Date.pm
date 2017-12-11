package Local::Date;

use parent Local::Object;

use Time::Local;
use locale;
use POSIX qw(strftime locale_h);
setlocale(LC_TIME, "C");

use Local::Date::Interval;

use DDP;

=head1 NAME
	Local::Date - объект даты
=head1 VERSION
	Version 1.00
=cut
our $VERSION = '1.00';
=head1 SYNOPSIS
=cut

=head2
	Перерасчитывает компоненты даты (согласно timestamp)
=cut
sub _get_data_comp {
	my ($self) = @_;

	# получаем компоненты даты (по GMT)
	my @time = gmtime($self->{epoch});
	$self->{seconds} = $time[0];
	$self->{minutes} = $time[1];
	$self->{hours} = $time[2];
	$self->{day} = $time[3];
	$self->{month} = $time[4];
	$self->{year} = 1900 + $time[5];
}

=head2
	Сеттеры, геттеры,
	оверлоад (перегрузка)
=cut
use Class::XSAccessor
	setters => [ 'format' ],	# setter для формата вывода даты в строковом контексте
	getters => [ 'day', 'month', 'year', 'hours', 'minutes', 'seconds', 'epoch' ];	# В любой момент времени должна быть возможность обратиться как к компонентам времени, как к timestamp, для получения их текущего значения.

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
	Конструкторы.
	Инициализация объекта класса Local::Date::Interval
	Определяет какой из конструкторов объекта вызвать (по компонентам даты (дни, месяцы, года, часы, минуты, секунды) и по timestamp)
=cut
sub init {
	my ($self, %params) = @_;

	if (exists $params{epoch}) { _init_by_timestamp($self, %params); }
	else { _init_by_date($self, %params); }

	return;
}

# Инициализация компонентами даты (day, month, year, hours, minutes, seconds)
sub _init_by_date {
	my ($self, %params) = @_;

	# запоминаем компоненты даты
	$self->{seconds} = $params{seconds};
	$self->{minutes} = $params{minutes};
	$self->{hours} = $params{hours};
	$self->{day} = $params{day};
	$self->{month} = $params{month} - 1;
	$self->{year} = $params{year};

	# получаем timestamp (по GMT)
    my $time = timegm($self->{seconds}, $self->{minutes}, $self->{hours}, $self->{day}, $self->{month}, $self->{year});
	$self->{epoch} = $time;

	return;
}

# Инициализация по timestamp (epoch)
sub _init_by_timestamp {
	my ($self, %params) = @_;

    # запоминаем timestamp
	$self->{epoch} = $params{epoch};

	# получаем компоненты даты (по GMT)
	$self->_get_data_comp();

	return;
}

=head2
	Строковый контекст.
	* Дата должна преобразовываться в строку вида `"Fri May 19 02:08:33 2017"`.
	* Формат преобразовния определяется атрибутом объекта, и должен быть совместим с форматами функции `strftime`.
=cut
sub _string_con {
	my ($self) = @_;

	if (exists $self->{format}) {
		return strftime( $self->{format}, gmtime($self->{epoch}) );
	}
	else {
		# вывод как gmtime
		return gmtime($self->{epoch});
	}
}

=head2
	Числовой контекст.
	* Дата должна преобразовываться в число секунд прошедших с `01-01-1970 00:00:00` (*unix timestamp*).
	Сложение.
	* Операция должна прибавлять указанное количество секунд к объекту.
	* Если вторым операндом является объект типа `Local::Date::Interval`, то операция должна возвращать объект типа `Local::Date`.
	* Если вторым операндом является число, то операция должна возвращать число (unix timestamp).
	* В остальных случая должно вызываться исключение.
=cut
sub _add {
	my ($date1, $date2) = @_;

	if ($date2->isa('Local::Date::Interval')) {	# `Local::Date::Interval`
		my $date = Local::Date->new(epoch => $date1->epoch() + $date2->duration() );
		return $date;
	}
	elsif ($date2 =~ /^\d+$/) {	# Целое число
		return $date1->epoch() + $date2;
	}

	return undef;
}

=head2
	Вычитание.
	* Операция должна вычитать указанное количество секунд из объекта или вычитать объект даты.
	* Если вторым операндом является объект типа `Local::Date::Interval`, то операция должна возвращать объект типа `Local::Date`.
	* Если вторым операдном является объект типа `Local::Date`, то операция должна возвращать объект типа `Local::Date::Interval`.
	* Если вторым операндом является число, то операция должна возвращать число (*unix timestamp*).
	* Операция вычитания объекта типа `Local::Date` из чего либо отличного от объект типа `Local::Date`, должна приводить к вызову исключения.
	* В остальных случая должно вызываться исключение.
=cut
sub _subtract {
	my ($date1, $date2, $inverse) = @_;

	# not `Local::Date` - `Local::Date` -> error
	if ($inverse) { return undef unless $date2->isa('Local::Date'); }

	if ($date2->isa('Local::Date::Interval')) {	# `Local::Date::Interval`
		my $date = Local::Date->new(epoch => $date1->epoch() - $date2->duration() );
		return $date;
	}
	elsif ($date2->isa('Local::Date')) {	# `Local::Date`
		my $int = Local::Date::Interval->new(duration => $date1->epoch() - $date2->epoch());
		return $int;
	}
	elsif ($date2 =~ /^\d+$/) {	# Целое число
		return $date1->epoch() - $date2;
	}

	return undef;
}

=head2
	Сложение/вычитание с присваиванием.
	* Операции должны прибавлять/вычитать указанное количество секунд к/из объекта.
	* Если аргументом является число или объект типа `Local::Date::Interval`, то должен возращаться исходный объект типа `Local::Date`.
	* Новых объектов создаваться не должно!
	* В остальных случая должно вызываться исключение.
=cut
sub _add_assign {
	my ($date1, $date2) = @_;

	if ($date2->isa('Local::Date::Interval')) {	# `Local::Date::Interval`
		$date1->{epoch} += $date2->duration();
		$date1->_get_data_comp();	# корректируем компоненты даты (по GMT)
		return $date1;
	}
	elsif ($date2 =~ /^\d+$/) {	# Целое число
		$date1->{epoch} += $date2;
		$date1->_get_data_comp();	# корректируем компоненты даты (по GMT)
		return $date1;
	}

	die "Incorrect object\n";
}

sub _sub_assign {
	my ($date1, $date2) = @_;

	if ($date2->isa('Local::Date::Interval')) {	# `Local::Date::Interval`
		$date1->{epoch} -= $date2->duration();
		$date1->_get_data_comp();	# корректируем компоненты даты (по GMT)
		return $date1;
	}
	elsif ($date2 =~ /^\d+$/) {	# Целое число
		$date1->{epoch} -= $date2;
		$date1->_get_data_comp();	# корректируем компоненты даты (по GMT)
		return $date1;
	}

	die "Incorrect object\n";
}

=head2
	Операции инкремента/декремента.
	* К исходному объекту должна быть добавлена/вычтена одна секунда.
	* Новых объектов создаваться не должно!
=cut
sub _inc {
	my ($date1) = @_;
	$date1->{epoch}++;
	$date1->_get_data_comp();	# корректируем компоненты даты (по GMT)
	return $date1;
}
sub _dec {
	my ($date1) = @_;
	$date1->{epoch}--;
	$date1->_get_data_comp();	# корректируем компоненты даты (по GMT)
	return $date1;
}

=head2
	Операции сравнения.
	* Должна быть возможность сравнивать объекты между собой, а так же с временем заданным как количество секунд (*unix timestamp*).
	* Так же объекты должны корректно сортироваться функцией *sort*.
=cut
sub _get_seconds {
	my ($date1, $date2) = @_;

	my $sec1 = $date1->epoch();
	my $sec2;
	if ($date2->isa('Local::Date::Interval')) { $sec2 = $date2->duration(); }	# `Local::Date::Interval`
	elsif ($date2->isa('Local::Date')) { $sec2 = $date2->epoch(); }	# `Local::Date`
	elsif ($date2 =~ /^\d+$/) { $sec2 = $date2; }	# число

	return ($sec1, $sec2);
}
sub _sort_digit {	# сортировка как чисел (<=>)
	my ($date1, $date2, $inverted) = @_;
	my ($sec1, $sec2) = _get_seconds($date1, $date2);
	return -$inverted || 1 unless ($sec2);	# если подали что-то не то то делаем как сортировка
	return $sec1 <=> $sec2;
}

1;
