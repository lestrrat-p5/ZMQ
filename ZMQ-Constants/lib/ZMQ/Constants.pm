package ZMQ::Constants;
use strict;

our $VERSION = '1.00';

our $DEFAULT_VERSION = '3.1.1';

sub import {
    my $class = shift;

    my ($version, @args);
    foreach my $arg ( @_ ) {
        if ( $arg =~ s/^:v(?=\d+\.\d+\.\d+$)// ) {
            $version = $arg;
        } else {
            push @args, $arg;
        }
    }

    $version ||= $DEFAULT_VERSION;
    $version =~ s/\./_/g;
    my $klass   = "ZMQ::Constants::V$version";
    eval sprintf <<EOM, $klass, $klass;
        require %s;
        %s->export_zmq_symbols(\@args);
EOM
    if ($@) {
        die $@;
    }
}

1;

__END__

=head1 NAME

ZMQ::Constants - Constants for ZMQ

=head1 SYNOPSIS

    use ZMQ::Constants ':all'; # pulls in constants from $DEFAULT_VERSION
    use ZMQ::Constants ':v3.1.1', ':all'; # pulls in constants for 3.1.1
    use ZMQ::Constants ':v3.1.2', ':all'; # pulls in constants for 3.1.2

=head1 DESCRIPTION

libzmq is a fast-chanding beast and constants get renamed, new one gest
removed, etc... 

We used to auto-generate constants from the libzmq source code, but then
adpating the binding code to this change got very tedious, and controling
which version contains which constants got very hard to manage.

This module is now separate from ZMQ main code, and lists the constants
statically. You can also specify which set of constants to pull in depending
on the zmq version.

=head1 SUPPORTED VERSIONS

=over 4

=item libzmq 3.1.1

=item libzmq 3.1.2

Reintroduces ZMQ device related constants, and adds ZMQ_FAIL_UNROUTABLE

=back

If you would like to add more sets, please send in a pullreq

=cut
