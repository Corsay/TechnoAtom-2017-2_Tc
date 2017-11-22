use v5.010;
use strict;
use warnings;

use AnyEvent::HTTP;
use EV;
use XML::Fast;
use URI;
use DDP;

binmode(STDOUT, ':utf8');
# Register your user on your own
# http://www.geonames.org/
my $username = 'demo';

my $uri = URI->new('http://api.geonames.org/search');
$uri->query_form(q => 'Масква', username => $username, maxRows => 10);

http_request (
	GET => $uri,
	sub {
		my ($b, $h) = @_;
		unless ($h->{Status} == 200) {
			warn "Error on download: $h->{Status} $h->{Reason}";
			EV::unloop;
		}

		my $reply = xml2hash($b);
		# p $reply;

		say join "\n", map { sprintf "%s:\t%s %s", $_->{toponymName}, $_->{lat}, $_->{lng} } @{ $reply->{geonames}{geoname} };

		EV::unloop;
	}
);

EV::loop;