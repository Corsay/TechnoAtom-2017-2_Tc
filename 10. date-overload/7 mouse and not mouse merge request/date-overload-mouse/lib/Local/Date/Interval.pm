package Local::Date::Interval;

use Mouse;

=head2
	Аттрибуты
=cut
has [qw(days hours minutes seconds)] => (
	is => 'rw',
	isa => 'Int',
);
has duration => (
	is => 'rw',
	isa => 'Int',
	builder => '_init_by_duration_comp',
	trigger => \&_get_duration_comp,	# при изменении duration изменять соответственно days hours minutes seconds
);

=head2
	Инициализируем duration (сразу) согласно переданным компонентам длительности интервала.
=cut
sub _init_by_duration_comp {
	my ($self) = @_;
	# получаем длительность интервала в секундах
	$self->duration( ( ( $self->days() * 24 + $self->hours() ) * 60 + $self->minutes() ) * 60 + $self->seconds() );
}

=head2
	Перерасчитывает компоненты длительности интервала
=cut
sub _get_duration_comp {
	my ($self) = @_;

	# получаем компоненты длительности интервала
	my $duration = $self->duration();
	$self->days( int($duration / 60 / 60 / 24) );	$duration %= 60 * 60 * 24;
	$self->hours( int($duration / 60 / 60) );	$duration %= 60 * 60;
	$self->minutes( int($duration / 60) );	$duration %= 60;
	$self->seconds( int($duration) );
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
		my $date = Local::Date::Interval->new( duration => $date1->duration() + $date2->duration() );
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
		my $date = Local::Date::Interval->new( duration => $date1->duration() - $date2->duration() );
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
		$date1->duration( $date1->duration() + $date2->duration() );
		return $date1;
	}
	elsif ($date2 =~ /^\d+$/) {	# Целое число
		$date1->duration( $date1->duration() + $date2 );
		return $date1;
	}

	die "Incorrect object\n";
}

sub _sub_assign {
	my ($date1, $date2) = @_;

	if ($date2->isa('Local::Date::Interval')) {	# `Local::Date::Interval`
		$date1->duration( $date1->duration() - $date2->duration() );
		return $date1;
	}
	elsif ($date2 =~ /^\d+$/) {	# Целое число
		$date1->duration( $date1->duration() - $date2 );
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
	$date1->duration( $date1->duration() +1 );
	return $date1;
}
sub _dec {
	my ($date1) = @_;
	$date1->duration( $date1->duration() - 1 );
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

no Mouse;

1;
