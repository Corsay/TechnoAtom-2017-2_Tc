#!/usr/bin/env perl

# use EV;
use 5.016;
use AnyEvent::HTTP;
use URI;
use DDP;

my @urls = (
	"http://search.cpan.org",
	"http://search.cpan.org:80/",
	"http://mfk.msu.ru",
	"http://ya.ru",
);

my $url = $urls[$ARGV[0]];
my $host = URI->new($url)->host;

#AE::cv->begin;

my @queue = ($url);
my %seen;
my $ACTIVE = 0;
my $curLevel = 0;	# текущий уровень вложенности
$AnyEvent::HTTP::MAX_PER_HOST = my $LIMIT = 100;

my $cv = AE::cv;

my $worker; $worker = sub {
	my $uri = shift @queue or return;
	$seen{ $uri } = undef;
	say "[$ACTIVE:$LIMIT] Start loading $uri (".(0+@queue).")";
	$ACTIVE++;

	$cv->begin;

	http_request
		HEAD => $uri,
		timeout => 10,
		sub {
			my ($body,$hdr) = @_;
			if (exists $hdr->{'content-length'} and $hdr->{'content-length'} < 4096) {
				http_request
					GET => $uri,
					timeout => 10,
					sub {
						my ($body,$hdr) = @_;
						say "End loading $uri: $hdr->{Status}";
						$ACTIVE--;
						$seen{ $uri } = $hdr->{Status};
						if ($hdr->{Status} == 200 and $curLevel < 1) {
							# say $hdr->{URL};
							# my @href = $body =~ m{<a[^>]*href=(|"([^"]+)"|(\S+))}i;
							my @href = $body =~ m{<a[^>]*href="([^"]+)"}sig;
							#p @href;
							for my $href (@href) {
								my $new = URI->new_abs( $href, $hdr->{URL} );
								next if $new !~ /^https?:/;
								next if $new->host ne $host;
								next if exists $seen{ $new };
								# say "$href -> $new";
								push @queue, $new;
								#p @queue;
								#if ($new !~ /\/$/) {	# увеличиваем уровень вложенности если вложен не подкаталог
									#p $new;
									$curLevel++ ;	
								#}
							}
							# p $hdr;
							# p $body;
						}
						else {
							warn "Failed to fetch: $hdr->{Status} $hdr->{Reason}";
						}
						while (@queue and $ACTIVE < $LIMIT) {
							$worker->();
							$cv->end;
						}
					}
				;
			}
			else {
				say "Skip loading $uri: $hdr->{Status} ($hdr->{'content-length'})";
				$ACTIVE--;
				$worker->();
				$cv->end;
			}
		}
	;
}; $worker->();

$cv->recv;
