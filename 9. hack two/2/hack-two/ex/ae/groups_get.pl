#!/usr/bin/env perl

use 5.016;
use utf8;
use open qw(:utf8 :std);
use LWP::UserAgent;
use DDP;
use URI;
use JSON::XS;
our $JSON = JSON::XS->new->utf8;

my $access_token = ...;
@ARGV = grep { $_ < 0 } @ARGV;
die "Need negative group ids\n" unless @ARGV;
@ARGV = map { -$_ } @ARGV;

my $auth_uri = URI->new("https://api.vk.com/method/groups.getById");
$auth_uri->query_form(
	access_token => $access_token,
	group_ids => join (",",@ARGV), # Argument contains positive values
);

my $ua = LWP::UserAgent->new();
$ua->timeout(3);
my $res = $ua->get($auth_uri);
die $res->status_line unless $res->is_success;
my $j = $JSON->decode($res->decoded_content);
p $j
