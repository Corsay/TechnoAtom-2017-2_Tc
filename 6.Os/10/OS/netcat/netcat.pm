package netcat 1.00;

use strict;
use warnings;

use IO::Socket;

use Getopt::Long;
use Pod::Usage;

=head1 NAME

netcat - receives data from stdin and sends to connection (tcp/udp)

=head1 SYNOPSIS

Netcat [options] [destination] [port]

Options:

-help -> show help for netcat

-man -> shom man for netcat

-u -> Use UDP instead of the default option of TCP.

=cut

# Получаем опции в Хеш
my $param = {};
GetOptions ($param, 'help|?', 'man', 'u');

# Забираем из ARGV destination и port (целое число)
$param->{dest} = $ARGV[0];
if ($ARGV[1]) {
	$ARGV[1] =~ /(\d+)/;
	$param->{port} = $1;
}

# выводим help/man (нам обязательно должны передать адрес назначения и порт)
pod2usage(1) if ($param->{help} or not $param->{port});
pod2usage(-exitval => 0, -verbose => 2) if $param->{man};

# выбираем что использовать UDP или TCP
$param->{proto} = "tcp";
$param->{type} = SOCK_STREAM;
if ($param->{u}) {
	$param->{proto} = "udp";
	$param->{type} = SOCK_DGRAM;
}

# вызываем функцию отправки данных
WriteToDestByPort($param);

sub WriteToDestByPort {
	my ($param) = @_;

	my $socket = IO::Socket::INET->new(
		PeerAddr => $param->{dest},
		PeerPort => $param->{port},
		Proto => $param->{proto},
		Type => $param->{type},
	) or die "Can't connect to $param->{dest}:$param->{port} $/";

	my $pid;
	if ($pid = fork()) {
		# при завершении дочернего процесса закрываем STDIN 
		# при получении сигнала - этим - завершаем цикл while ( <STDIN> )
		local $SIG{CHLD} = sub { close(STDIN); };

		# в родительском читаем STDIN 
		while ( <STDIN> ) {
			eval { print $socket $_ };
		}
	}
	else {
		# редкий, но возможный случай, когда не смогли сделать fork()
		die "Cannot fork $!" unless defined $pid;
		# в дочернем выводим ответы с сервера
		while (<$socket>) {
			my $message = $_; 
			chomp($message);
			print "$message\n" if $message;
		}
		# завершаем дочерний процесс
		exit;
	}
	
	# отключаем соединение и закрываем сокет
	# тем самым заодно убивается дочерний процесс $pid
	# т.к. while (<$socket>) вернет 0
	shutdown ($socket, 2);
	close ($socket);
	# подождем пока дочерний процесс наверняка завершится
	waitpid($pid, 0);
} 

1;
