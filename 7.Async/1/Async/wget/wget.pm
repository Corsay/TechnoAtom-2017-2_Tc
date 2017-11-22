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

# перебираем URL ... из ARGV 
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

1;
