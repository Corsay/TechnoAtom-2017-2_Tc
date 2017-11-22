package wget 1.00;

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

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

use 5.016;
use DDP;

# AnyEvent
#use AnyEvent::IO;
=head
sub AE::cv(;&) {
	my $self = bless {}, 'condvar';
	$self->{cb} = shift;
	return $self;
}
sub condvar::begin {
	my $self = shift;
	$self->{counter}++;
}
sub condvar::end {
	my $self = shift;
	$self->{counter}--;
	if ($self->{counter} == 0) {
		$self->send();
	}
}
sub condvar::cb {
	my $self = shift;
	$self->{cb} = shift;
}
sub condvar::recv {
	my $self = shift;
	$self->_one_loop
	while !$self->{sent};
	return @{ $self->{args} };
} 
sub condvar::send {
	my $self = shift;
	$self->{sent} = 1;
	$self->{args} = [ @_ ];
	if ($self->{cb}) { $self->{cb}->() };
}
# =cut
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
say "";
say "";

# Параллельно
say "\x1b[1;31m"."Параллельно"."\x1b[0m";
{
	my $cv = AE::cv; $cv->begin;
	my @array = 1..5;
	for my $cur (@array) {
		say "\x1b[32m"."Process"."\x1b[0m $cur";
		$cv->begin;
		async sub {
			say "\x1b[1;32m"."Processed"."\x1b[0m $cur";
			$cv->end;
		};
	}
	$cv->end; $cv->recv;
}
say "";
say "";

# Последовательно
say "\x1b[1;31m"."Последовательно"."\x1b[0m";
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

	}; $next->();
	
	$cv->end; $cv->recv;
}
say "";
say "";
# =head
=cut

# Coro
=head
say "\x1b[1;31m"."Coro"."\x1b[0m";
use Coro;
my $chan = Coro::Channel->new(2); # 2 elements chan
async {
	while(my $val = $chan->get){
		say "\x1b[32m"."chan out"."\x1b[0m:", $val;
	}
};
$chan->put($_) for 1..3;
=cut

# перебираем URL ... из ARGV
#=head
foreach (@ARGV) {
	my $url = "ya.ru";
	my $ip = gethostbyname $url;

	say ((gethostbyname $_) eq (inet_aton($_)));
	say ((gethostbyname $url) eq (inet_aton("ya.ru")));

	say "1 - $url";
	say "2 - $ip";
	say "2.2 - " . length $ip;
	say "3 - " . inet_ntoa $ip;
	say "4 - " . inet_aton $url;
	say "5 - " . (0+($ip eq inet_aton($url)));
}
#=cut

1;
