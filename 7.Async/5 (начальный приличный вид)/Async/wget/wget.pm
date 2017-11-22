package wget 1.00;

use strict;
use warnings;

use IO::Socket;
use AnyEvent::HTTP;
#use Web::Query;
#use Coro::LWP;
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

# Получаем опции в Хеш
my $param = {};
GetOptions ($param, 'help|?', 'man', 'N=i', 'r', 'l=i', 'L', 'S') 
	or ErrorInfoMsg($errorHelpInfo);

# проверяем на минимально необходимые параметры
ErrorInfoMsg("wget: не указан URL\n$errorHelpInfo") unless (@ARGV);	# ни одного URL

# выводим help/man (нам обязательно должны передать адрес назначения и порт)
pod2usage(1) if $param->{help};
pod2usage(-exitval => 0, -verbose => 2) if $param->{man};

# AnyEvent
#use AnyEvent::IO;
=head
sub async {
	my $cb = pop;
	my $w; $w = AE::timer rand(0.1),0,sub {
		undef $w;
		$cb->();
	};
	return;
}

# Параллельно с лимитом
say "\x1b[1;31m"."Параллельно с лимитом"."\x1b[0m";
{
	my $cv = AE::cv; $cv->begin;
	my @array = 1..5;
	my $i = 0;
	my $next; $next = sub {
		my $cur = $i++;
		return if $cur > $#array;
		say "\x1b[32m"."Process"."\x1b[0m $array[$cur]";
		$cv->begin;
		async sub {
			say "\x1b[1;32m"."Processed"."\x1b[0m $array[$cur]";
			$next->();
			$cv->end;
		};
	}; $next->() for 1..3;
	$cv->end; $cv->recv;
}
=cut
$AnyEvent::HTTP::MAX_PER_HOST = my $LIMIT = 100;

### схожее с выводом в wget
my %rec = (); # Recognized - распознанные url
###

# перебираем URL ... из Queue
my @queue = @ARGV;
foreach my $url (@queue) {
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
	unless ($port) {# если не указан порт, берем порт по умолчанию
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

	### схожее с выводом в wget
	# проверяем является ли валидным ip
	my $valid = 1;	# не является валидным ip
	if ($domain =~ /^(\d{1,3}).(\d{1,3}).(\d{1,3}).(\d{1,3})$/) {
		$valid = 0;	# является валидным ip
		$valid = 1 if ($1 > 255 or $2 > 255 or $3 > 255 or $4 > 255);	# не валидный ip
	}
	print "--2017-11-16 15:16:18-- $url\n";
	my $valid_out = 0;
	if ($valid and not exists $rec{$domain}) { 
		# выводится в wget когда параметр доменное имя, которое не было распознанно ранее
		$rec{$domain} = $inet_ip;
		print "Распознаётся $domain ($domain)... ";
		$valid_out = 1;
	}
	###

	# если удалось получить ip (распознать доменное имя)
	if (defined $ip) {
		### схожее с выводом в wget
		print "$inet_ip\n" if ($valid_out); # дополняем предыдущую строку выводом ip распознаного домена
		print "Подключение к $domain"." ($domain)|$inet_ip|"x$valid.":$port... ";
		print "соединение установлено\n";
		###

		my $cv = AE::cv; $cv->begin;

		my $next; $next = sub {
			$cv->begin;

			http_request
				HEAD => $url,
				timeout => 1,
				sub {
					my ($body, $hdr) = @_;
					if ($hdr->{Status} == 200) {
						# получен ответ
						say "Success: ".length $body;
					} else {
						# иначе неудача
						say "Fail: @$hdr{qw(Status Reason)}";
					}

					$cv->end;
				}
			;
		}; $next->();

		$cv->end; $cv->recv;

=head
				# создаем сокет(TCP)? И если смог приконектить то "соединение установлено".
		my $SockError = 0;
		my $socket = IO::Socket::INET->new(
			PeerAddr => $inet_ip,
			PeerPort => $port,
			Proto => 'tcp',
			Type => SOCK_STREAM,
		) or $SockError = 1;
		if ($SockError) {
			# при ошибке подключения ($1 - первый байт ip адреса из проверки url на валидный ip)
			if ($1 == 0) {print "ошибка: Недопустимый аргумент.\n";}
			else {print "ошибка: Сеть недоступна.\n";}
			next;
		};
		print "соединение установлено.\n";

		# отправление http запроса
		print $socket
			"GET / HTTP/1.0\nHost: $url\n\n";
		#print "HTTP-запрос отправлен. Ожидание ответа... ";

		# отключаем соединение и закрываем сокет
		shutdown ($socket, 2);
		close ($socket);
=cut
	}
	else {
		# если не удалось получить ip (распознать доменное имя)
		print "ошибка: Имя или служба не известны.\n";
		print "wget: не удаётся разрешить адрес «$domain».\n";
	}
	print "\n";
}

1;
