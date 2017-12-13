#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 60;

BEGIN { use_ok("Local::Date"); }
BEGIN { use_ok("Local::Date::Interval"); }

my $date1 = Local::Date->new(epoch => 1495393394);
my $date2 = Local::Date->new(day => 1, month => 5, year => 2017, hours => 3, minutes => 20, seconds => 50);

my $int1 = Local::Date::Interval->new(duration => 7200);
my $int2 = Local::Date::Interval->new(days => 30, hours => 5, minutes => 10, seconds => 15);

is($date1->year,        2017, "Date 1 year");
is($date1->month,          5, "Date 1 month");
is($date1->day,           21, "Date 1 day");
is($date1->hours,         19, "Date 1 hours");
is($date1->minutes,        3, "Date 1 minutes");
is($date1->seconds,       14, "Date 1 seconds");
is($date1->epoch, 1495393394, "Date 1 epoch");
is($date2->year,        2017, "Date 2 year");
is($date2->month,          5, "Date 2 month");
is($date2->day,            1, "Date 2 day");
is($date2->hours,          3, "Date 2 hours");
is($date2->minutes,       20, "Date 2 minutes");
is($date2->seconds,       50, "Date 2 seconds");
is($date2->epoch, 1493608850, "Date 2 epoch");

# Date operations test
my $date3 = $date1 + 10;
is($date3, 1495393404, "Date '+' integer");

my $date4 = $date1 + $int1;
is($date4, "Sun May 21 21:03:14 2017", "Date '+' interval");
is($date1, "Sun May 21 19:03:14 2017", "Date '+' interval original");

my $date5 = eval { $date1 + $date2 };
is($date5, undef, "Date '+' date error");
is($date1, "Sun May 21 19:03:14 2017", "Date '+' date original 1");
is($date2, "Mon May  1 03:20:50 2017", "Date '+' date original 2");

my $date6 = $date1 - 10;
is($date6, 1495393384, "Date '-' integer");

my $date7 = $date1 - $int2;
is($date7, "Fri Apr 21 13:52:59 2017", "Date '-' interval");
is($date1, "Sun May 21 19:03:14 2017", "Date '-' interval original");

my $date8 = $date1 - $date2;
is($date8, "20 days, 15 hours, 42 minutes, 24 seconds", "Date '-' date");
is($date1, "Sun May 21 19:03:14 2017", "Date '-' date original 1");
is($date2, "Mon May  1 03:20:50 2017", "Date '-' date original 2");

my $date9 = eval { 10 - $date1 };
is($date9, undef, "Number '-' date error");
is($date1, "Sun May 21 19:03:14 2017",  "Nubmer '-' date original");

my $date10 = eval { $int1 - $date1 };
is($date10, undef, "Interval '-' date error");
is($date1, "Sun May 21 19:03:14 2017",  "Interval '-' date original");

$date1 += 10;
is($date1, "Sun May 21 19:03:24 2017", "Date '+=' number");

$date2 += $int2;
is($date2, "Wed May 31 08:31:05 2017", "Date '+=' interval");

is(eval { $date1 += $date2 }, undef, "Date '+=' date error");
is($date1, "Sun May 21 19:03:24 2017", "Date '+=' date original 1");
is($date2, "Wed May 31 08:31:05 2017", "Date '+=' date original 2");

$date1 -= 3600;
is($date1, "Sun May 21 18:03:24 2017", "Date '-=' number");

$date2 -= $int1;
is($date2, "Wed May 31 06:31:05 2017", "Date '-=' interval");

is(eval { $date1 -= $date2 }, undef, "Date '-=' date error");
is($date1, "Sun May 21 18:03:24 2017", "Date '-=' date original 1");
is($date2, "Wed May 31 06:31:05 2017", "Date '-=' date original 2");

$date1++;
is($date1, "Sun May 21 18:03:25 2017",  "Date '++'");

$date2--;
is($date2, "Wed May 31 06:31:04 2017",  "Date '--'");

ok($date1 < $date2, "Date compare date");
ok($date1 > 7200, "Date compare number");
ok($date1 > $int1, "Date compare interval");

# date creation error test
my $date11 = eval { Local::Date->new(); };
is($date11, undef, "Error: No params");
$date11 = eval { Local::Date->new(day => 1, month => 5, year => 2017, hours => 3, minutes => 20); };
is($date11, undef, "Error: Not enought params: seconds");
$date11 = eval { Local::Date->new(day => 1, month => 5, year => 2017, hours => 3, seconds => 50); };
is($date11, undef, "Error: Not enought params: minutes");
$date11 = eval { Local::Date->new(day => 1, month => 5, year => 2017, minutes => 20, seconds => 50); };
is($date11, undef, "Error: Not enought params: hours");
$date11 = eval { Local::Date->new(day => 1, month => 5, hours => 3, minutes => 20, seconds => 50); };
is($date11, undef, "Error: Not enought params: year");
$date11 = eval { Local::Date->new(day => 1, year => 2017, hours => 3, minutes => 20, seconds => 50); };
is($date11, undef, "Error: Not enought params: month");
$date11 = eval { Local::Date->new(month => 5, year => 2017, hours => 3, minutes => 20, seconds => 50); };
is($date11, undef, "Error: Not enought params: day");

# date epoch changes tests
my $date13 = Local::Date->new(year => 2017, month => 5, day => 1, hours => 3, minutes => 20, seconds => 50);
my $date14 = Local::Date->new(year => 2017, month => 5, day => 1, hours => 3, minutes => 20, seconds => 51);
my $date15 = Local::Date->new(year => 2017, month => 5, day => 1, hours => 3, minutes => 21, seconds => 51);
my $date16 = Local::Date->new(year => 2017, month => 5, day => 1, hours => 4, minutes => 21, seconds => 51);
my $date17 = Local::Date->new(year => 2017, month => 5, day => 2, hours => 4, minutes => 21, seconds => 51);
my $date18 = Local::Date->new(year => 2017, month => 6, day => 2, hours => 4, minutes => 21, seconds => 51);
my $date19 = Local::Date->new(year => 2018, month => 6, day => 2, hours => 4, minutes => 21, seconds => 51);
$date13->seconds( $date13->seconds() + 1 );
is($date13 - $date14 + 0, 0, "Add one second check");
$date13->minutes( $date13->minutes() + 1 );
is($date13 - $date15 + 0, 0, "Add one minute check");
$date13->hours( $date13->hours() + 1 );
is($date13 - $date16 + 0, 0, "Add one hour check");
$date13->day( $date13->day() + 1 );
is($date13 - $date17 + 0, 0, "Add one day check");
$date13->month( $date13->month() + 1 );
is($date13 - $date18 + 0, 0, "Add one month check");
$date13->year( $date13->year() + 1 );
is($date13 - $date19 + 0, 0, "Add one year check");
