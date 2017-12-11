package Local::Date;

use parent Local::Object;

use Time::Local;
use POSIX qw(strftime);

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
	Сеттеры, геттеры,
	оверлоад (перегрузка)
=cut
use Class::XSAccessor
	setters => [ 'format' ],	# setter для формата вывода даты в строковом контексте
	getters => [ 'day', 'month', 'year', 'hours', 'minutes', 'seconds', 'epoch' ];	# В любой момент времени должна быть возможность обратиться как к компонентам времени, как к timestamp, для получения их текущего значения.

use overload
	# контексты
	'""' => '_string_con',	# строковый
	'0+' => '_digit_con',	# числовой
	# сложение/вычитание
	#'+' => '_add',
	'-' => '_sub',
	# Сложение/вычитание с присваиванием
	'+=' => '_add_assign',
	'-=' => '_sub_assign',
	# операции инкремента/декремента
	'++' => '_inc',
	'--' => '_dec',
	# операции сравнения
	'<' => '_less',
	'<=' => '_less_equal',
	'>' => '_more',
	'>=' => '_more_equal',
	'==' => '_equal',
	'!=' => '_not_equal',
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
	my @time = gmtime($self->{epoch});
	$self->{seconds} = $time[0];
	$self->{minutes} = $time[1];
	$self->{hours} = $time[2];
	$self->{day} = $time[3];
	$self->{month} = $time[4];
	$self->{year} = 1900 + $time[5];

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
=cut
sub _digit_con {
	my ($self) = @_;
	return $self->{epoch};
}

# сложение/вычитание
# Операция должна прибавлять указанное количество секунд к объекту.
sub _add {
	my ($date1, $date2) = @_;

	#
	#if ( $date2->isa('Local::Date') ) {

	#}

	return 1;
}
sub _sub {
	my ($date1, $date2) = @_;

	return 1;
}

# Сложение/вычитание с присваиванием
sub _add_assign {

}
sub _sub_assign {

}
# операции инкремента/декремента
sub _inc {

}
sub _dec {

}
# операции сравнения
sub _less {

}
sub _less_equal {

}
sub _more {

}
sub _more_equal {

}
sub _equal {

}
sub _not_equal {

}
sub _sort_digit {

}


1;
