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
@ARGV = grep { $_ > 0 } @ARGV;
die "Need positive user ids\n" unless @ARGV;

my $uri = URI->new("https://api.vk.com/method/users.get");
$uri->query_form(
	access_token => $access_token,
	user_ids => join (",",@ARGV),
	fields => 'photo_100,name,nickname,screen_name,home_town,city',
);
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
