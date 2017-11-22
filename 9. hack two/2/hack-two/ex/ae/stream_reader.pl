#!/usr/bin/env perl

use 5.016;
use utf8;
use open qw(:utf8 :std);
use AnyEvent::HTTP;
use DDP;
use EV;
use URI;
use Async::Chain;
use Getopt::Long;
use JSON::XS;
our $JSON = JSON::XS->new->utf8;
use AnyEvent::Socket;
use AnyEvent::Handle;
use HTTP::Easy::Headers;
use Mojo::UserAgent;
use Time::HiRes 'time';
use Encode 'decode_utf8';
my $access_token;

GetOptions(
	'a|access_token=s' => \$access_token,
) and $access_token or die "Usage:\n\t$0 -a access_token\n";

our @EVENTS;
our %WATCHERS;

my $auth_uri = URI->new("https://api.vk.com/method/streaming.getServerUrl");
$auth_uri->query_form(access_token => $access_token, v => "5.64");
my $cv = AE::cv;
http_request
	GET => "$auth_uri",
	sub {
		if ($_[1]{Status} == 200) {
			my $j = $JSON->decode($_[0]);
			# p $j;
			$cv->send($j->{response}{endpoint}, $j->{response}{key});
		}
		else {
			warn "$_[1]{Status} $_[1]{Reason}\n";
			exit;
		}
	}
;
my ($endpoint, $key) = $cv->recv;


say "Got key $key for $endpoint";


# binmode STDOUT, ':utf8';

my $ua = Mojo::UserAgent->new();
$ua->websocket("wss://$endpoint/stream?key=$key", sub {
	my ($ua, $tx) = @_;
	unless ($tx->is_websocket) {
		say 'WebSocket handshake failed!';
		p $tx->res->body;
		exit;
	};
	say "Connected";

	$tx->on(
		message => sub {
			shift;
			my $raw = shift;
			utf8::encode $raw if utf8::is_utf8 $raw;
			my $data = $JSON->decode($raw);
			if ($data->{code} == 100) {
				my $event = $data->{event};
				my $my_event = { id => int(time*100), event => $event };
				push @EVENTS, $my_event;
				shift @EVENTS while @EVENTS > 100;
				for (values %WATCHERS) {
					$_->($my_event);
				}
				if ($event->{event_type} eq 'post') {
					if ($event->{action} eq 'new') {
						say "#$event->{event_id}{post_id} ($event->{event_url}) by $event->{author}{id} ".substr($event->{text},0,127);
						return;
					}
				}
				elsif ($event->{event_type} eq 'comment') {
					if ($event->{action} eq 'new') {
						say "#$event->{event_id}{comment_id}->$event->{event_id}{post_id} ($event->{event_url}) by $event->{author}{id} $event->{text}";
						return;
					}
				}
				elsif ($event->{event_type} eq 'share') {
					if ($event->{action} eq 'new') {
						say "#$event->{event_id}{post_id}:$event->{event_id}{shared_post_id} ($event->{event_url}) by $event->{author}{id} $event->{text}";
						return;
					}
				}
			}
			p $data;
		},
	);
});

# Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
EV::loop;
