package Local::Date;

use Time::Local;
use locale;	# Для вывода AM\PM
use POSIX qw(strftime locale_h);
setlocale(LC_TIME, "C");

use Local::Date::Interval;
use Mouse;

=head2
	Аттрибуты
=cut
has [qw(day month year hours minutes seconds)] => (
	is => 'rw',
	isa => 'Int',
);
has epoch => (
	is => 'rw',
	isa => 'Int',
	builder => '_init_by_date_comp',
	trigger => \&_get_date_comp,	# при изменении timestamp изменять соответственно day month year hours minutes seconds
);
has format => (
	is => 'rw',
	isa => 'Str',
	default => '%a %b %e %T %Y',
);

=head2
	Инициализируем epoch (сразу) согласно переданной дате.
=cut
sub _init_by_date_comp {
	my ($self) = @_;
	my $time = timegm($self->seconds(), $self->minutes(), $self->hours(), $self->day(), $self->month() - 1, $self->year());
	$self->epoch($time);
}

=head2
	Перерасчитывает компоненты даты (согласно timestamp)
=cut
sub _get_date_comp {
	my ($self) = @_;

	# получаем компоненты даты (по GMT)
	my @time = gmtime($self->epoch());
	$self->seconds($time[0]);
	$self->minutes($time[1]);
	$self->hours($time[2]);
	$self->day($time[3]);
	$self->month($time[4]);
	$self->year(1900 + $time[5]);
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
	Строковый контекст.
	* Дата должна преобразовываться в строку вида `"Fri May 19 02:08:33 2017"`.
	* Формат преобразовния определяется атрибутом объекта, и должен быть совместим с форматами функции `strftime`.
=cut
sub _string_con {
	my ($self) = @_;
	return strftime( $self->format(), gmtime($self->epoch()) );
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
		my $date = Local::Date->new( epoch => $date1->epoch() + $date2->duration() );
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
		my $date = Local::Date->new( epoch => $date1->epoch() - $date2->duration() );
		return $date;
	}
	elsif ($date2->isa('Local::Date')) {	# `Local::Date`
		my $int = Local::Date::Interval->new( duration => $date1->epoch() - $date2->epoch());
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
		$date1->epoch( $date1->epoch() + $date2->duration() );
		return $date1;
	}
	elsif ($date2 =~ /^\d+$/) {	# Целое число
		$date1->epoch( $date1->epoch() + $date2 );
		return $date1;
	}

	die "Incorrect object\n";
}

sub _sub_assign {
	my ($date1, $date2) = @_;

	if ($date2->isa('Local::Date::Interval')) {	# `Local::Date::Interval`
		$date1->epoch( $date1->epoch() - $date2->duration() );
		return $date1;
	}
	elsif ($date2 =~ /^\d+$/) {	# Целое число
		$date1->epoch( $date1->epoch() - $date2 );
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
	$date1->epoch( $date1->epoch() + 1 );
	return $date1;
}
sub _dec {
	my ($date1) = @_;
	$date1->epoch( $date1->epoch() - 1 );
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

no Mouse;

1;
