package Shell 1.00;

use strict;
use warnings;

use Cwd;

use Getopt::Long;
use Pod::Usage;

#Необходимо реализовать собственный шелл
#	`встроенные команды: cd/pwd/echo/kill/ps`
#	`поддержать fork/exec команды`
#	`конвеер на пайпах`

=head1 NAME

 Shell - own shell.

=head1 SYNOPSIS

 Shell [options]

 Options:
 -help            show help for shell
 -man             show man for shell

 Commands:
 cd              chsnge the shell working directory
 pwd             print name of current shell working dirrectory
 echo            echo the STRING(s) to standard output
 kill            send a signal to a process
 ps              print process indormation

=cut

# Получаем опции в Хеш
my $param = {};
GetOptions ($param, 'help|?', 'man');

# выводим help/man (нам обязательно должны передать адрес назначения и порт)
pod2usage(1) if $param->{help};
pod2usage(-verbose => 2) if $param->{man};

# чистим ARGV и даем warn
if ($ARGV[0]) {
	@ARGV = ();
	warn "We don't wait a param to shell.";
}

# Основные данные
my $comCount = 0;	# счётчик команд
my $PS2 = "> "; 	# приглашение на ввод
my $Exit = "exit";	# выход
my %commands = (	# хеш команд
	cd => \&cd,
	pwd => \&pwd,
	echo => \&echo,
	kill => \&shell_kill,
	ps => \&ps,
	fork => \&shell_exec,
	exec => \&shell_exec,
	$Exit => \&shell_exit,
	clear => sub { system('clear'); },	# удобно убирать лапшу с экрана
	ls => sub { system('ls'); },
);

use DDP;
use 5.016;

{
	# обрабатываем ctrl+c аналогию sh
	local $SIG{INT} = 'IGNORE';

	while( is_interactive() ){
		# выводим приглашение и считываем пользовательсукую команду
		print $PS2;
		my $line = <>;
		unless ($line) {
			print "\n";
			last;
		}	# ctrl+d
		chomp($line);
		next unless $line;	# ctrl+c
		# инкремент количества команд
		$comCount++;
		# обрабатываем команду
		my @line = split /\s+/, $line;
		if (exists $commands{$line[0]})	{
			# а вот тут уже можно делать конвейер pipe
			$commands{$line[0]}->(*STDOUT, *STDIN, @line);
		}
		else {
			# выводим сообщение и Usage
			print "$0: $comCount: $line[0]: not found.$/";
			#pod2usage(-exitval => "NOEXIT");
		}
	}
}

sub is_interactive {
	return -t STDIN && -t STDOUT;
}

# один параметр - путь
# без параметра - переход в home каталог (~)
sub cd {
	my ($name, @argv) = @_;
	# еshсли есть аргумент используем его
	if ($argv[0]) {
		$argv[0] =~ s/~/$ENV{HOME}/;
		# chdir возвращает 0 в случае неудачи
		unless (chdir $argv[0]) {
			print "$name: $argv[0]: Нет такого файла или каталога\n"
		}
	}
	# иначе переходим в каталог home
	else {
		chdir $ENV{HOME};
	}
}

# выводит текущий путь
# $wfh - write to file handler
# $rfh - read from file handler
sub pwd {
	my ($wfh, $rfh, $name, @argv) = @_;
	print {$wfh} getcwd()."\n";
}

# выводим то что передано параметрами в $wfh
sub echo {
	my ($wfh, $rfh, $name, @argv) = @_;
	print join ' ', @argv;
	print "\n";
}

# 
sub shell_kill {
	my ($wfh, $rfh, $name, @argv) = @_;
	return undef;
}

# выводим таблицу процессов в $wfh
sub ps {
	my ($wfh, $rfh, $name, @argv) = @_;
	# запоминаем текущий каталог и переходим в /proc
	my $curdir = getcwd();
	chdir $ENV{HOME};
	chdir "/proc";

	# восстанавливаем текущую дирректорию
	chdir $curdir;
}

# форкаем процесс и выполняем exec (подмену)
sub shell_exec {
	my ($wfh, $rfh, $name, @argv) = @_;
	# Еcли не передали параметр, cообщим об этом
	unless ($argv[0]) {
		print "Nothing to $name. \n";
		return;
	}

	unless (my $pid  = fork()) {
		exec "$argv[0]";
		exit;
	}
	# ждём пока ляжет дочерний процесс, так как exec выполняет подмену
	wait();
}

# функция выхода из программы
sub shell_exit {
	if (wait() == -1) {	# ждем завершения дочерних процессов
		print "Goodbye$/";	
		exit;
	}
	else {
		# если процессы не завершены
		print "Not all process are ended.\n";
	}
}

1;
