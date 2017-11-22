#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use FindBin; use lib "$FindBin::Bin/../lib";


use DDP;

### Source test
use Local::Source::Array 1.0;
use Local::Source::Text;

my $SourceArray = Local::Source::Array->new(array => [
        '{"price": 1}',
        '{"price": 2}',
        '{"price": 3}',
    ]);
#p $SourceArray; p $SourceArray->next(); p $SourceArray->next(); p $SourceArray->next(); p $SourceArray->next();
my $SourceText = Local::Source::Text->new(text =>"sended:1024,received:2048\nsended:2048,received:10240");
#p $SourceText;
my $SourceTextDelim = Local::Source::Text->new(text =>"sended:1024,received:2048\nsended:2048,received:10240", delimiter => ',');
#p $SourceTextDelim;


### Row test
use Local::Row::JSON;
use Local::Row::Simple;

my $RowJSON = Local::Row::JSON->new('{"price": 1}');
#p $RowJSON; p $RowJSON->get('price','0'); p $RowJSON->get('benefit');
my $RowJSON2 = Local::Row::JSON->new('sended:1024,received:2048');
#p $RowJSON2;
my $RowSimple = Local::Row::Simple->new('sended:1024,received:2048');
#p $RowSimple; p $RowSimple->get('sended','0'); p $RowSimple->get('received','0'); p $RowSimple->get('skipped');


### Reducer test
use Local::Reducer::Sum;
use Local::Reducer::MaxDiff;

my $reducerSum = Local::Reducer::Sum->new(
    field => 'price',
    source => Local::Source::Array->new(array => [
        '{"price": 1}',
        '{"price": 2}',
        '{"price": 3}',
    ]),
    row_class => 'Local::Row::JSON',
    initial_value => 5,
);
p $reducerSum; p $reducerSum->reduced();

my $reducerMaxDiff = Local::Reducer::MaxDiff->new(
    top => 'received',
    bottom => 'sended',
    source => Local::Source::Text->new(text =>"sended:1024,received:2048\nsended:2048,received:10240"),
    row_class => 'Local::Row::Simple',
    initial_value => 0,
);
p $reducerMaxDiff; p $reducerMaxDiff->reduced();
