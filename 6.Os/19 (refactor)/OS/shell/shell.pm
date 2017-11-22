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
my %commands = (	# хеш команд (команда, чистить ли STDOUT)
	cd => { sub => \&cd, clearSTD => 1},
	pwd => { sub => \&pwd, clearSTD => 1},
	echo => { sub => \&echo, clearSTD => 1},
	kill => { sub => \&shell_kill, clearSTD => 1},
	ps => { sub => \&ps, clearSTD => 1},
	fork => { sub => \&shell_exec, clearSTD => 1},
	exec => { sub => \&shell_exec, clearSTD => 1},
	$Exit => { sub => \&shell_exit, clearSTD => 0},
);

{
	# обрабатываем ctrl+c по аналогии sh
	local $SIG{INT} = 'IGNORE';

	while( 1 ){
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

		# обрабатываем команды
		my @line = split/\|/, $line;	# разделяем команды по пайпу |
		my $size = @line;

		# если всего одна команда (критично для команд cd, exit)
		unless ($#line) {
			my $comm = shift @line; # забираем команду
			$comm =~ /\s*(.+)/;	# убираем разделители в начале и в конце для каждоц строки
			my @comm = split /\s+/, $1;	# разделяем части команды по разделителю
			if ($comm[0]) {	# если есть команда
				if (exists $commands{$comm[0]})	{
					$commands{$comm[0]}{sub}->(@comm);
				}
				else {
					shell_exec($comm[0], $comm);
				}
			}
		}
		else {
			# делаем форк с открытием канала перенаправляющего дочерний STDOUT в READ_FROM_CHILD
			if (my $pid = open(READ_FROM_CHILD, '-|')) {
				print $_ while (<READ_FROM_CHILD>);
				close(READ_FROM_CHILD);
				waitpid($pid, 0);
			} else {
				die "Can't fork: $!" unless defined $pid;
				# далее первый дочерний процесс
				my @childSTDOUT;
				# пока в @line есть команды
				foreach my $num (0..$#line) {
					my $comm = $line[$num];	# берем следующую($num) команду
					$comm =~ /\s*(.+)/;	# убираем разделители в начале и в конце для каждоц строки
					my @comm = split /\s+/, $1;	# разделяем части каждой команды по разделителю
					next unless $comm[0]; # если есть команда
					pipe(IN_FROM_P, OUT_TO_C);	# для передачи данных из родительского в дочерний (буфер -> STDIN)
					pipe(IN_FROM_C, OUT_TO_P);	# для передачи данных из дочернего в родительский (STDOUT -> буфер)
					if (my $pidP = fork()) {
						# первый дочерний
						if ($num) {	# если команда не первая
						close (IN_FROM_P);
							print OUT_TO_C @childSTDOUT;	# передаем STDOUT предыдущей команды в следующую
							close (OUT_TO_C);
							@childSTDOUT = ();	# чистим чтобы не получить лишнего в выводе
						}
						close (OUT_TO_P);
						while (<IN_FROM_C>) { 
							push @childSTDOUT, $_;	# Записываем результат команды в буфер
							# далее это уйдет либо в вывод родителю, либо в следующую команду как STDIN
						}
						close (IN_FROM_C);
						waitpid ($pidP, 0);
					} else {
						# второй дочерний
						open (STDERR, '>&', 'STDOUT');	# перенаправление STDERR напрямую в STDOUT (в родительский процесс)
						if ($num) {	# если команда не первая
							close (OUT_TO_C);
							open (STDIN, '<&', 'IN_FROM_P'); # читаем IN_FROM_P(он же OUT_TO_P предыдущей команды) в STDIN текущей
							close (IN_FROM_P);
						}
						close (IN_FROM_C);
						open (STDOUT, '>&', 'OUT_TO_P') or die $!;	# направляем STDOUT текущей команды в OUT
						close (OUT_TO_P);

						# если команда из реализованных
						if (exists $commands{$comm[0]})	{
							# выкидываем STDOUT команды если команда не принимает STDIN
							@childSTDOUT = () if ( $commands{$comm[0]}{clearSTD} );
							$commands{$comm[0]}{sub}->(@comm);
						}
						else {
							exec "$comm" or do {
								exit; # если была ошибка в exec завершим дочерний процесс
							}
						}
					}
				} # for 
				print @childSTDOUT; # отправляем родителю накопленный STDOUT
				exit; # завершаем дочерний процесс
			}	
		}
	}
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
			print STDERR "$name: $argv[0]: Нет такого файла или каталога\n"
		}
	}
	# иначе переходим в каталог home
	else {
		chdir $ENV{HOME};
	}
}

# выводит текущий путь
sub pwd {
	my ($name, @argv) = @_;
	print getcwd()."\n";
}

# выводим то что передано параметрами в $wfh
sub echo {
	my ($name, @argv) = @_;
	print join ' ', @argv;
	print "\n";
}

# посылает сигнал TERM указанным в @argv процессам
sub shell_kill {
	my ($name, @argv) = @_;
	# если не передали параметров, выводим способ использования:
	unless (@argv) {
		print STDERR "$name: использование: kill pid ...\n";
	}
	# перебираем аргументы и завершаем соответствующие процессы
	foreach (@argv) {
		# если передали валидный pid (число)
		if ($_ =~ /^(\d+)$/) {
			unless (kill 'TERM', $_) {
				print STDERR "$0: $name: ($_) - Нет такого процесса\n";
			}
		}
		else {
			print STDERR "$0: $name: $_: аргументы должны быть идентификаторами процесса\n";
		}
	}
}

# выводим таблицу процессов
sub ps {
	my ($name, @argv) = @_;
	# выводим инфо строку 
	print "S   UID   PID  PPID PRI  NI WCHAN  CMD\n";
	# открываем директорию
	my %proc;	# хеш для данных о процессах
	opendir (my $dh, '/proc') or die $!;
	while (my $fname = readdir $dh) {
		if ($fname =~ /\d+/) {
			# от каждого числа -3 - номерв массиве line
			# 1 - Pid       - PID
			# 2 - (Name)    - (CMD)
			# 3 - State     - S
			# 4 - PPid      - PPID
			# 18 - priority - PRI
			# 19 - nice     - NI
			# 35 - wchan    - WCHAN
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
			# хеш позиций нужных данных (тип => позиция) (Номер в man - 3)
			my %poz = (
				S    => 0,
				PPID => 1,
				TTY  => 4,
				F    => 6,		
			);
			# считываем остальные параметры
			@line = $line[0] =~ /(\S+)/g;
			while (my ($k, $v) = each %poz) { $proc{$fname}{$k} = $line[$v]; }
			#print {$wfh} "S   UID   PID  PPID PRI  NI WCHAN  CMD\n";
			my $line = sprintf("%1s %5d %5d ",$proc{$fname}{S},$proc{$fname}{UID},$proc{$fname}{PID});
			$line .= sprintf("%5d %3d %3s ",$proc{$fname}{PPID},$proc{$fname}{PRI},$proc{$fname}{NI});
			$line .= sprintf("%-6s ",$proc{$fname}{WCHAN});
			$line .= sprintf("%s",$proc{$fname}{CMD});
			print "$line\n";
		}
	}
	closedir ($dh);
}

# форкаем процесс и выполняем exec (подмену)
sub shell_exec {
	my ($name, @argv) = @_;
	# Еcли не передали параметр, cообщим об этом
	unless ($argv[0]) {
		#print STDERR "Nothing to $name. \n";
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
	exit;
}

1;
