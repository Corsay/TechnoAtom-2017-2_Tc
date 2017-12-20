package YourPackage 1.00;

use 5.010;	# минимальная версия для использования say, и т.д.
use strict;
use warnings;

my $TEST = {
	sv => "string",
	av => [ qw(some elements) ],
	hv => {
		nested => "value",
		key => [ 1,2,{},[],undef,'' ],
	},
};
my $TEST2 = {
	sv => "string",
};

use Data::Dumper;
say "Dumper ", Dumper($TEST);

{
	local $| = 1;			# сделаем "локально" autoflush на STDOUT (чтобы print вывелся до вывода DDP)
	#$|++;
	#*STDOUT->autoflush(1);	# или глобально и придется в конце кода вернуть все обратно

	use DDP;
	print "DDP ";
	p $TEST;

	#*STDOUT->autoflush(0);	# возврат (причём не файт что исходно autoflush не был установлен)
	#$|--;
}

print "DDP ";
p $TEST2;
print "\n";
