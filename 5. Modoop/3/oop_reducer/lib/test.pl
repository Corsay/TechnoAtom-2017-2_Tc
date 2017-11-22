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

my $RowJSON = Local::Row::JSON->new(str =>'{"price": 1}');
#p $RowJSON; p $RowJSON->get('price','0'); p $RowJSON->get('benefit');
my $RowJSON2 = Local::Row::JSON->new(str =>'sended:1024,received:2048');
#p $RowJSON2;
my $RowSimple = Local::Row::Simple->new(str =>'sended:1024,received:2048');
#p $RowSimple; p $RowSimple->get('sended','0'); p $RowSimple->get('received','0'); p $RowSimple->get('skipped');
my $RowSimple2 = Local::Row::Simple->new(str =>'sended:0,received:10240');

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
    initial_value => 0,
);
#p $reducerSum; 
#p $reducerSum->reduced(); 
#$reducerSum->reduce_n(1); p $reducerSum->reduced(); 
#$reducerSum->reduce_n(1); p $reducerSum->reduced(); 
#$reducerSum->reduce_n(1); p $reducerSum->reduced(); 
#$reducerSum->reduce_n(4); p $reducerSum->reduced(); 

my $reducerSum2 = Local::Reducer::Sum->new(
    field => 'price',
    source => Local::Source::Array->new(array => [
        '{"price": 1}',
        '{"price": 2}',
        '{"price": 3}',
    ]),
    row_class => 'Local::Row::JSON',
    initial_value => 5,
);
#p $reducerSum2; 
#p $reducerSum2->reduced();
#$reducerSum2->reduce_all();
#p $reducerSum2->reduced();

my $reducerMaxDiff = Local::Reducer::MaxDiff->new(
    top => 'received',
    bottom => 'sended',
    source => Local::Source::Text->new(text =>"sended:1024,received:2048\nsended:2048,received:10240\nsended:0,received:10240"),
    row_class => 'Local::Row::Simple',
    initial_value => 0,
);
#p $reducerMaxDiff; 
#p $reducerMaxDiff->reduced();
#$reducerMaxDiff->reduce_n(1); p $reducerMaxDiff->reduced(); 
#$reducerMaxDiff->reduce_n(1); p $reducerMaxDiff->reduced(); 
#$reducerMaxDiff->reduce_n(1); p $reducerMaxDiff->reduced(); 
#$reducerMaxDiff->reduce_n(4); p $reducerMaxDiff->reduced(); 

my $reducerMaxDiff2 = Local::Reducer::MaxDiff->new(
    top => 'received',
    bottom => 'sended',
    source => Local::Source::Text->new(text =>"sended:1024,received:2048\nsended:2048,received:10240\nsended:0,received:10240"),
    row_class => 'Local::Row::Simple',
    initial_value => 0,
);
#p $reducerMaxDiff2; 
#p $reducerMaxDiff2->reduced();
#$reducerMaxDiff2->reduce_all();
#p $reducerMaxDiff2->reduced();

my $RS1 = Local::Row::Simple->new( str => "" );#, {}, "empty struct";
#p $RS1;
my $RS2 = Local::Row::Simple->new( str => "key:val" );#, {key => "val"}, "one pair";
#p $RS2;
my $RS3 = Local::Row::Simple->new( str => "a:1,b:2" );#, { a => 1, b => 2 }, "two pairs";
#p $RS3;
my $RS4 = Local::Row::Simple->new( str => "test" );# undef, "no value";
#p $RS4;
my $RS5 = Local::Row::Simple->new( str => "test:test:test" );#, undef, "too many colons in pair";
#p $RS5; p $RS5->get("test");
my $RS6 = Local::Row::Simple->new( str => "test,test,test" );#, undef, "record does not have value";
#p $RS6; p $RS6->get("test");
my $RS7 = Local::Row::Simple->new( str => "key:val,test" );#, undef, "record does not have value 2";
#p $RS7; p $RS7->get("key");

my $RJ1 = Local::Row::JSON->new( str => '{}' );#, {}, "empty struct";
#p $RJ1;
my $RJ2 = Local::Row::JSON->new( str => '{"key":"val"}' );#, {key => "val"}, "one pair";
#p $RJ2;
my $RJ3 = Local::Row::JSON->new( str => '{"a":1,"b":2}' );#, { a => 1, b => 2 }, "two pairs";
#p $RJ3;
my $RJ4 = Local::Row::JSON->new( str => "test" );#, undef, "not a json";
#p $RJ4;
my $RJ5 = Local::Row::JSON->new( str => '["json must be hash"]' );#, undef, "not a hash json";
#p $RJ5;
my $RJ6 = Local::Row::JSON->new( str => '{"test":"val"' );#, undef, "unbalanced json";
#p $RJ6;

say Local::Row::JSON->new('not-a-json')->get("price");
say Local::Row::JSON->new('{"price": 0}')->get("price");
say Local::Row::JSON->new('{"price": 1}')->get("price");
say Local::Row::JSON->new('{"price": 2}')->get("price");
say Local::Row::JSON->new('[ "invalid json structure" ]')->get("price");
say Local::Row::JSON->new('{"price":"low"}')->get("price");
say Local::Row::JSON->new('{"price": 3}')->get("price");

my $sum_reducer = Local::Reducer::Sum->new(
    field => 'price',
    source => Local::Source::Array->new(array => [
        'not-a-json',
        '{"price": 0}',
        '{"price": 1}',
        '{"price": 2}',
        '[ "invalid json structure" ]',
        '{"price":"low"}',
        '{"price": 3}',
    ]),
    row_class => 'Local::Row::JSON',
    initial_value => 0,
);
p $sum_reducer;
my $sum_result;

$sum_result = $sum_reducer->reduce_n(3);
p $sum_result;#, 1, 'sum reduced 1');
p $sum_reducer->reduced;#, 1, 'sum reducer saved');

$sum_result = $sum_reducer->reduce_all();
p $sum_result;#, 6, 'sum reduced all');
p $sum_reducer->reduced;#, 6, 'sum reducer saved at the end');