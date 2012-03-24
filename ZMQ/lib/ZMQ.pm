package ZMQ;
use strict;
our $VERSION = '1.00';
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

=cut


