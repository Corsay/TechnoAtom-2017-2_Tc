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
	copy_history_depth => 0,
	extended => 1,
	fields => 'name,photo_50,photo_100,nickname,screen_name',
);
say $uri;
http_request
	GET => "$uri",
	sub {
		if ($_[1]{Status} == 200) {
			my $j = $JSON->decode($_[0]);
			my %author;
			my %wall;
			for (@{$j->{response}{groups}}) {
				$author{ -$_->{gid} } = $_;
			}
			for (@{$j->{response}{profiles}}) {
				$author{ $_->{uid} } = $_;
			}
			for (@{$j->{response}{wall}}) {
				$wall{ $_->{from_id}.'_'.$_->{id} } = $_;
				$_->{author} = $author{ $_->{from_id} };
			}
			p %wall;
		}
		else {
			warn "$_[1]{Status} $_[1]{Reason}\n";
		}
		exit;
	}
;

EV::loop;
