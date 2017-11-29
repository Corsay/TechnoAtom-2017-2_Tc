#!/usr/bin/env perl

use strict;
use warnings;
use FindBin; use lib "$FindBin::Bin/../lib/";

use Local::SocialNetwork;
use DDP;

my $soc = Local::SocialNetwork->new("Текст");
p $soc;
$soc->print;
