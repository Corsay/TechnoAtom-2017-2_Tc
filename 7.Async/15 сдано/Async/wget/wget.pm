package wget 1.00;

use strict;
use warnings;

use IO::Socket;
use AnyEvent::HTTP;
use URI;

use File::Path qw/make_path/;

use Getopt::Long;
use Pod::Usage;

=head1 NAME

  wget.pm - assync text/html files loader

=head1 SYNOPSIS

  perl wget.pm [options] URLS ...

  Options:
    -N - count of parralel queryes
    -r - recursive load
    -l - depth of recursive load (0 = INF)
    -L - only relative links
    -S - show server responce

=cut

# Параметры по-умолчанию
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
$param->{N} = 100 if ($param->{N} > 100);
# если параметр l = 0 то это бесконечная глубина и просто удалим ключ -l
delete $param->{l} if (exists $param->{l} and $param->{l} == 0);

# перебираем URL ... из ARGV
$AnyEvent::HTTP::MAX_PER_HOST = my $LIMIT = 100;

# Запоминаем URL из @ARGV в @queueURL
my @queueURL = @ARGV;

my $cv = AE::cv; $cv->begin; # begin

# перебираем URL ... из QueueURL
my $nextURL; $nextURL = sub {
	my $url = shift @queueURL or return;

	$cv->begin; # begin

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

	my $host = URI->new($url)->host;
	my @queue = ($url);
	my %seen;			# для текущего хоста -> просмотрено{STATUS} вложенность{CURLVL} каталог{FOLDER}
	# определяем каалог для загрузки
	my $curCat = $ENV{PWD};	# без рекурсии
	if (exists $param->{r}) { # c рекурсией
		$curCat = "$ENV{PWD}/$domain";
		mkdir $curCat unless (-e "$curCat");	# если каталога нет, создадим
	}
	$seen{$url}{CURLVL} = 0;	# текущий уровень вложенности
	$seen{$url}{PATH} = "";
	$seen{$url}{FILE} = "/index.html";
	my $ACTIVE = 0;		# активно для текущего хоста

	# перебираем URI ... из Queue
	my $next; $next = sub {
		my $uri = shift @queue or return;
		print "[$ACTIVE:$LIMIT] Начало загрузки $uri (".(0+@queue).")\n";
		$ACTIVE++;

		$cv->begin;	# begin

		# HEAD запрос
		http_request
			HEAD => $uri,
			sub {
				my ($body, $hdr) = @_;

				# получен положительный ответ
				if ($hdr->{Status} == 200 and $hdr->{'content-type'} =~ /^text\/html.*/ ) {
					# GET запрос
					http_request
						GET => $uri,
						sub {
							my ($body,$hdr) = @_;

							# обрабатываем опцию -S
							if (exists $param->{S}) {
								print "  HTTP/".$hdr->{HTTPVersion}." $hdr->{Status} $hdr->{Reason}\n";
								foreach (qw /date server content-length content-type cache-control expires
										last-modified content-security-policy p3p set-cookie x-frame-options
										x-xss-protection x-content-type-options keep-alive connection/) {
									print "  $_: $hdr->{$_}\n" if exists $hdr->{$_};
								}
							}

							print "Загрузка завершена $uri: $hdr->{Status}\n\n";
							$ACTIVE--;
							# взятие следующих URI
							$seen{$uri}{STATUS} = $hdr->{Status}; # запоминаем что эту ссылку мы уже скачали и её статус

							# записываем ответ в файл
							make_path ($curCat."$seen{$uri}{PATH}") unless (-e "$curCat"."$seen{$uri}{PATH}");	# если каталога нет, создадим
							my $fullname = "$curCat"."$seen{$uri}{PATH}"."$seen{$uri}{FILE}";
							open (my $fh, '>', $fullname) or do {
								print "Нет возможности открыть файл для записи: $!$/";
								$cv->end;
								return;
							};
							syswrite $fh, $body or do {
								print "Нет возможности сохранить в данный файл: $!$/";
								$cv->end;
								return;
							};
							print "Cохранено в каталог: ««$fullname»»\n";
							close $fh;

							#      если успешно        и при этом рекурсивно  и    глубина бесконечна    или не превышает запрошенной
							if ($hdr->{Status} == 200 and exists $param->{r} and (not exists $param->{l} or $seen{$uri}{CURLVL} < $param->{l})) {
								my @href = $body =~ m{(?:<a|<link)[^>]*href="([^"]+)"}sig;
								for my $href (@href) {
									my $new = URI->new_abs( $href, $hdr->{URL} );
									if (exists $param->{L}) {
										next if $new =~ /^https?:/;		# если только по относительным ссылкам
									}
									else {
										next if $new !~ /^https?:/;		# проверяем протокол на http: или https:
									}
									next if $new->host ne $host;	# качать только с текущего хоста
									$new =~ s/#.*//;	# отрезает из $new все что после "#"
									next if exists $seen{$new};		# чтобы не качать повторно
									$seen{$new}{CURLVL} = $seen{$uri}{CURLVL}+1;
									push @queue, $new;

									$new =~ "(https?)?:?(\/\/)?($domain)?:?($port)?(\/(.*))?\/([^\/]*)";
									my $path = $6 ? "/$6" : "";
									my $file = $7 ? "/$7" : "/index.html";
									$seen{$new}{PATH} = "$path";
									$seen{$new}{FILE} = "$file";
								}
							}

							# если очередь URI не пуста и лимит не превышен запустить следующий запрос в обработку
							while (@queue and $ACTIVE < $LIMIT) {
								$next->();
							}
							$cv->end;
						}
					;
				} else {
					# если неудача на этоп этапе выведем соответсвующее сообщение
					print "Skipped: $uri: @$hdr{qw(Status Reason)}\n";
					$ACTIVE--;
					$next->();
					$cv->end; # end
				}
			}
		;
	}; $next->();

	while (@queueURL) {
		$nextURL->();
	}
	$cv->end;
}; $nextURL->() for 1..$param->{N};

$cv->end; $cv->recv; # end

1;
