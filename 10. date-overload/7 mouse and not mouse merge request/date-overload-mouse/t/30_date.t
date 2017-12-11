#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 33;

BEGIN { use_ok("Local::Date"); }
BEGIN { use_ok("Local::Date::Interval"); }

my $date1 = Local::Date->new(epoch => 1495393394);
my $date2 = Local::Date->new(day => 1, month => 5, year => 2017, hours => 3, minutes => 20, seconds => 50);

my $int1 = Local::Date::Interval->new(duration => 7200);
my $int2 = Local::Date::Interval->new(days => 30, hours => 5, minutes => 10, seconds => 15);

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
