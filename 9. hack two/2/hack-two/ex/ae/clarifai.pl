#!/usr/bin/env perl

use 5.016;
use utf8;
use open qw(:utf8 :std);

use EV;

use DDP;
use JSON::XS;
use MIME::Base64;
use AnyEvent::HTTP;

my $apikey = ...;

my $url = 'https://api.clarifai.com/v2/models/aaa03c23b3724a16a56b629203edc62c/outputs';
my $photo;
{
	open my $fh, '<', "AXUuvghZd3E.jpg" or die $!;
	local $/; $photo = encode_base64(<$fh>);
}

http_request
	POST => $url,
	headers => {
		'content-type' => 'application/json',
		'Authorization' => "Key $apikey",
	},
	body => JSON::XS->new->encode({
		inputs => [{
			data => {
				image => {
					base64 => $photo,
				}
			}
		}]
	}),
	sub {
		p @_;
		EV::unloop;
	};

EV::loop;

