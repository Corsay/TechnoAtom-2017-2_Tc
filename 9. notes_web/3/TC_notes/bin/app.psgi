#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";


# use this block if you don't need middleware, and only have a single target Dancer app to run here
use TC_notes;

TC_notes->to_app;

=begin comment
# use this block if you want to include middleware such as Plack::Middleware::Deflater

use TC_notes;
use Plack::Builder;

builder {
    enable 'Deflater';
    TC_notes->to_app;
}

=end comment

=cut

=begin comment
# use this block if you want to mount several applications on different path

use TC_notes;
use TC_notes_admin;

use Plack::Builder;

builder {
    mount '/'      => TC_notes->to_app;
    mount '/admin'      => TC_notes_admin->to_app;
}

=end comment

=cut

