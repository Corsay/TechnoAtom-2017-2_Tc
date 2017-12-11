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
	геттеры,
	оверлоад (перегрузка)
=cut
use Class::XSAccessor
	getters => [ 'days', 'hours', 'minutes', 'seconds', 'duration' ];	# В любой момент времени должна быть возможность обратиться как к компонентам длительности интеревала, так и к длительности в секундах, для получения их текущего значения.

use overload
	# контексты
	'""' => '_string_con',	# строковый
	'0+' => '_digit_con',	# числовой
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
	$self->{days} = int($duration / 60 / 60 / 24);	$duration %= 60 * 60 * 24;
	$self->{hours} = int($duration / 60 / 60);	$duration %= 60 * 60;
	$self->{minutes} = int($duration / 60);	$duration %= 60;
	$self->{seconds} = int($duration);

	return;
}


=head2
	Строковый контекст.
	* Интервал должен преобразовываться в строку вида `"1524 days, 20 hours, 0 minutes, 14 seconds"`.
=cut
sub _string_con {
	my ($self) = @_;
	return $self->{days} . " days, " . $self->{hours} . " hours, " . $self->{minutes} . " minutes, " . $self->{seconds} . " seconds";
}

=head2
	Числовой контекст.
	* Интервал должен преобразовываться в число равное длительности интервала в секундах.
=cut
sub _digit_con {
	my ($self) = @_;
	return $self->{duration};
}

1;
