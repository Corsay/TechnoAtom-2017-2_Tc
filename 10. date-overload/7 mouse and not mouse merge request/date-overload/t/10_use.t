#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 2;

BEGIN { use_ok("Local::Date"); }
BEGIN { use_ok("Local::Date::Interval"); }
