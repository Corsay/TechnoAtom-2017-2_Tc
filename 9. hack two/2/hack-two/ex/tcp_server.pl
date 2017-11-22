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

my $port = 5508;

our $JSON = JSON::XS->new->canonical->utf8;

# @events -- events ready to send for subscribers
my @events;
my %connected_clients;

my $j = {
          'id' => '1511203340042',
          'data' => {
                      'event_type' => 'post',
                      'creation_time' => 1511203338,
                      'author' => {
                                    'id' => '-48848938',
                                    'author_url' => 'https://vk.com/club48848938'
                                  },
                      'attachments' => [
                                         {
                                           'link' => {
                                                       'url' => 'http://vsenovosti24.ru/rossiyanin-reshil-vlozhit-svoi-pensionnye-nakopleniya-v-kriptovalyutu-i-napisal-ob-etom-peticiyu-v-pfr/',
                                                       'description' => "https://www.change.org/p/\x{432}\x{43b}\x{43e}\x{436}\x{435}\x{43d}\x{438}\x{435}-\x{43d}\x{430}\x{43a}\x{43e}\x{43f}\x{43b}\x{435}\x{43d}\x{438}\x{439}-\x{433}\x{440}\x{430}\x{436}\x{434}\x{430}\x{43d}-\x{440}\x{43e}\x{441}\x{441}\x{438}\x{438}-\x{432}-\x{43f}\x{435}\x{43d}\x{441}\x{438}\x{43e}\x{43d}\x{43d}\x{43e}\x{43c}-\x{444}\x{43e}\x{43d}\x{434}\x{435}-\x{432}-\x{43a}\x{440}\x{438}\x{43f}\x{442}\x{43e}\x{432}\x{430}\x{43b}\x{44e}\x{442}\x{443} \x{423}\x{432}\x{430}\x{436}\x{430}\x{435}\x{43c}\x{44b}\x{439} \x{410}\x{43d}\x{442}\x{43e}\x{43d} \x{412}\x{438}\x{43a}\x{442}\x{43e}\x{440}\x{43e}\x{432}\x{438}\x{447}! \x{421}\x{43e}\x{43e}\x{431}\x{449}\x{430}\x{44e} \x{412}\x{430}\x{43c}, \x{447}\x{442}\x{43e} \x{441}\x{443}\x{449}\x{435}\x{441}\x{442}\x{432}\x{443}\x{435}\x{442} \x{43d}\x{430}\x{434}\x{451}\x{436}\x{43d}\x{44b}\x{439} \x{441}\x{43f}\x{43e}\x{441}\x{43e}\x{431} \x{443}\x{43c}\x{43d}\x{43e}\x{436}\x{438}\x{442}\x{44c} \x{43d}\x{430}\x{43a}\x{43e}\x{43f}\x{43b}\x{435}\x{43d}\x{438}\x{44f} \x{43c}\x{438}\x{43b}\x{43b}\x{438}\x{43e}\x{43d}\x{43e}\x{432} \x{440}\x{43e}\x{441}\x{441}\x{438}\x{44f}\x{43d} \x{438}, \x{43d}\x{430}\x{43a}\x{43e}\x{43d}\x{435}\x{446}, \x{43e}\x{431}\x{435}\x{441}\x{43f}\x{435}\x{447}\x{438}\x{442}\x{44c} \x{438}\x{445} \x{434}\x{43e}\x{441}\x{442}\x{43e}\x{439}\x{43d}\x{44b}\x{439} \x{43e}\x{442}\x{434}\x{44b}\x{445} \x{437}\x{430} \x{43c}\x{43d}\x{43e}\x{433}\x{43e}\x{43b}\x{435}\x{442}\x{43d}\x{438}\x{439} \x{442}\x{440}\x{443}\x{434}. \x{41d}\x{430}\x{43f}\x{43e}\x{43c}\x{43d}\x{44e}, \x{447}\x{442}\x{43e} \x{432} 2016 \x{433}\x{43e}\x{434}\x{443} \x{43d}\x{435} \x{431}\x{44b}\x{43b}\x{430} \x{43f}\x{440}\x{43e}\x{432}\x{435}\x{434}\x{435}\x{43d}\x{430} \x{438}\x{43d}\x{434}\x{435}\x{43a}\x{441}\x{430}\x{446}\x{438}\x{44f} \x{43f}\x{435}\x{43d}\x{441}\x{438}\x{439}, \x{41f}\x{424} \x{420}\x{424} \x{432}\x{44b}\x{43f}\x{43b}\x{430}\x{442}\x{438}\x{43b} \x{43a}\x{430}\x{436}\x{434}\x{43e}\x{43c}\x{443} \x{43f}\x{435}\x{43d}\x{441}\x{438}\x{43e}\x{43d}\x{435}\x{440}\x{443} \x{43e}\x{434}\x{438}\x{43d} \x{440}\x{430}\x{437} \x{43f}\x{43e} 5000 (\x{43f}\x{44f}\x{442}\x{44c} \x{442}\x{44b}\x{441}\x{44f}\x{447}) \x{440}\x{443}\x{431}\x{43b}\x{435}\x{439}. \x{414}\x{43e} 2016 \x{433}\x{43e}\x{434}\x{430} \x{432} \x{441}\x{43e}\x{43e}\x{442}\x{432}\x{435}\x{442}\x{441}\x{442}\x{432}\x{438}\x{435} \x{441} \x{437}\x{430}\x{43a}\x{43e}\x{43d}\x{43e}\x{434}\x{430}\x{442}\x{435}\x{43b}\x{44c}\x{441}\x{442}\x{432}\x{43e}\x{43c} \x{443}\x{432}\x{435}\x{43b}\x{438}\x{447}\x{435}\x{43d}\x{438}\x{435} \x{43f}\x{435}\x{43d}\x{441}\x{438}\x{439} \x{43f}\x{440}\x{43e}\x{438}\x{441}\x{445}\x{43e}\x{434}\x{438}\x{43b}\x{43e} Read more",
                                                       'caption' => 'vsenovosti24.ru',
                                                       'title' => "\x{420}\x{43e}\x{441}\x{441}\x{438}\x{44f}\x{43d}\x{438}\x{43d} \x{440}\x{435}\x{448}\x{438}\x{43b} \x{432}\x{43b}\x{43e}\x{436}\x{438}\x{442}\x{44c} \x{441}\x{432}\x{43e}\x{438} \x{43f}\x{435}\x{43d}\x{441}\x{438}\x{43e}\x{43d}\x{43d}\x{44b}\x{435} \x{43d}\x{430}\x{43a}\x{43e}\x{43f}\x{43b}\x{435}\x{43d}\x{438}\x{44f} \x{432} \x{43a}\x{440}\x{438}\x{43f}\x{442}\x{43e}\x{432}\x{430}\x{43b}\x{44e}\x{442}\x{443} \x{438} \x{43d}\x{430}\x{43f}\x{438}\x{441}\x{430}\x{43b} \x{43e}\x{431} \x{44d}\x{442}\x{43e}\x{43c} \x{43f}\x{435}\x{442}\x{438}\x{446}\x{438}\x{44e} \x{432} \x{41f}\x{424}\x{420}",
                                                       'is_external' => 0
                                                     },
                                           'type' => 'link'
                                         }
                                       ],
                      'tags' => [
                                  '4'
                                ],
                      'action' => 'new',
                      'event_id' => {
                                      'post_owner_id' => -48848938,
                                      'post_id' => '3574'
                                    },
                      'event_url' => 'https://vk.com/wall-48848938_3574',
                      'text' => "\x{420}\x{43e}\x{441}\x{441}\x{438}\x{44f}\x{43d}\x{438}\x{43d} \x{440}\x{435}\x{448}\x{438}\x{43b} \x{432}\x{43b}\x{43e}\x{436}\x{438}\x{442}\x{44c} \x{441}\x{432}\x{43e}\x{438} \x{43f}\x{435}\x{43d}\x{441}\x{438}\x{43e}\x{43d}\x{43d}\x{44b}\x{435} \x{43d}\x{430}\x{43a}\x{43e}\x{43f}\x{43b}\x{435}\x{43d}\x{438}\x{44f} \x{432} \x{43a}\x{440}\x{438}\x{43f}\x{442}\x{43e}\x{432}\x{430}\x{43b}\x{44e}\x{442}\x{443} \x{438} \x{43d}\x{430}\x{43f}\x{438}\x{441}\x{430}\x{43b} \x{43e}\x{431} \x{44d}\x{442}\x{43e}\x{43c} \x{43f}\x{435}\x{442}\x{438}\x{446}\x{438}\x{44e} \x{432} \x{41f}\x{424}\x{420}"
                    }
        };

p $j->{id};
#p $j;

push @events, $j;

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

