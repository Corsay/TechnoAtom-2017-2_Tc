#!/usr/bin/env perl

use 5.016;
use utf8;
use open qw(:utf8 :std);
use Getopt::Long;

use AnyEvent::Socket;
use AnyEvent::Handle;
use Async::Chain;

use JSON::XS;
use Encode 'decode_utf8';
use DDP;
our $JSON = JSON::XS->new->canonical->utf8;

my $access_token = 'test';
my $port = 5599;
my $disco;
my $monitor;

GetOptions(
	'a|access_token=s' => \$access_token,
	'l|listen=i'       => \$port,
	'd|disco=s'        => \$disco,
	'm|monitor=s'      => \$monitor,
) and $access_token and $stream
or die <<DOC;
Usage:
	$0 -a access_token -l listenport -d ser.vice.dis.covery
DOC

my $type = 'dummy';

# Monitor notifier

{
	use Socket ':all';

	my $socket;
	if ($monitor) {
		my ($mhost,$mport) = split ':', $monitor, 2;
		$mport //= 5500;
		socket $socket, AF_INET, SOCK_DGRAM, IPPROTO_UDP or die "monitor socket failed: $!";
		my $addr = gethostbyname($mhost);
		my $sockaddr = sockaddr_in($mport, $addr);
		connect($socket, $sockaddr) or die "Assign udp socket failed: $!";
	}


	sub notify_monitor {
		my ($event_id) = @_;
		return unless $monitor;
		send($socket, $JSON->encode({
			id => $event_id,
			port => $port,
			type => $type,
		}), 0);
	}

}

my $last_id = 0;
sub gen_id {
	my $id = int(time*1000);
	++$id while $last_id >= $id;
	return $last_id = $id;
};

use Time::HiRes 'time';
my @events; # archive of events
my %connected_clients;

my $generate;$generate = sub {
	# Wait random time
	my $w;$w = AE::timer rand(5), 0, sub {
		undef $w;

		my $event_data = { test => 'data', time => time() };
		my $event = {
			id => gen_id(),
			data => $event_data,
		};
		say "Generated new dummy event $event->{id}";
		
		# 1. Store event in @events
		push @events, $event;
		
		# 2. Limit @events to 100 backlog
		shift @events if @events > 100;

		# 3. Deliver event to every connected client
		for my $client_event_cb (values %connected_clients) {
			$client_event_cb->($event);
		}

		# 4. Nonity monitor about new event
		notify_monitor($event->{id});


		# Call dummy generator again
		$generate->();
	};
};$generate->();

# Server code

my $server = tcp_server '0.0.0.0', $port, sub {
	my ($fh,$host,$port) = @_;

	my $h = AnyEvent::Handle->new(
		fh => $fh,
		timeout => 60, # read timeout
	);

	# String for identification of client in logs
	my $client = "$host:$port#".fileno($fh);

	say "Client $client connected";

	my $finish = sub {
		my $reason = shift;
		say "Client $client disconnected", ($reason ? ": $reason" : "");
		$h->destroy;
		# Unregister client
		delete $connected_clients{$client};
	};
	$h->on_error($finish);

	# First, we'd expect one line with id of event to send from
	# Empty line means "Send me all" (i.e. id = 0)

	$h->push_read(line => sub {
		my (undef, $line) = @_;
		if ($line =~ /^(\d*)$/) {
			my $from = $1 || 0;
			say "Client want events from $from";
			# $process->($1);

			# Callback will be called outsive with event data
			my $on_event = sub {
				my $event = shift;
				my $body = $JSON->encode($event)."\n";

				print "Deliver to $client: ".decode_utf8($body);
				$h->push_write($body);
			};

			# Resend old events to newly connected client

			for my $event (@events) {
				if ($event->{id} > $from) {
					$on_event->($event);
				}
			}

			# Register client's callback
			# Any event should be delivered to every client
			$connected_clients{$client} = $on_event;

			# Waiting for any other input
			# It will catch close of socket
			# Also disable timeout, allowing to be connected forever
			$h->timeout(0);
			$h->on_read(sub {
				# If there is some input, read it, and goodbye to client
				$h->push_read(line => sub {
					$h->push_write("Goodbye!\n");
					$finish->("by client input");
				})
			});
		}
		else {
			warn "Client $client sent malformed input: $line";
			$h->push_write("Malformed input\n");
			$finish->("Malformed input");
		}
	});

}, sub {
	shift;
	my ($host,$port) = @_;
	say "Started server on $host:$port";
	return 1024;
};


my $cv = AE::cv;

my $stop_watcher = AE::signal INT => sub {
	say "Stopping server";
	undef $server;
	$cv->send();
};

$cv->recv;
