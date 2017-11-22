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
	my ($ip, $port, $msg) = @_;

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
		$h->push_write("$msg\n");

		# Read answer from server
		$h->push_read(line => sub {
			my (undef, $line) = @_;
			#say sprintf "[%s:%s] >>> %s", $peer->{ip}, $peer->{port}, $line;

			my $j;
			if (eval { $j = $JSON->decode($line) }) {
				p $j;
				# Goodbye to server
				$h->push_write("Goodbye!\n");

				my $post_id = $j->{data}->{event_id}->{post_id};
				my $owner_id = $j->{data}->{event_id}->{post_owner_id};
				my $post_event = $j->{data}->{event_type};	# post
				p $post_id;
				p $owner_id;
				p $post_event;

				###
				use URI;
				use AnyEvent::HTTP;
				my $access_token = "f04347f5f04347f5f04347f51cf01cd3b4ff043f04347f5aa4c168ddd893379b325f8a8";
				my $uri = URI->new("https://api.vk.com/method/likes.getList");

				my $cv = AE::cv; $cv->begin;

				$uri->query_form(
					access_token => $access_token,
					type => 'post',
					owner_id => $owner_id,
					item_id => $post_id,
				);
				http_request
					GET => $uri,
					sub {
						my ($body, $hdr) = @_;
						p $hdr;

						$cv->begin;

						if ($hdr->{Status} == 200) {
							my $js = $JSON->decode($body);

							p $js;
							
						}
						else {
							warn "$hdr->{Status} $hdr->{Reason}\n";
						}

						$cv->end;
						exit;
					}
				;

				$cv->end; $cv->recv;
				###


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

# задержка 5 минут -> 60 sec
# очередь push @array
# get from @array
# 
# update if time over
# post notify

connect_to("$ARGV[0]", 5502, "$ARGV[1]");

my $cv = AE::cv; #$cv->begin;

my $stop_watcher = AE::signal INT => sub {
	#$cv->begin;
	say "Stopping";
	$cv->send();
	#$cv->end;
};

#$cv->end; 
$cv->recv;
