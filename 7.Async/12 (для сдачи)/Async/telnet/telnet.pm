package telnet 1.00;

use strict;
use warnings;

use AnyEvent::Socket;
use AnyEvent::Handle;

use Getopt::Long;
use Pod::Usage;

=head1 NAME

  telnet.pm - telnet client

=head1 SYNOPSIS

  perl telnet.pm destination port

=cut

# Получаем опции в Хеш
my $param = {};
GetOptions ($param, 'help|?', 'man');

# Забираем из ARGV destination и port (целое число)
$param->{dest} = $ARGV[0];
$param->{port} = "80";
if ($ARGV[1]) {
	$ARGV[1] =~ /(\d+)/;
	$param->{port} = $1;
}

# выводим help/man (нам обязательно должны передать адрес назначения и порт)
pod2usage(1) if ($param->{help});
pod2usage(-exitval => 0, -verbose => 2) if $param->{man};

my $cv = AE::cv; $cv->begin;

my ($reader_from_STDIN);

my $telnet; $telnet = sub {
	my ($param) = @_;

	# устанавливаем TCP соединение
	tcp_connect $param->{dest}, $param->{port}, sub {
		if (my $fh = shift) {
			# говорим об успешном соединении
			print "Соединено с $param->{dest}:$param->{port}$/";
			print "Для выхода: '^C'$/";

			my $h;
			$h = AnyEvent::Handle->new(
				fh => $fh,
				on_error => sub {
					$h->destroy;
					$cv->end;
				},
				on_eof => sub {
					$h->destroy;
					$cv->end;
				},
				on_read => sub {
					print $h->rbuf();	# печатаем ответ сервера
					$h->{rbuf} = '';	# чистим буфер
				},
			);

			$reader_from_STDIN = AE::io \*STDIN, 0, sub {	# ждет пока STDIN станет читаемым
				my $line = <STDIN>;	# забираем запрос из ввода пользователя
				if ($h) {
					$h->push_write($line);	# отдаем запрос серверу
				}
			};
		}
		else {
			# говорим о провале в соединении
			print "Соединение провалено: $!$/";
			$cv->end;
		}
	};
}; $telnet->($param);

$cv->recv;

1;
