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
 cd              a
 pwd             print name of current working dirrectory
 echo            a
 kill            a
 ps              a

=cut

# Получаем опции в Хеш
my $param = {};
GetOptions ($param, 'help|?', 'man');

# выводим help/man (нам обязательно должны передать адрес назначения и порт)
pod2usage(1) if $param->{help};
pod2usage(-verbose => 2) if $param->{man};

# Основные данные
my $PS2 = "> "; 	# приглашение на ввод
my $Exit = "exit";	# выход
my %commands = (	# хеш команд
	cd => \&cd,
	pwd => \&pwd,
	echo => \&echo,
	kill => \&shell_kill,
	ps => \&ps,
	fork => \&shell_fork,
	exec => \&shell_exec,
	$Exit => \&shell_exit,
	clear => sub { system('clear'); },	# удобно убирать лапшу с экрана
	ls => sub { system('ls'); },
);

use DDP;
use 5.016;
#p %ENV;
#p %commands;

my $do = 1;
while( is_interactive() ){
	# выводим приглашение и считываем пользовательсукую команду
	print $PS2;
	my $line = <>;
	chomp($line);
	# обрабатываем команду
	my @line = split /\s+/, $line;
	if (exists $commands{$line[0]})	{
		$commands{$line[0]}->(@line);
	}
	else {
		# выводим сообщение и Usage
		print "Incorrect shell command.$/";
		#pod2usage(-exitval => "NOEXIT");
	}
	#print "command: $line$/";
}

sub is_interactive {
	return -t STDIN && -t STDOUT;
}

# один параметр - путь
# без параметра - переход в home каталог (~)
sub cd {
	my ($name, @argv) = @_;
	# если есть аргумент используем его
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
sub pwd {
	print getcwd()."\n";
}

# выводим то что передано параметрами в STDOUT
sub echo {
	my ($name, @argv) = @_;
	print join ' ', @argv;
	print "\n";
}

sub shell_kill {
	my ($name, @argv) = @_;
	return undef;
}

sub ps {
	my ($name, @argv) = @_;
	return undef;
}

sub shell_fork {
	my ($name, @argv) = @_;
	
	return undef;
}

sub shell_exec {
	my ($name, @argv) = @_;
	
	return undef;
}

# функция выхода из программы
sub shell_exit {
	my ($name, @argv) = @_;
	print "Goodbye$/";
	exit;
}

1;
