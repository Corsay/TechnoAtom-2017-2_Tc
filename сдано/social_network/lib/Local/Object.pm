package Local::Object;

use strict;
use warnings;

sub new {
    my ($class, @params) = @_;

    my $object = bless {}, $class;
    $object->init(@params);

    return $object;
}

sub init {
    my ($self, @params) = @_;

    return;
}

1;
