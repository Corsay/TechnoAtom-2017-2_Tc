#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 32;

BEGIN { use_ok("Local::Date::Interval"); }

my $int1 = Local::Date::Interval->new(duration => 7200);
my $int2 = Local::Date::Interval->new(days => 30, hours => 5, minutes => 10, seconds => 15);

 is($int1->days,           0, "Interval 1 days");
 is($int1->hours,          2, "Interval 1 hours");
 is($int1->minutes,        0, "Interval 1 minutes");
 is($int1->seconds,        0, "Interval 1 seconds");
 is($int1->duration,    7200, "Interval 1 duration");
 is($int2->days,          30, "Interval 2 days");
 is($int2->hours,          5, "Interval 2 hours");
 is($int2->minutes,       10, "Interval 2 minutes");
 is($int2->seconds,       15, "Interval 2 seconds");
 is($int2->duration, 2610615, "Interval 2 duration");

# Interval operations test
my $int3 = $int1 + 20;
is($int3, 7220, "Interval '+' nubmer");

my $int4 = $int1 + $int2;
is($int4, "30 days, 7 hours, 10 minutes, 15 seconds", "Interval '+' interval");

my $int5 = $int1 - 20;
is($int5, 7180, "Interval '-' nubmer");

my $int6 = $int2 - $int1;
is($int6, "30 days, 3 hours, 10 minutes, 15 seconds", "Interval '-' interval");

$int1 += 10;
is($int1, "0 days, 2 hours, 0 minutes, 10 seconds", "Interval '+=' number");

$int2 += $int1;
is($int2, "30 days, 7 hours, 10 minutes, 25 seconds", "Interval '+=' interval");

$int1 -= 3600;
is($int1, "0 days, 1 hours, 0 minutes, 10 seconds", "Interval '-=' number");

$int2 -= $int1;
is($int2, "30 days, 6 hours, 10 minutes, 15 seconds", "Interval '-=' interval");

$int1++;
is($int1, "0 days, 1 hours, 0 minutes, 11 seconds",  "Interval '++'");

$int2--;
is($int2, "30 days, 6 hours, 10 minutes, 14 seconds",  "Interval '--'");

ok($int1 < $int2, "Interval compare interval");
ok($int1 > 60, "Interval compare number");

# date creation error test
my $int7 = eval { Local::Date::Interval->new(); };
is($int7, undef, "Error: No params");
$int7 = eval { Local::Date::Interval->new(days => 30, hours => 5, minutes => 10); };
is($int7, undef, "Error: Not enought params: seconds");
$int7 = eval { Local::Date::Interval->new(days => 30, hours => 5, seconds => 15); };
is($int7, undef, "Error: Not enought params: minutes");
$int7 = eval { Local::Date::Interval->new(days => 30, minutes => 10, seconds => 15); };
is($int7, undef, "Error: Not enought params: hours");
$int7 = eval { Local::Date::Interval->new(hours => 5, minutes => 10, seconds => 15); };
is($int7, undef, "Error: Not enought params: days");

# date duration changes tests
my $int8  = Local::Date::Interval->new(days => 30, hours => 5, minutes => 10, seconds => 15);
my $int9  = Local::Date::Interval->new(days => 30, hours => 5, minutes => 10, seconds => 16);
my $int10 = Local::Date::Interval->new(days => 30, hours => 5, minutes => 11, seconds => 16);
my $int11 = Local::Date::Interval->new(days => 30, hours => 6, minutes => 11, seconds => 16);
my $int12 = Local::Date::Interval->new(days => 31, hours => 6, minutes => 11, seconds => 16);
$int8->seconds( $int8->seconds() + 1 );
is($int8 - $int9 + 0, 0, "Add one second check");
$int8->minutes( $int8->minutes() + 1 );
is($int8 - $int10 + 0, 0, "Add one minute check");
$int8->hours( $int8->hours() + 1 );
is($int8 - $int11 + 0, 0, "Add one hour check");
$int8->days( $int8->days() + 1 );
is($int8 - $int12 + 0, 0, "Add one day check");
