#!/usr/bin/env perl

   use AnyEvent::HTTP;

   sub download($$$) {
      my ($url, $file, $cb) = @_;

      open my $fh, "+<", $file
         or die "$file: $!";

      my %hdr;
      my $ofs = 0;

      warn stat $fh;
      warn -s _;
      if (stat $fh and -s _) {
         $ofs = -s _;
         warn "-s is ", $ofs;
         $hdr{"if-unmodified-since"} = AnyEvent::HTTP::format_date +(stat _)[9];
         $hdr{"range"} = "bytes=$ofs-";
      }

      http_get $url,
         headers   => \%hdr,
         on_header => sub {
            my ($hdr) = @_;

            if ($hdr->{Status} == 200 && $ofs) {
               # resume failed
               truncate $fh, $ofs = 0;
            }

            sysseek $fh, $ofs, 0;

            1
         },
         on_body   => sub {
            my ($data, $hdr) = @_;

            if ($hdr->{Status} =~ /^2/) {
               length $data == syswrite $fh, $data
                  or return; # abort on write errors
            }

            1
         },
         sub {
            my (undef, $hdr) = @_;

            my $status = $hdr->{Status};

            if (my $time = AnyEvent::HTTP::parse_date $hdr->{"last-modified"}) {
               utime $fh, $time, $time;
            }

            if ($status == 200 || $status == 206 || $status == 416) {
               # download ok || resume ok || file already fully downloaded
               $cb->(1, $hdr);

            } elsif ($status == 412) {
               # file has changed while resuming, delete and retry
               unlink $file;
               $cb->(0, $hdr);

            } elsif ($status == 500 or $status == 503 or $status =~ /^59/) {
               # retry later
               $cb->(0, $hdr);

            } else {
               $cb->(undef, $hdr);
            }
         }
      ;
   }

   download "http://server/somelargefile", "/tmp/somelargefile", sub {
      if ($_[0]) {
         print "OK!\n";
      } elsif (defined $_[0]) {
         print "please retry later\n";
      } else {
         print "ERROR\n";
      }
   };
