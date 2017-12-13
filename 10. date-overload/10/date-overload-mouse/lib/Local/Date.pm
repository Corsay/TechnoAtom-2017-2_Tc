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
	trigger => sub { $_[0]->clear_epoch(); },
);
has epoch => (
	is => 'rw',
	isa => 'Int',
	lazy_build => 1,
	trigger => sub {	# при изменении timestamp изменять соответственно day month year hours minutes seconds
		my ($self, $nv, $ov) = @_;
		$self->_get_date_comp() if (not defined $ov or $ov != $nv);
	},
);
has format => (
	is => 'rw',
	isa => 'Str',
	default => '%a %b %e %T %Y',
);

=head2
	Конструктор
=cut
around BUILDARGS => sub {
	my ($orig, $class, %p) = @_;
	if ( $p{epoch} ) {
		# инициализируем $p{day}, $p{month} и т.д.
		my @time = gmtime( $p{epoch} );
		$p{seconds} = $time[0];
		$p{minutes} = $time[1];
		$p{hours} = $time[2];
		$p{day} = $time[3];
		$p{month} = $time[4] + 1;
		$p{year} = 1900 + $time[5];
	} else {
		# проверяем наличие всех параметров (grep вернет количество !defined, если 0 -> нет ошибки)
		die "Not enought attributes 'day month year hours minutes seconds'\n" if grep { !defined $p{$_} }  qw/day month year hours minutes seconds/;
		# инициализируем $p{epoch} из $p{day}, $p{month} и т.д.
		my $time = timegm($p{seconds}, $p{minutes}, $p{hours}, $p{day}, $p{month} - 1, $p{year});
		$p{epoch} = $time;
	}
	return $class->$orig(%p);
};

=head2
	Коррекция параметров попадающих в аксессоры аттрибутов:
	* seconds	(0..59)
	* minutes	(0..59)
	* hours		(0..23)
	* day		(зависит от месяца)
	* month		(1..12)
=cut
after seconds => sub {
	my ($self, $sec) = @_;
	return unless $sec;
	# корректируем
	my $min = int($sec / 60);
	$sec -= $min * 60;
	#$self->seconds( $sec ) if $sec != $self->seconds();	# избегаем deep recursion (Будет чаще заходить сюда)
	$self->{seconds} = $sec;	# избегаем deep recursion
	$self->minutes( $self->minutes() + $min ) if $min;
};
after minutes => sub {
	my ($self, $min) = @_;
	return unless $min;
	# корректируем
	my $hours = int($min / 60);
	$min -= $hours * 60;
	$self->{minutes} = $min;	# избегаем deep recursion
	$self->hours( $self->hours() + $hours ) if $hours;
};
after hours => sub {
	my ($self, $hours) = @_;
	return unless $hours;
	# корректируем
	my $day = int($hours / 24);
	$hours -= $day * 24;
	$self->{hours} = $hours;	# избегаем deep recursion
	$self->day( $self->day() + $day ) if $day;
};
around day => sub {
	my $orig = shift;
	my $class = shift;
	return $class->$orig() unless @_;
	my $day = $class->{day};	# текущие дни
	$class->$orig(@_); # вызываем оригинальную функцию (которая изменит количество дней (в том числе на то, которое выходит за диапазон для текущего месяца))

	my $days = $class->day() - $day;	# разница в днях (стало - было)
	if ( $days ) {
		my $epoch = timegm($class->seconds(), $class->minutes(), $class->hours(), $day, $class->month() - 1, $class->year());	# получаем состояние epoch до изменения day
		$epoch += $days * 86400;	# прибавляем к epoch разницу в секундах
		my @time = gmtime($epoch);	# разбиваем полученный timestamp(epoch) на части
		$class->{day} = $time[3];	# получаем день
		$class->month($time[4] + 1) if ($class->{month} != $time[4] + 1);	# изменяем месяц
	}
};
after month => sub {
	my ($self, $month) = @_;
	return unless $month;
	# корректируем
	my $year = int($month / 12);
	$month -= $year * 12;
	$self->{month} = $month;	# избегаем deep recursion
	$self->year( $self->year() + $year ) if $year;
};

=head2
	Инициализируем epoch согласно текущей дате.
=cut
sub _build_epoch {
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
	$self->month($time[4] + 1);	# save month in form 1..12
	$self->year(1900 + $time[5]);
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
=cut
sub _digit_con {
	my ($self) = @_;
	return $self->epoch();
}

=head2
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

no Mouse;

1;
