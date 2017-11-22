#!/usr/bin/env perl

use 5.016;
use utf8;
use DDP;
use JSON::XS;
our $JSON = JSON::XS->new->canonical->utf8;

use AnyEvent::Socket;
use AnyEvent::Handle;

my %connections;

sub connect_to {
	my ($ip, $port) = @_;

	my $peer = {
		ip => $ip,
		port => $port,
		id => $ip.':'.$port,
	};

	# Declare finish-callback to destroy handle
	my $finish = sub {
		my ($reason) = @_;
		my $h = delete $connections{$peer->{id}};

		say AE::now()." "."Connecion to ".$peer->{id}." closed", ($reason ? ": $reason" : "");
		$h->destroy;
	};

	tcp_connect $peer->{ip}, $peer->{port}, sub {
		my $fh = shift;
		unless ($fh) {
			my $err = "$!";
			say sprintf "Failed to connect to %s with '%s'", $peer->{id}, $err;	# то куда мы не присоединились
			return;
		}

		say sprintf "Connection established to %s", $peer->{id};	# то куда мы присоединились

		my $h = AnyEvent::Handle->new(fh => $fh);

		# Error callback for any errors on socket
		$h->on_error(sub {
			my (undef, undef, $err) = @_;
			$finish->($err);
		});

		$connections{$peer->{id}} = $h;

		# Send empty message
		$h->push_write("0\n");

		# Read answer from server
		$h->push_read(line => sub {
			my (undef, $line) = @_;
			say sprintf "[%s:%s] >>> %s", $peer->{ip}, $peer->{port}, $line;

			my $j;
			if (eval { $j = $JSON->decode($line) }) {
				p $j;
				# Goodbye to server
				$h->push_write("Goodbye!\n");

				# When write buffer becomes empty
				# Close connection
				$h->on_drain(sub {
					$finish->("by client input");
				});
			} else {
				warn "Server ".$peer->{id}." returned malformed input: $line";
				$h->push_write("Malformed input\n");
				$finish->("Malformed input");
			}

		});

		$h->on_read(sub {
			my ($h, undef, $err) = @_;
			$finish->($err);
		});
	}, sub { 3 }; # tcp_connect
	return;
}

connect_to("$ARGV[0]", 5502);

my $cv = AE::cv;

my $stop_watcher = AE::signal INT => sub {
	say "Stopping";
	$cv->send();
};

$cv->recv;
