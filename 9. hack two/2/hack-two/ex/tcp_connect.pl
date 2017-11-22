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

				if ($post_event eq 'post') {
					### likes_get
					use URI;
					use AnyEvent::HTTP;
					#my $access_token = "f04347f5f04347f5f04347f51cf01cd3b4ff043f04347f5aa4c168ddd893379b325f8a8";
					my $uri = URI->new("https://api.vk.com/method/likes.getList");

					my $cv = AE::cv; $cv->begin;

					$uri->query_form(
						#access_token => $access_token,
						type => 'post',
						owner_id => $owner_id,
						item_id => $post_id,
					);
					http_request
						GET => $uri,
						sub {
							my ($body, $hdr) = @_;
							#p $hdr;

							$cv->begin;

							if ($hdr->{Status} == 200) {
								my $js = $JSON->decode($body);

								#p $js;
								#p $js->{response}->{count};
								my $likes_count = $js->{response}->{count};
								
								$j->{data}->{event_id}->{likes_count} = $likes_count;
								#use Data::Dumper;
								#p $j;
								#print Dumper($j);

								### UDP client
								use Socket ':all';
								socket my $s, AF_INET, SOCK_DGRAM, IPPROTO_UDP or die "socket: $!";

								my $host = '100.100.145.201';#'localhost'; 
								my $port = 5500;
								my $addr = gethostbyname $host;
								my $sockaddr = sockaddr_in($port, $addr);

								my $event_id = 1511203340042;#$post_id; #int(time*1000);
								my $event_body = $JSON->encode({
									id => "$event_id",
									port => 5508,
									type => 'stream',
								});

								send($s, $event_body, 0, $sockaddr);
								p $j;
								###

								###
=head
								my @events;
								my %connected_clients;

								$j->{data}->{event_id}->{likes_count} = $likes_count;
								p $j;
								push @events, $j;

								my $server = tcp_server '0.0.0.0', '5508', sub {
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
=cut
								
								###

								### TCP push
=head
								use IO::Socket;
								my $socket = IO::Socket::INET->new(
									PeerAddr => $param->{dest},
									PeerPort => $param->{port},
									Proto => $param->{proto},
									Type => SOCK_STREAM,
								) or die "Can't connect to $param->{dest}:$param->{port} $/";
								socket my $s2, AF_INET, SOCK_STREAM, IPPROTO_TCP or die "socket: $!";
 								
 								my $serv_host = '100.100.145.201';
 								my $serv_port = 5500;
								my $serv_addr = gethostbyname $serv_host;
								my $serv_sockaddr = sockaddr_in($serv_port, $serv_addr);

								#$j->{data}->{event_id}->{likes_count} = $likes_count;
								#p $j;
								my $serv_event_body = $JSON->encode($j);

								send($s2, $serv_event_body, 0, $serv_sockaddr);
=cut
								###

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
				}
				else {
					say "Not a post: $post_event";
				}


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

connect_to("100.100.148.229", 5502, "0");

my $cv = AE::cv; #$cv->begin;

my $stop_watcher = AE::signal INT => sub {
	#$cv->begin;
	say "Stopping";
	$cv->send();
	#$cv->end;
};

#$cv->end; 
$cv->recv;
