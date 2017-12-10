#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 12;

BEGIN { use_ok("Local::Date"); }
BEGIN { use_ok("Local::Date::Interval"); }

my $date1 = Local::Date->new(epoch => 1495393394); 
my $date2 = Local::Date->new(day => 1, month => 5, year => 2017, hours => 3, minutes => 20, seconds => 50);

my $int1 = Local::Date::Interval->new(duration => 7200); 
my $int2 = Local::Date::Interval->new(days => 30, hours => 5, minutes => 10, seconds => 15);

# Date cast tests
is("$date1", "Sun May 21 19:03:14 2017", "Date string 1");
is("$date2", "Mon May  1 03:20:50 2017", "Date string 2");

$date1->format("%F %T");
$date2->format("%D %r");
is("$date1", "2017-05-21 19:03:14",  "Date string format 1");
is("$date2", "05/01/17 03:20:50 AM", "Date string format 2");

is(0+$date1, 1495393394, "Date number 1");
is(0+$date2, 1493608850, "Date number 2");

# Interval cast tests
is("$int1", "0 days, 2 hours, 0 minutes, 0 seconds",    "Interval string 1");
is("$int2", "30 days, 5 hours, 10 minutes, 15 seconds", "Interval string 2");

is(0+$int1, 7200,    "Interval number 1");
is(0+$int2, 2610615, "Interval number 2");
