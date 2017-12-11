package Local::Date::Interval;

use parent Local::Date;

=head1 NAME
	Local::Date::Interval - объект временного интревала
=head1 VERSION
	Version 1.00
=cut
our $VERSION = '1.00';
=head1 SYNOPSIS
=cut

# Инициализация объекта класса Local::Date::Interval
# Определяет какой из конструкторов объекта вызвать (по компонентам длительности (дни, часы, минуты, секунды) и по длительности в секундах)
sub init {
	my ($self, $params) = @_;

	return;
}

1;
