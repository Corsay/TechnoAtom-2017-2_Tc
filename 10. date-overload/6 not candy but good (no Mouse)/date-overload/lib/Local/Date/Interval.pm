package Local::Date::Interval;

use parent Local::Object;

use DDP;

=head1 NAME
	Local::Date::Interval - объект временного интревала
=head1 VERSION
	Version 1.00
=cut
our $VERSION = '1.00';
=head1 SYNOPSIS
=cut

=head2
	Перерасчитывает компоненты длительности интервала
=cut
sub _get_duration_comp {
	my ($self) = @_;

	# получаем компоненты длительности интервала
	my $duration = $self->{duration};
	$self->{days} = int($duration / 60 / 60 / 24);	$duration %= 60 * 60 * 24;
	$self->{hours} = int($duration / 60 / 60);	$duration %= 60 * 60;
	$self->{minutes} = int($duration / 60);	$duration %= 60;
	$self->{seconds} = int($duration);
}

=head2
	геттеры,
	оверлоад (перегрузка)
=cut
use Class::XSAccessor
	getters => [ 'days', 'hours', 'minutes', 'seconds', 'duration' ];	# В любой момент времени должна быть возможность обратиться как к компонентам длительности интеревала, так и к длительности в секундах, для получения их текущего значения.

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
	Определяет какой из конструкторов объекта вызвать (по компонентам длительности (дни, часы, минуты, секунды) и по длительности в секундах)
=cut
sub init {
	my ($self, %params) = @_;

	if (exists $params{duration}) { _init_by_duration($self, %params); }
	else { _init_by_duration_comp($self, %params); }

	return;
}

# Инициализация компонентами длительности интервала (days, hours, minutes, seconds)
sub _init_by_duration_comp {
	my ($self, %params) = @_;

	# запоминаем компоненты длительности интервала
	$self->{seconds} = $params{seconds};
	$self->{minutes} = $params{minutes};
	$self->{hours} = $params{hours};
	$self->{days} = $params{days};

	# получаем длительность интервала в секундах
	$self->{duration} = ( ( $params{days} * 24 + $params{hours} ) * 60 + $params{minutes} ) * 60 + $params{seconds};

	return;
}

# Инициализация по длительность интервала в секундах (duration)
sub _init_by_duration {
	my ($self, %params) = @_;

    # запоминаем длительность интервала в секундах
    my $duration = $params{duration};
	$self->{duration} = $duration;

	# получаем компоненты длительности интервала
	$self->_get_duration_comp();

	return;
}


=head2
	Строковый контекст.
	* Интервал должен преобразовываться в строку вида `"1524 days, 20 hours, 0 minutes, 14 seconds"`.
=cut
sub _string_con {
	my ($self) = @_;
	return $self->days() . " days, " . $self->hours() . " hours, " . $self->minutes() . " minutes, " . $self->seconds() . " seconds";
}

=head2
	Числовой контекст.
	* Интервал должен преобразовываться в число равное длительности интервала в секундах.
	Сложение.
	* Операция должна прибавлять указанное количество секунд к объекту.
	* Если вторым операндом является объект типа `Local::Date::Interval`, то операция должна возвращать объект типа `Local::Date::Interval`.
	* Если вторым операндом является число, то операция должна возвращать число (*unix timestamp*).
	* В остальных случая должно вызываться исключение.
=cut
sub _add {
	my ($date1, $date2) = @_;

	if ($date2->isa('Local::Date::Interval')) {	# `Local::Date::Interval`
		my $date = Local::Date::Interval->new(duration => $date1->duration() + $date2->duration() );
		return $date;
	}
	elsif ($date2 =~ /^\d+$/) {	# Целое число
		return $date1->duration() + $date2;
	}

	return undef;
}

=head2
	Вычитание.
	* Операция должна вычитать указанное количество секунд из объекта.
	* Если вторым операндом является объект типа `Local::Date::Interval`, то операция должна возвращать объект типа `Local::Date::Interval`.
	* Если вторым операндом является число, то операция должна возвращать число (*unix timestamp*).
	* В остальных случая должно вызываться исключение.
=cut
sub _subtract {
	my ($date1, $date2, $inverse) = @_;

	# not `Local::Date::Interval` - `Local::Date::Interval` -> error
	if ($inverse) { return undef unless $date2->isa('Local::Date::Interval'); }

	if ($date2->isa('Local::Date::Interval')) {	# `Local::Date::Interval`
		my $date = Local::Date::Interval->new(duration => $date1->duration() - $date2->duration() );
		return $date;
	}
	elsif ($date2 =~ /^\d+$/) {	# Целое число
		return $date1->duration() - $date2;
	}

	return undef;
}

=head2
	Сложение/вычитание с присваиванием.
	* Операции должны прибавлять/вычитать указанное количество секунд к/из объекта.<br>
	* Если аргументом является число или объект типа `Local::Date::Interval`, то должен возращаться исходный объект типа `Local::Date::Interval`.<br>
	* Новых объектов создаваться не должно!<br>
	* В остальных случая должно вызываться исключение.
=cut
sub _add_assign {
	my ($date1, $date2) = @_;

	if ($date2->isa('Local::Date::Interval')) {	# `Local::Date::Interval`
		$date1->{duration} += $date2->duration();
		$date1->_get_duration_comp();	# корректируем компоненты даты (по GMT)
		return $date1;
	}
	elsif ($date2 =~ /^\d+$/) {	# Целое число
		$date1->{duration} += $date2;
		$date1->_get_duration_comp();	# корректируем компоненты даты (по GMT)
		return $date1;
	}

	die "Incorrect object\n";
}

sub _sub_assign {
	my ($date1, $date2) = @_;

	if ($date2->isa('Local::Date::Interval')) {	# `Local::Date::Interval`
		$date1->{duration} -= $date2->duration();
		$date1->_get_duration_comp();	# корректируем компоненты даты (по GMT)
		return $date1;
	}
	elsif ($date2 =~ /^\d+$/) {	# Целое число
		$date1->{duration} -= $date2;
		$date1->_get_duration_comp();	# корректируем компоненты даты (по GMT)
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
	$date1->{duration}++;
	$date1->_get_duration_comp();	# корректируем компоненты даты (по GMT)
	return $date1;
}
sub _dec {
	my ($date1) = @_;
	$date1->{duration}--;
	$date1->_get_duration_comp();	# корректируем компоненты даты (по GMT)
	return $date1;
}

=head2
	Операции сравнения.
	* Должна быть возможность сравнивать объекты между собой, а так же с временем заданным как количество секунд (*unix timestamp*).
	* Так же объекты должны корректно сортироваться функцией *sort*.
=cut
sub _get_seconds {
	my ($date1, $date2) = @_;

	my $sec1 = $date1->duration();
	my $sec2;
	if ($date2->isa('Local::Date::Interval')) { $sec2 = $date2->duration(); }	# `Local::Date::Interval`
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
