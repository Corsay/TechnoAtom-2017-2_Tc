package Netcat 1.00;

use strict;
use warnings;

use DDP;
use POSIX qw(:sys_wait_h);
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
pod2usage(1) if ($param->{help} or (not $param->{port} and not $param->{l}));
pod2usage(-exitval => 0, -verbose => 2) if $param->{man};

# выбираем что использовать UDP или TCP
$param->{proto} = "tcp";
if ($param->{u}) {
	$param->{proto} = "udp";
}

# вызываем функцию отправки данных
WriteToDestByPort($param);

sub WriteToDestByPort {
	my ($param) = @_;

	my $socket = IO::Socket::INET->new(
		PeerAddr => $param->{dest},
		PeerPort => $param->{port},
		Proto => $param->{proto},
		Type => SOCK_STREAM
	) or die "Can't connect to $param->{dest} $/";
	
	#local $SIG{CHLD} = sub {
	#	while( my $pid = waitpid(-1, 0)){
	#		last if $pid == -1;
	#		if( WIFEXITED($?) ){
	#			my $status = WEXITSTATUS($?);
	#			print "$pid exit with status $status $/";
	#		}
	#		else {
	#			print "Process $pid sleep $/";
	#		}
	#	}
	#};

	#my $pid;
	if (my $pid = fork()) {
		# в родительском читаем STDIN
		while ( <STDIN> ) {
			last unless (kill 0, $pid);
			print $socket $_;
		}
	}
	else {
		# редкий, но возможный случай, когда не смогли сделать fork()
		die "Cannot fork $!" unless defined $pid;
		# в дочернем выводим ответы с сервера
		while (<$socket>) {
			my $message = $_; 
			chomp($message);
			print "Response: $message\n" if $message;
		}
		# завершаем дочерний процесс
		exit;
	}
	
	# отключаем соединение и закрываем сокет
	# тем самым заодно убиваем дочерний процесс $pid
	shutdown ($socket, 2);
	close ($socket);
	#waitpid($pid, 1); # он тут не нужен, проверено, дочерний процесс ляжет точно)
} 

1;
