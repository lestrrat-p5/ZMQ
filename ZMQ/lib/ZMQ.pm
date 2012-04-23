package ZMQ;
use strict;
our $VERSION = '1.01';
our $BACKEND;
BEGIN {
    $BACKEND ||= $ENV{PERL_ZMQ_BACKEND};
    if ( $BACKEND ) {
        eval "require $BACKEND";
        if ($@) {
            die $@;
        }
    } else {
        foreach my $lib ( qw(ZMQ::LibZMQ2 ZMQ::LibZMQ3) ) {
            eval "require $lib";
            if ($@) {
                next;
            }
            $BACKEND = $lib;
        }
    }

    if (! $BACKEND) {
        die "Could not find a suitable backend for ZMQ";
    }
}

use ZMQ::Context;
use ZMQ::Socket;
use ZMQ::Message;

sub call {
    my $funcname = shift;
    no strict 'refs';
    goto &{"${BACKEND}::$funcname"};
}

1;

__END__

=head1 NAME

ZMQ - Perl-ish Interface libzmq 

=head1 SYNOPSIS

    use ZMQ;
    use ZMQ::Constants qw(ZMQ_PUB);

    my $cxt = ZMQ::Context->new(5);
    my $sock = $cxt->socket( ZMQ_PUB );
    $sock->bind( "tcp://192.168.11.5:9999" );

    if ( $ZMQ::BACKEND eq 'ZMQ::LibZMQ2' ) {
        $sock->send( ZMQ::Message->new( "Hello" ) );
    } elsif ( $ZMQ::BACKEND eq 'ZMQ::LibZMQ3' ) {
        $sock->sendmsg( ZMQ::Message->new( "Hello" ) );
    }

=head1 DESCRIPTION

ZMQ is a Perl-ish wrapper for libzmq. It uses ZMQ::LibZMQ2 or ZMQ::LibZMQ3 (ZMQ::LibZMQ2 is the default)

If you want a one-to-one direct mapping to libzmq, then you should be using ZMQ::LibZMQ2, ZMQ::LibZMQ3 directly

ZMQ will automatically choose the backend (either ZMQ::LibZMQ2 or ZMQ::LibZMQ3) to use. This can be explicitly specified by setting C<PERL_ZMQ_BACKEND> environment variable.

By default ZMQ::LibZMQ2 will be used as the backend. This may change in future
versions, so make sure to explicitly set your backend if you don't want it to
change:

    BEGIN {
        $ENV{ PERL_ZMQ_BACKEND } = 'ZMQ::LibZMQ2';
    }
    use ZMQ;

If you think your code will be used from another program that also uses libzmq,
you might want to consider using the ZMQ::LibZMQ* modules. This is because you
can't write "truly" portable code using this high level interface (libzmq's
API change rather drastically between versions). Personally, I'd recommend
only using this module for your one-shot scripts, and use ZMQ::LibZMQ* for
all other uses. YMMV.

=head1 FUNCTIONS

=head2 ZMQ::call( $funcname, @args )

Calls C<$funcname> via whichever backend loaded by ZMQ.pm. For example if
ZMQ::LibZMQ2 is loaded:

    use ZMQ;

    my $version = ZMQ::call( "zmq_version" ); # calls ZMQ::LibZMQ2::zmq_version

If C<@args> is passed, they are passed directly to the target function.

=head1 SEE ALSO

L<http://zeromq.org>

L<http://github.com/lestrrat/p5-ZMQ>

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 COPYRIGHT AND LICENSE

The ZMQ module is

Copyright (C) 2012 by Daisuke Maki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut


