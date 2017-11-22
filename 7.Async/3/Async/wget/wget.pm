package wget 1.00;

use strict;
use warnings;

use IO::Socket;

use Getopt::Long;
use Pod::Usage;

use 5.016;
use DDP;

=head1 NAME

=head1 SYNOPSIS

=cut

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

# перебираем URL ... из ARGV
foreach my $url (@ARGV) {
	#my $url = $_;
	#my $ip = gethostbyname $url;

	# проверяем является ли валидным ip (наивно?)
	my $valid = 1;	# не является валидным ip
	if ($url =~ /^(\d{1,3}).(\d{1,3}).(\d{1,3}).(\d{1,3})$/) {
		$valid = 0;	# является валидным ip
		$valid = 1 if ($1 > 255 or $2 > 255 or $3 > 255 or $4 > 255);	# не валидный ip
	}

	print "--2017-11-16 15:16:18-- http://$url/\n";		# выводится в wget всегда
	print "Распознаётся $url ($url)... " if $valid;		# выводится в wget когда параметр доменное имя

	my $ip = gethostbyname $url;
	my $port = 80;

	# если удалось получить ip (распознать доменное имя)
	if (defined $ip) {
		my $inet_ip = inet_ntoa($ip);
		print $inet_ip . "\n" if $valid; # дополняем предыдущую строку выводом ip распознаного домена
		print "Подключение к $url"." ($url)|$inet_ip|"x$valid.":$port... ";
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

		
		
		# отключаем соединение и закрываем сокет
		shutdown ($socket, 2);
		close ($socket);
		#say "? - " . (gethostbyname "l");
		#say "? - " . (inet_aton("l"));

		#say "- - " . ((gethostbyname $_) eq (inet_aton($_)));
		#say "0 - " . ((gethostbyname $url) eq (inet_aton("ya.ru")));

		#say "1 - $url";
		#say "2 - $ip";
		#say "2.2 - " . length $ip;
		#say "3 - " . inet_ntoa $ip;
		#say "4 - " . inet_aton $url;
		#say "5 - " . (0+($ip eq inet_aton($url)));
	}
	else {
		# если не удалось получить ip (распознать доменное имя)
		print "ошибка: Имя или служба не известны.\n";
		print "wget: не удаётся разрешить адрес «$url».\n";
	}
}

1;
