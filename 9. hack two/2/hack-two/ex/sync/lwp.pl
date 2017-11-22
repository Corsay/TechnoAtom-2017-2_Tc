#!/usr/bin/env perl

use 5.016;
use utf8;
use LWP::UserAgent;
use DDP;
use URI;
use JSON::XS;
our $JSON = JSON::XS->new->utf8;

my $access_token = ...;
my ($endpoint,$key);

my $auth_uri = URI->new("https://api.vk.com/method/streaming.getServerUrl");
$auth_uri->query_form(access_token => $access_token, v => "5.64");

my $ua = LWP::UserAgent->new();
$ua->timeout(3);
my $res = $ua->get($auth_uri);
die $res->status_line unless $res->is_success;
my $j = $JSON->decode($res->decoded_content);
my ($endpoint,$key) = ($j->{response}{endpoint}, $j->{response}{key});

my $rules_uri = URI->new("https://$endpoint/rules?key=$key");

my $res = $ua->get($rules_uri);
die $res->status_line unless $res->is_success;
my $j = $JSON->decode($res->decoded_content);
for my $rule (@{ $j->{rules} }) {
	say "Deleting rule $rule->{tag}#$rule->{value}";
	$res = $ua->delete($rules_uri, Content => $JSON->encode({tag => $rule->{tag}}));
	die $res->status_line unless $res->is_success;
}
# p $j



# p $data;
__END__



chain
sub {
	my $next = shift;
	http_request
		GET => "$auth_uri",
		sub {
			p @_;
			if ($_[1]{Status} == 200) {
				my $j = $JSON->decode($_[0]);
				p $j;
				($endpoint,$key) = ($j->{response}{endpoint}, $j->{response}{key});
				$next->();
			}
			else {
				warn "$_[1]{Status} $_[1]{Reason}\n";
				exit;
			}
		}
	;
},
sub {
	my $next = shift;
	my $rules_uri = URI->new("https://$endpoint/rules?key=$key");
	http_request
		GET => "$rules_uri",
		sub {
			p @_;
			$next->();
		}
},
sub {
	my $next = shift;
	my $rules_uri = URI->new("https://$endpoint/rules?key=$key");
	# my $data = $JSON->encode( { rule => { tag => "4", value => "и" } } )."\n";
	# my $data = $JSON->encode( { rule => { tag => "5", value => '"#осень"' } } )."\n";
	# my $data = $JSON->encode( { rule => { tag => "6", value => '"#безфильтра"' } } )."\n";
	my $data = $JSON->encode( { rule => { tag => "7", value => '"порно"' } } )."\n";
	p $data;
	http_request
		POST => "$rules_uri",
		body => $data,
		headers => { 'content-type' => 'application/json' },
		sub {
			p @_;
			$next->();
		}
},
sub {
	my $next = shift;
	my $stream_uri = URI->new("https://$endpoint/stream?key=$key");
	my $client = AnyEvent::WebSocket::Client->new();
	$client->connect("wss://$endpoint/stream?key=$key")->cb(sub {
		warn "@_";
		my $connection = shift->recv;
		$connection->on(each_message => sub {
			p @_;
		});
		$connection->on(finish => sub {
			warn "fin";
		});

	});
	# http_request
	# 	GET => "$stream_uri",
	# 	headers => {

	# 	},
	# 	on_headers => sub {
	# 		p @_;
	# 	},
	# 	sub {
	# 		p @_;
	# 	}
},
;

EV::loop;
