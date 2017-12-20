package YourPackage 1.00;

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

=head1 NAME

  Prog Name - my program general info.

=head1 SYNOPSIS

  Prog [options]

  Options:
    -help				show help for prog
    -man				show man for prog

  Commands:
    com1				com1 description
    com2				com2 description
    com3				com3 description
    com4				com4 description
    com5				com5 description

=cut

# -ru = -r -u
# --ru = -ru
Getopt::Long::Configure("bundling");

# Получаем опции в Хеш
my $param = {};
GetOptions ( 
	$param, 'help|?', 'man', # и тд, одиночные параметры
	'user=i' => sub { push @{ $param->{users} }, $_[1]; }, # и тд. множественные аргументы (массив/хэш)
) or die "some msg\n";	# пример ошибки, можно тут использовать и функцию/или еще что-то допустим "or do { commands; };" 

# проверяем параметры
use DDP;
p $param;

# (-verbose => 2) выводит все head (в случае man)
=head2 CodeComment
	some comment which will shown in man
=cut
# выводим help/man 
pod2usage(-exitval => "NOEXIT") if $param->{help};	# help без выхода из работы
#print "in after help with 'NOEXIT'\n";
pod2usage(-exitval => "NOEXIT", -verbose => 2) if $param->{man};	# man без выхода из работы
#print "in after man with 'NOEXIT'\n";

pod2usage() if $param->{help};
#print "in after help with 'EXIT' - error if you see this))\n";
pod2usage(-verbose => 1) if $param->{man};
#print "in after man with 'EXIT' - error if you see this))\n";
