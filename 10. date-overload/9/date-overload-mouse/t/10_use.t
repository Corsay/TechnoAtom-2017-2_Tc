#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 2;

BEGIN { use_ok("Local::Date"); }
BEGIN { use_ok("Local::Date::Interval"); }

my $date20 = Local::Date->new(year => 2017, month => 5, day => 1, hours => 3, minutes => 20, seconds => 50);

print "\n";
print "seconds - ".$date20->seconds()."; minutes - ".$date20->minutes().";\n";
# 						50								20

my $time_part = $date20->seconds();
$date20->seconds( $time_part + 25 );
print "seconds - ".$date20->seconds()."; minutes - ".$date20->minutes()."; hours - ".$date20->hours().";\n";
# 						15								21							3

$time_part = $date20->minutes();
$date20->minutes( $time_part + 49 );
print "seconds - ".$date20->seconds()."; minutes - ".$date20->minutes()."; hours - ".$date20->hours()."; day - ".$date20->day().";\n";
# 						15									10								4							1

$time_part = $date20->hours();
$date20->hours( $time_part + 25 );
print "seconds - ".$date20->seconds()."; minutes - ".$date20->minutes()."; hours - ".$date20->hours()."; day - ".$date20->day()."; month - ".$date20->month().";\n";
# 						15									10								5							2							5

$time_part = $date20->day();
$date20->day( $time_part + 60 );
print "seconds - ".$date20->seconds()."; minutes - ".$date20->minutes()."; hours - ".$date20->hours()."; day - ".$date20->day()."; month - ".$date20->month()."; year - ".$date20->year().";\n";
# 						15									10								5							1							7							2017

$time_part = $date20->month();
$date20->month( $time_part + 14 );
print "seconds - ".$date20->seconds()."; minutes - ".$date20->minutes()."; hours - ".$date20->hours()."; day - ".$date20->day()."; month - ".$date20->month()."; year - ".$date20->year().";\n";
# 						15									10								5							1							9							2018
