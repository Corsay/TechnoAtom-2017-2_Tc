#!/usr/bin/env perl

use strict;

use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;

use feature 'say';

use DDP;
use Socket ':all';

my $port = 5000;
GetOptions(
	'l|listen=i'       => \$port,
) and $port
or die <<DOC;
Usage:
	$0 -l listenport
DOC

sub udp_server {
	my ($lport, $on_client_cb) = @_;

	# Create Data-Gram socket
	socket my $s, AF_INET, SOCK_DGRAM, IPPROTO_UDP or die "socket: $!";
	# Reuse addr
	setsockopt $s, SOL_SOCKET, SO_REUSEADDR, 1 or die "sso: $!";

	# Bind to listen port
	bind $s, sockaddr_in($lport, INADDR_ANY) or die "bind: $!";

	# Get ip:port on which we've binded
	my ($port, $addr) = sockaddr_in(getsockname($s));
	say "Listening for events on udp://".inet_ntoa($addr).":".$port;

	# Set accept socket non-blocking
	AnyEvent::Util::fh_nonblocking $s, 1;

	my $rw; $rw = AE::io $s, 0, sub { $rw or return;
		while(my $peer = recv($s, my $msg, 4096, 0)) {
			my ($port, $addr) = sockaddr_in($peer);
			my $ip = inet_ntoa($addr);
			say "[$ip:$port] >>> $msg";

			$on_client_cb->({
				ip   => $ip,
				port => $port,
				msg  => $msg
			});
		}
	};
}

use JSON::XS;
our $JSON = JSON::XS->new->canonical->utf8;

# Start server on port 5000 and
# transmit to him on_client_cb

my $server = udp_server($port, sub {
	my ($args) = @_;

	my $data;
	if (eval { $data = $JSON->decode($args->{msg}) }) {
		if ($data->{port} and $data->{type}) {
			$data->{ip} = $args->{ip};
			$data->{id} = $data->{ip}.':'.$data->{port};
		}
		p $data;
	} else {
		my $err = "Malformed data from ".$args->{ip}." (no ". join(', ', grep !exists $data->{$_}, qw(port type id))."): ".$args->{msg};
		say "$err";
	}
});

my $cv = AE::cv;

my $stop_watcher = AE::signal INT => sub {
	say "Stopping server";
	undef $server;
	$cv->send();
};

$cv->recv;
