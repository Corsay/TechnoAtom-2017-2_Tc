#!/usr/bin/env perl

use 5.016;
use utf8;
use open qw(:utf8 :std);
use Getopt::Long;

use AnyEvent::Socket;
use AnyEvent::Handle;
use Time::HiRes qw(time);
use Time::Moment;
use POSIX 'strftime';

use JSON::XS;
use Encode 'decode_utf8';
use DDP;

my $port = 6000;

our $JSON = JSON::XS->new->canonical->utf8;

# @events -- events ready to send for subscribers
my @events;
my %connected_clients;

my $server = tcp_server '0.0.0.0', $port, sub {
	my ($fh,$host,$port) = @_;

	my $h = AnyEvent::Handle->new(
		fh => $fh,
		timeout => 60, # read timeout
	);

	# String for identification of client in logs
	state $client_seq;
	my $client = "$host:$port#".(++$client_seq);

	say "Client $client connected (".fileno($fh).")";

	my $finish = sub {
		my $reason = shift;
		# Unregister client
		delete $connected_clients{$client};

		say AE::now()." "."Client $client disconnected", ($reason ? ": $reason" : "");
		$h->destroy;
	};

	$h->on_error(sub {
		my ($h, $err, undef) = @_;
		$finish->($err);
	});

	# First, we'd expect one line with id of event to send from
	# Empty line means "Send me all" (i.e. id = 0)

	$h->push_read(line => sub {
		my (undef, $line) = @_;
		if ($line =~ /^(\d*)$/) {
			my $from = $1 || 0;
			say AE::now()." "."Client $client want events from $from";
			# $process->($1);

			# Callback will be called outsive with event data
			my $on_event = sub {
				UNIVERSAL::isa($h,'AnyEvent::Handle::destroyed') and return;
				my $event = shift;
				my $body = $JSON->encode($event)."\n";

				say AE::now()." "."Deliver to $client $event->{id} ($h)";
				# print "Deliver to $client: ".decode_utf8($body);
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
				$_[0]->push_read(line => sub {
					$_[0]->push_write("Goodbye!\n");
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

