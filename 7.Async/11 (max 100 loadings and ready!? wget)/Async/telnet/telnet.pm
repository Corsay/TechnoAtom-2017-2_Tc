package telnet 1.00;

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

=head1 NAME

=head1 SYNOPSIS

=cut

# Получаем опции в Хеш
my $param = {};
GetOptions ($param, 'help|?', 'man');

# выводим help/man
pod2usage(1) if ($param->{help});
pod2usage(-exitval => 0, -verbose => 2) if $param->{man};

1;
