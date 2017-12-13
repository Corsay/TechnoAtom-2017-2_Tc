package Local::Date::Interval;

use Mouse;

=head2
	Аттрибуты
=cut
has [qw(days hours minutes seconds)] => (
	is => 'rw',
	isa => 'Int',
	trigger => sub {
		my ($self) = @_;
		$self->_init_by_duration_comp if (defined $self->days() and defined $self->hours() and defined $self->minutes() and defined $self->seconds());
	},
);
has duration => (
	is => 'rw',
	isa => 'Int',
	builder => '_init_by_duration_comp',
	trigger => sub {	# при изменении duration изменять соответственно days hours minutes seconds
		my ($self, $nv, $ov) = @_;
		$self->_get_duration_comp() if (not defined $ov or $ov != $nv);
	},
);

=head2
	Инициализируем duration (сразу) согласно переданным компонентам длительности интервала.
=cut
sub _init_by_duration_comp {
	my ($self) = @_;
	# убиваем если хотябы один параметр(days hours minutes seconds) не был передан
	die "Not enought attributes 'days hours minutes seconds'\n" if (not defined $self->seconds() or not defined $self->minutes() or not defined $self->hours() or not defined $self->days());
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
	'0+' => '_digit_con',	# числовой контекст
	# сложение/вычитание
	'+' => '_add',
	'-' => '_subtract',
	# Сложение/вычитание с присваиванием
	'+=' => '_add_assign',
	'-=' => '_sub_assign',
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
=cut
sub _digit_con {
	my ($self) = @_;
	return $self->duration();
}

=head2
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

no Mouse;

1;
