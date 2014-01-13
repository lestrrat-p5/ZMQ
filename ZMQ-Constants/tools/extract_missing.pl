#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use ZMQ::Constants qw//;

my ($header_file) = @ARGV;

my %LOOKUP = map { $_ => 0 } @{ $ZMQ::Constants::EXPORT_TAGS{all} };

open( my $fh, "<", $header_file );
while ( my $line = <$fh> ) {
    chomp($line);

    foreach my $cst ( sort keys %LOOKUP ) {
        next if $LOOKUP{$cst};

        if ( $line =~ m/
                #define
                \s+
                $cst\s+\w+/x ) {
            $LOOKUP{$cst}++;
        }

    }
}
close($fh);

while ( my ( $k, $v ) = each %LOOKUP ) {
    next if $v;
    say $k;
}

1;
