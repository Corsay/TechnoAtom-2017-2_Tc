package shell 1.00;

use strict;
use warnings;

use Cwd;

use Getopt::Long;
use Pod::Usage;

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
	warn "Оболочка не ожидает параметров. Параметры отброшены.";
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

say "PID  - $$";
say "GID  - $(";
say "EGID - $)";
say "UID  - $>";
say "EUID - $<";

{
	# обрабатываем ctrl+c по аналогии sh
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
		my @line = split/\|/, $line;	# разделяем команды по пайпу |
		#p @line;
		#$line =~ /\s*(.+)/;	# убираем разделители в начале и в конце для каждоц строки
		#@line = split /\s+/, @line;	# разделяем части каждой команды по разделителю
		#p @line;
		if (exists $commands{$line[0]})	{
			# а вот тут уже можно делать конвейер pipe
			$commands{$line[0]}->(*STDOUT, *STDIN, @line);
		}
		else {
			# выводим сообщение и Usage
			print "$0: $comCount: $line[0]: команда не найдена.$/";
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
	my ($wfh, $rfh, $name, @argv) = @_;
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
# $wfh - write to file handler
# $rfh - read from file handler
sub pwd {
	my ($wfh, $rfh, $name, @argv) = @_;
	print {$wfh} getcwd()."\n";
}

# выводим то что передано параметрами в $wfh
sub echo {
	my ($wfh, $rfh, $name, @argv) = @_;
	print {$wfh} join ' ', @argv;
	print {$wfh} "\n";
}

# посылает сигнал TERM указанным в @argv процессам
sub shell_kill {
	my ($wfh, $rfh, $name, @argv) = @_;
	# если не передали параметров, выводим способ использования:
	unless (@argv) {
		print "$name: использование: kill pid ...\n";
	}
	# перебираем аргументы и завершаем соответствующие процессы
	foreach (@argv) {
		# если передали валидный pid (число)
		if ($_ =~ /^(\d+)$/) {
			unless (kill 'TERM', $_) {
				print "$0: $name: ($_) - Нет такого процесса\n";
			}
		}
		else {
			print "$0: $name: $_: аргументы должны быть идентификаторами процесса\n";
		}
	}
}

# выводим таблицу процессов в $wfh
sub ps {
	my ($wfh, $rfh, $name, @argv) = @_;

	# выводим инфо строку 
	print {$wfh} "S   UID   PID  PPID PRI  NI WCHAN  TTY      CMD\n";
	# открываем директорию
	my %proc;	# хеш для данных о процессах
	opendir (my $dh, '/proc') or die $!;
	while (my $fname = readdir $dh) {
		if ($fname =~ /1475/) {
			# от каждого числа -3 - номерв массиве line
			# 1 - Pid       - PID
			# 2 - (Name)    - (CMD)
			# 3 - State     - S
			# 4 - PPid      - PPID
			# 7 - tty_nr    - TTY   - конвертировать
			# 14 15 16 17 22 43 44 - time
			# 18 - priority - PRI
			# 19 - nice     - NI
			# 35 - wchan    - WCHAN
			# 
			# хеш позиций нужных данных (тип => позиция) (Номер в man - 3)
			my %poz = (
				S    => 0,
				PPID => 1,
				TTY  => 4,
				F    => 6,		
			);
			# читаем нужные файлы процесса
			# строковый wchan
			open (my $fh, "<", "/proc/$fname/wchan");
			my @line = <$fh>;
			chomp($line[0]);
			$line[0] =~ /^(.{6})/;
			$proc{$fname}{WCHAN} = $1 // "-";
			close ($fh);
			# Uid
			open ($fh, "<", "/proc/$fname/status");
			@line = grep {chomp($_); $_ = "$1" if $_ =~ /Uid:\s+(\d+)/; } <$fh>;
			$proc{$fname}{UID} = $line[0] // 0;
			close ($fh);
			# PRI  NI
			# PRI = prio - 40
			# NI  = PRI - 80
			open ($fh, "<", "/proc/$fname/sched");
			@line = grep {chomp($_); $_ = "$1" if $_ =~ /prio\s+:\s+(\d+)/;} <$fh>;
			if ($line[0]) {
				$proc{$fname}{PRI} = $line[0] - 40;
				$proc{$fname}{NI} = $proc{$fname}{PRI} - 80;
			}
			else {
				$proc{$fname}{PRI} = -40;
				$proc{$fname}{NI} = "-";
			}
			close ($fh);
			# считываем PID и CMD и убираем их из строки
			open ($fh, "<", "/proc/$fname/stat");
			@line = <$fh>;
			close ($fh);
			#                PID      CMD
			$line[0] =~ s/^((\d+)\s\((.+)\))//;
			$proc{$fname}{PID} = $2;
			$proc{$fname}{CMD} = $3;
			# считываем остальные параметры
			@line = $line[0] =~ /(\S+)/g;
			while (my ($k, $v) = each %poz) { $proc{$fname}{$k} = $line[$v]; }

			# 14 15 16 17 22 43 44 - time
			use POSIX;
			my $clock_ticks = POSIX::sysconf(&POSIX::_SC_CLK_TCK);
			print "14 = $line[14]\n";
			print "15 = $line[15]\n";
			print "16 = $line[16]\n";
			print "17 = $line[17]\n";
			print "localtime = ".localtime."\n";
			print "22 = $line[22]\n";
			print "22 = $clock_ticks\n";
			$line[22] /= $clock_ticks;
			print "22 = $line[22]\n";
			print "localtime from = ".localtime($line[22]/$clock_ticks)."\n";
			print "43 = $line[43]\n";
			print "44 = $line[44]\n";
			$proc{$fname}{TIME} = "00:00:00";
			system("ps -el | grep 1475");
			#print {$wfh} "S   UID   PID  PPID PRI  NI WCHAN  TTY          TIME CMD\n";
			my $line = sprintf("%1s %5d %5d ",$proc{$fname}{S},$proc{$fname}{UID},$proc{$fname}{PID});
			$line .= sprintf("%5d %3d %3s ",$proc{$fname}{PPID},$proc{$fname}{PRI},$proc{$fname}{NI});
			$line .= sprintf("%-6s %-8s ",$proc{$fname}{WCHAN},$proc{$fname}{TTY});
			$line .= sprintf("%s",$proc{$fname}{CMD});
			print {$wfh} "$line\n";
			last;
		}
	}
	closedir ($dh);
}

# форкаем процесс и выполняем exec (подмену)
sub shell_exec {
	my ($wfh, $rfh, $name, @argv) = @_;
	# Еcли не передали параметр, cообщим об этом
	unless ($argv[0]) {
		#print "Nothing to $name. \n";
		return;
	}
	# выполняем fork и exec
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
		print "Всего доброго!$/";	
		exit;
	}
	else {
		# если процессы не завершены
		print "Не все процессы завершены\n";
	}
}

1;
