package wget 1.00;

use strict;
use warnings;

use IO::Socket;
use AnyEvent::HTTP;
use URI;

use Getopt::Long;
use Pod::Usage;

use 5.016;
use DDP;

=head1 NAME

=head1 SYNOPSIS

=cut

# Параметры по-умолчанию
my $debug = 0;
my $out_like_wget = 0;
my %def = (
	prot => 'http',
	port_http => 80,
	port_https => 443,
);

# Информационное сообщение и функция для его вывода с выходом(аналогия wget)
my $errorHelpInfo = "Использование: perl $0 [КЛЮЧ]... [URL]...\n
Запустите `perl $0 -help' для получения более подробной справки.";
sub ErrorInfoMsg {
	my ($msg) = @_;
	print "$msg\n";
	exit;
}

# -ru = -r -u
# --ru = -ru 
Getopt::Long::Configure("bundling");

# Получаем опции в Хеш
my $param = {};
GetOptions ($param, 'help|?', 'man', 'N=i', 'r', 'l=i', 'L', 'S') 
	or ErrorInfoMsg($errorHelpInfo);

# проверяем на минимально необходимые параметры
ErrorInfoMsg("wget: не указан URL\n$errorHelpInfo") unless (@ARGV);	# ни одного URL

# выводим help/man (нам обязательно должны передать адрес назначения и порт)
pod2usage(1) if $param->{help};
pod2usage(-exitval => 0, -verbose => 2) if $param->{man};

# проверяем остальные параметры
$param->{N} = 1 if (not exists $param->{N} or $param->{N} == 0);	# если параметр N не задан или равен 0
# если параметр l = 0 то это бесконечная глубина и просто удалим ключ -l
delete $param->{l} if (exists $param->{l} and $param->{l} == 0);	

### схожее с выводом в wget
my %rec = (); # Recognized - распознанные url
###

# перебираем URL ... из ARGV
$AnyEvent::HTTP::MAX_PER_HOST = my $LIMIT = 100;

# Перебираем URL ... из queueURL
my @queueURL = @ARGV;

my $cvURL = AE::cv; $cvURL->begin; # begin

# перебираем URI ... из Queue
my $nextURL; $nextURL = sub {
	my $url = shift @queueURL or return;

	# debug - отладочное (URL)
	if ($debug) {
		print "\x1b[1;32m"."defurl - $url\n"."\x1b[0m";	#p $url;
	}
	# определяем протокол, домен, порт и параметры
	my ($prot, $domain, $port, $params);
	#         ????????      ????????????
	#         https://DOMAIN:Port/PARAMS
	$url =~ /(https?)?:?(\/\/)?([^\/:]*):?([^\/]*)?\/?(.*)/;	# парсим поданный на вход url
	$prot = $1 // $def{prot};	# получаем протокол (http или https)
	$domain = $3;				# получаем доменное имя
	$port = $4;					# получаем порт
	unless ($port) {	# если не указан порт, берем порт по умолчанию (в соответствии протоколу)
		$port = $prot eq 'http' ? $def{port_http} : $def{port_https};
	}
	$params = $5;				# все остальные параметры url
	$url = "$prot://$domain:$port/$params";	# формируем нужный формат url
	my $ip = gethostbyname $domain;		# получаем ip (для распознования домена)
	my $inet_ip = ''; $inet_ip = inet_ntoa($ip) if $ip;
	# debug - отладочное (URL)
	if ($debug) {
		print "\x1b[32m"."prot   - \x1b[31m". $prot ."\x1b[0m"."\n"; 	#p $prot;
		print "\x1b[32m"."domain - \x1b[34m". $domain ."\x1b[0m"."\n"; 	#p $domain;
		print "\x1b[32m"."port   - \x1b[31m". $port ."\x1b[0m"."\n"; 	#p $port;
		print "\x1b[32m"."url    - \x1b[34m". $url ."\x1b[0m"."\n"; 	#p $url;
		print "\x1b[32m"."params - \x1b[31m". $params ."\x1b[0m"."\n"; 	#p $params;
		if ($ip) {
			print "\x1b[32m"."ip     - \x1b[34m". $ip ."\x1b[0m"."\n"; 	#p $ip;
			print "\x1b[32m"."dig ip - \x1b[31m". $inet_ip ."\x1b[0m"."\n";
		}
	}

	# если удалось получить ip (распознать доменное имя)
	if (defined $ip) {
		my $host = URI->new($url)->host;
		my @queue = ($url);
		my %seen;		# просмотрено для текущего хоста
		my $ACTIVE = 0;	# активно для текущего хоста

		my $cv = AE::cv; $cv->begin; # begin
		$cvURL->begin;

		# перебираем URI ... из Queue
		my $next; $next = sub {
			my $uri = shift @queue or return;

			$seen{ $uri } = undef;
			say "[$ACTIVE:$LIMIT] Start loading $uri (".(0+@queue).")";
			$ACTIVE++;

			$cv->begin;	# begin

			# HEAD запрос
			http_request
				HEAD => $uri,
				timeout => 1,
				sub {
					my ($body, $hdr) = @_;
					### схожее с выводом в wget
					if ($out_like_wget) {	# если нужно видеть вывод как в wget
						# проверяем является ли валидным ip
						my $valid = 1;	# не является валидным ip
						if ($domain =~ /^(\d{1,3}).(\d{1,3}).(\d{1,3}).(\d{1,3})$/) {
							$valid = 0;	# является валидным ip
							$valid = 1 if ($1 > 255 or $2 > 255 or $3 > 255 or $4 > 255);	# не валидный ip
						}
						print "$uri\n";
						my $valid_out = 0;
						if ($valid and not exists $rec{$domain}) {
							# выводится в wget когда параметр доменное имя, которое не было распознанно ранее
							$rec{$domain} = $inet_ip;
							print "Распознаётся $domain ($domain)... ";
							$valid_out = 1;
						}
						print "$inet_ip\n" if ($valid_out); # дополняем предыдущую строку выводом ip распознаного домена
						print "Подключение к $domain"." ($domain)|$inet_ip|"x$valid.":$port... ";
						print "соединение установлено\n";
						print "HTTP-запрос отправлен. Ожидание ответа... ";
					}
					###

					if ($hdr->{Status} == 200 and exists $hdr->{'content-length'} and $hdr->{'content-length'} < 4096) {
						# получен положительный ответ
						#print "Success: ".length($body)."\n";

						# GET запрос
						http_request
							GET => $uri,
							timeout => 10,
							sub {
								my ($body,$hdr) = @_;

								# обрабатываем опцию -S


								# save to file here
								###################
								###################
								###################

								say "End loading $uri: $hdr->{Status}";
								$ACTIVE--;
								# взятие следующих URI
								$seen{ $uri } = $hdr->{Status}; # запоминаем что эту ссылку мы уже скачали и её статус
								if ($hdr->{Status} == 200) {
									my @href = $body =~ m{<a[^>]*href="([^"]+)"}sig;
									for my $href (@href) {
										my $new = URI->new_abs( $href, $hdr->{URL} );
										next if $new !~ /^https?:/;		# проверяем протокол на http: или https:
										next if $new->host ne $host;
										next if exists $seen{ $new };	# чтобы не качать повторно
										push @queue, $new;
										p @queue;
									}
								} else {
									warn "Failed to fetch: $hdr->{Status} $hdr->{Reason}";
								}

								# если очередь URI не пуста и лимит не превышен запустить следующий запрос в обработку
								while (@queue and $ACTIVE < $LIMIT) {
									$next->();
									$cv->end; # end
									$cvURL->end; # end
								}

								# если очередь URL не пуста запустить следующий запрос в обработку
								while (@queueURL) {
									$nextURL->();
									$cvURL->end; # end
								}
							}
						;
					} else {
						# если неудача на этоп этапе выведем соответсвующее сообщение
						#print "Fail: @$hdr{qw(Status Reason)}\n";	
						say "Skip loading $uri: $hdr->{Status} ($hdr->{'content-length'})";
						$ACTIVE--; 
						$next->();
						$cv->end; # end	
					}	
				}
			;
		}; $next->();

		$cv->end; $cv->recv; # end
	}
	else {
		# если не удалось получить ip (распознать доменное имя)
		print "ошибка: Имя или служба не известны.\n";
		print "wget: не удаётся разрешить адрес «$domain».\n";
		$nextURL->();
		$cvURL->end; # end
	}
}; $nextURL->() for 1..$param->{N};

$cvURL->end; $cvURL->recv; # end

1;
