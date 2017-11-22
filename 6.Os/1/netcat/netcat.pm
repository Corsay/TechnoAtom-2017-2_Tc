package Netcat;

use strict;
use warnings;

use DDP;
use POSIX qw(:sys_wait_h); 
use IO::Socket;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '1.00';

=head1 NAME

netcat - receives data from stdin and sends to connection (tcp/udp)

=head1 SYNOPSIS

Netcat [options] [destination] [port]

Options:

-help -> show help for netcat

-man -> shom man for netcat

-u -> Use UDP instead of the default option of TCP.

-l port -> Used to specify that netcat should listen for an incoming connection rather than initiate a connection to a remote host.

=cut

# Получаем опции в Хеш
my $param = {};
GetOptions ($param, 'help|?', 'man', 'u');#, 'l=i');

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
#if ($param->{l})
#{
#	ReadFromPort($param);
#}
#else {
	WriteToDestByPort($param);
#}


sub is_interactive {
	return -t STDIN && -t STDOUT;
}

#my $do = 1;
#while( is_interactive() && $do ){
#	print "Tell me anything: ";
#	my $line = <STDIN>;
#	print "Echo: ".$line;
#	$do = 0 if $line eq "bye$/";
#}
#print "Goodbye$/";

sub WriteToDestByPort {
	my ($param) = @_;

	my $socket = IO::Socket::INET->new(
		PeerAddr => $param->{dest},
		PeerPort => $param->{port},
		Proto => $param->{proto},
		Type => SOCK_STREAM
	) or die "Can't connect to $param->{dest} $/";
	
	$socket->autoflush(1);
	local $| = 1;
	local $SIG{} = ;

	if (my $pid = fork()) {
		while ( <STDIN> ) {
			unless (my $exists = kill 0, $pid) {
				p $pid;
				p $exists; 
			}
			#my $line = <STDIN>;
			print $socket "$_";
		}

		waitpid($pid, 0);
	}
	else {
		die "Cannot fork $!" unless defined $pid;
		# обрабатываем ответы
		while (<$socket>) {
			my $message = $_; 
			chomp($message);
			print "Response: $message\n" if $message;
		}
		print "end\n";
		# завершаем дочерний процесс
		exit;
	}

	#my $rw = 1;
	#while ( is_interactive() ) {
	#	my $line = <STDIN>;
	#	print $socket "$line";
	#	my $message = <$socket> or <STDIN>; 
	#	chomp($message);
	#	print "$message\n" if $message;	
	#}
	
	close ($socket);
} 

sub ReadFromPort {
	my ($param) = @_;

	my $server = IO::Socket::INET->new(
		LocalPort => $param->{l},
		Proto => $param->{proto},
		Type => SOCK_STREAM,
		ReuseAddr => 1,
		Listen => 10
	) or die "Can't create server on port $param->{l} : $@ $/";
	
	while (my $client = $server->accept()) {
		$client->autoflush(1);
		my $message = <$client>; 
		chomp( $message );
		print $client "Echo: $message\n";
		close( $client );
		last if $message eq 'END';
	}

	close( $server );
} 

1;
