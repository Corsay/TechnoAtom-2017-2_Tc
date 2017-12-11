#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 2;

BEGIN { use_ok("Local::Date"); }
BEGIN { use_ok("Local::Date::Interval"); }

my $date1 = Local::Date->new(epoch => 1495393394); 
my $date2 = Local::Date->new(day => 1, month => 5, year => 2017, hours => 3, minutes => 20, seconds => 50);

my $int1 = Local::Date::Interval->new(duration => 7200); 
my $int2 = Local::Date::Interval->new(days => 30, hours => 5, minutes => 10, seconds => 15);

# Date operations test
my $date3 = $date1 + 10;
print $date3+0 . "\n";
print "1495393404 - expected\n\n";

my $date4 = $date1 + $int1;
print $date4 . "\n";
print "Sun May 21 21:03:14 2017 - expected\n\n";

print $date1 . "\n";
print "Sun May 21 19:03:14 2017 - expected\n";