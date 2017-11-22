#!/usr/bin/env perl

use utf8;
use 5.016;
use Socket ':all';
use JSON::XS;
use Time::HiRes qw(time);

our $JSON = JSON::XS->new->utf8;

socket my $s, AF_INET, SOCK_DGRAM, IPPROTO_UDP or die "socket: $!";

my $host = 'localhost'; my $port = 5500;
my $addr = gethostbyname $host;
my $sockaddr = sockaddr_in($port, $addr);

my $event_id = int(time*1000);
my $event_body = $JSON->encode({
	id => $event_id,
	port => 7777,
	type => 'stream',
});

send($s, $event_body, 0, $sockaddr);

#connect $s, $sockaddr;
#send($s, $event_body, 0);
