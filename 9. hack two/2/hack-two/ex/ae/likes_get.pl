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

my $uri = URI->new("https://api.vk.com/method/likes.getList");
$uri->query_form(
	access_token => $access_token,
	type => 'sitepage',
	item_id => $ARGV[0],
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
