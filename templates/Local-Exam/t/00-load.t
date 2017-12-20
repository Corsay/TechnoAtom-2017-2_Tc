#!/usr/bin/perl
use 5.006;
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

plan tests => 1;

BEGIN {
    use_ok( 'Local::Exam' ) || print "Bail out!\n";
}

diag( "Testing Local::Exam $Local::Exam::VERSION, Perl $], $^X" );
