#!/usr/bin/env perl

use 5.016;
use utf8;
use open qw(:utf8 :std);
use AnyEvent::HTTP;
use DDP;
use EV;
use URI;
use Async::Chain;
use JSON::XS;
our $JSON = JSON::XS->new->utf8;

my $access_token = ...;
die "Need post ids\n" unless @ARGV;

my $uri = URI->new("https://api.vk.com/method/wall.getById");
$uri->query_form(
	access_token => $access_token,
	posts => join (",",@ARGV),
	copy_history_depth => 1,
	extended => 0,
	# fields => 'photo_100,nickname,screen_name,career',
);
say $uri;
http_request
	GET => "$uri",

	sub {
		if ($_[1]{Status} == 200) {
			my $j = $JSON->decode($_[0]);
			p $j;
		}
		else {
			warn "$_[1]{Status} $_[1]{Reason}\n";
		}
		exit;
	}
;

EV::loop;
