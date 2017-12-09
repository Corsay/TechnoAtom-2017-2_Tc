#!/usr/bin/env perl

use strict;
use warnings;
use FindBin; use lib "$FindBin::Bin/../lib";

use Getopt::Long;	# парсить параметры
use JSON::XS;		# * Ответ приложения `bin/social_network.pl` должен быть в формате `JSON`

use Local::SocialNetwork;

# -ru = -r -u
# --ru = -ru
Getopt::Long::Configure("bundling");
# читаем параметры
my $param = [];
GetOptions (
	'user=i' => sub { push @$param, $_[1]; }
);

# создаем экземпляр класса СоцСети
my $soc = Local::SocialNetwork->new( {config => 'database.yml'} );

# проверяем ввод пользователя - команду и параметры для команды
my %coms = (
	friends => sub { $soc->friends(@_); },
	nofriends => sub { $soc->nofriends(); },
	num_handshakes => sub { $soc->num_handshakes(@_); },
);
my $answer;	# результат выпголнения функции
if (defined $ARGV[0] and exists $coms{$ARGV[0]}) {
	# если есть аргумент(команда), и она есть в списке команд, то выполнить
	$answer = $coms{$ARGV[0]}->($param->[0], $param->[1]);
	# если $answer = undef то были переданы некорректные параметры
	die "$ARGV[0]: некорректные аргументы" unless defined $answer;
}
else {
	# если не допустимая команда
	print "Допустимые команды:\n";
	print "  friends --user XX --user YY\n";
	print "  nofriends\n";
	print "  num_handshakes --user XX --user YY\n";
	print "где XX и YY целочисленные id пользователей.\n";
	exit();
}

# в итоге работаем с JSON результатом
my $json = JSON::XS::decode_json($answer);
print "[\n";
foreach (@$json) {
	if ($ARGV[0] eq 'num_handshakes') {
		print "  num_handshakes = $_->{num_handshakes}\n";
	}
	else {
		print "  { 'first_name': '$_->{first_name}', 'last_name': '$_->{last_name}', 'ID': $_->{ID} },\n";
	}
}
print "]\n";
