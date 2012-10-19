package ZMQ::Constants;
use strict;
use base qw(Exporter);
use Carp ();

my %constants;
BEGIN {
    my $zmq_hausnumero = 156384712;
    %constants  = (
        # socket types
        ZMQ_PAIR                => 0,
        ZMQ_PUB                 => 1,
        ZMQ_SUB                 => 2,
        ZMQ_REQ                 => 3,
        ZMQ_REP                 => 4,
        ZMQ_DEALER              => 5,
        ZMQ_ROUTER              => 6,
        ZMQ_XREQ                => 5, # only on v2.x
        ZMQ_XREP                => 6, # only on v2.x
        ZMQ_PULL                => 7,
        ZMQ_PUSH                => 8,
        ZMQ_UPSTREAM            => 7, # only on v2.x
        ZMQ_DOWNSTREAM          => 8, # only on v2.x
        ZMQ_XPUB                => 9,
        ZMQ_XSUB                => 10,

        # message
        ZMQ_MSG_MORE            => 1,   # only on v2.x
        ZMQ_MAX_VSM_SIZE        => 30,  # only on v2.x
        ZMQ_DELIMITER           => 31,  # only on v2.x
        ZMQ_VSM                 => 32,  # only on v2.x
        ZMQ_MSG_SHARED          => 128, # only on v2.x
        ZMQ_MSG_MASK            => 129, # only on v2.x


        ZMQ_HWM                 => 1, # only on v2.x
        ZMQ_SWAP                => 3, # only on v2.x
        ZMQ_AFFINITY            => 4,
        ZMQ_IDENTITY            => 5,
        ZMQ_SUBSCRIBE           => 6,
        ZMQ_UNSUBSCRIBE         => 7,
        ZMQ_RATE                => 8,
        ZMQ_RECOVERY_IVL        => 9,
        ZMQ_MCAST_LOOP          => 10,
        ZMQ_SNDBUF              => 11,
        ZMQ_RCVBUF              => 12,
        ZMQ_RCVMORE             => 13,
        ZMQ_FD                  => 14,
        ZMQ_EVENTS              => 15,
        ZMQ_TYPE                => 16,
        ZMQ_LINGER              => 17,
        ZMQ_RECONNECT_IVL       => 18,
        ZMQ_BACKLOG             => 19,
        ZMQ_RECOVERY_IVL_MSEC   => 20,
        ZMQ_RECONNECT_IVL_MAX   => 21,
        ZMQ_MAXMSGSIZE          => 22,
        ZMQ_SNDHWM              => 23,
        ZMQ_RCVHWM              => 24,
        ZMQ_MULTICAST_HOPS      => 25,
        ZMQ_RCVTIMEO            => 27,
        ZMQ_SNDTIMEO            => 28,
        ZMQ_IPV4ONLY            => 31,
        ZMQ_LAST_ENDPOINT       => 32,
        ZMQ_FAIL_UNROUTABLE     => 33,

        ZMQ_MORE                => 1,
        ZMQ_NOBLOCK             => 1,
        ZMQ_DONTWAIT            => 1,
        ZMQ_SNDMORE             => 2,
        ZMQ_POLLIN              => 1,
        ZMQ_POLLOUT             => 2,
        ZMQ_POLLERR             => 4,
        ZMQ_STREAMER            => 1,
        ZMQ_FORWARDER           => 2,
        ZMQ_QUEUE               => 3,

        ZMQ_HAUSNUMERO          => $zmq_hausnumero,

        # "On Windows platform some of the standard POSIX errnos are not 
        # defined" says zmq.h
        ENOTSUP                 => $zmq_hausnumero + 1,
        EPROTONOSUPPORT         => $zmq_hausnumero + 2,
        ENOBUFS                 => $zmq_hausnumero + 3,
        ENETDOWN                => $zmq_hausnumero + 4,
        EADDRINUSE              => $zmq_hausnumero + 5,
        EADDRNOTAVAIL           => $zmq_hausnumero + 6,
        ECONNREFUSED            => $zmq_hausnumero + 7,
        EINPROGRESS             => $zmq_hausnumero + 8,
        ENOTSOCK                => $zmq_hausnumero + 9,

        # "Native 0MQ error codes." as defined in zmq.h
        EFSM                    => $zmq_hausnumero + 51,
        ENOCOMPATPROTO          => $zmq_hausnumero + 52,
        ETERM                   => $zmq_hausnumero + 53,
        EMTHREAD                => $zmq_hausnumero + 54,
    );
}

use constant \%constants;
our @EXPORT;
our @EXPORT_OK = keys %constants;
our %EXPORT_TAGS = (
    socket => [ qw(
        ZMQ_PAIR
        ZMQ_PUB
        ZMQ_SUB
        ZMQ_REQ
        ZMQ_REP
        ZMQ_DEALER
        ZMQ_ROUTER
        ZMQ_PULL
        ZMQ_PUSH
        ZMQ_XPUB
        ZMQ_XSUB
        ZMQ_AFFINITY
        ZMQ_IDENTITY
        ZMQ_SUBSCRIBE
        ZMQ_UNSUBSCRIBE
        ZMQ_RATE
        ZMQ_RECOVERY_IVL
        ZMQ_RECOVERY_IVL_MSEC
        ZMQ_SNDBUF
        ZMQ_RCVBUF
        ZMQ_RCVMORE
        ZMQ_FD
        ZMQ_EVENTS
        ZMQ_TYPE
        ZMQ_LINGER
        ZMQ_RECONNECT_IVL
        ZMQ_BACKLOG
        ZMQ_RECONNECT_IVL_MAX
        ZMQ_MAXMSGSIZE
        ZMQ_SNDHWM
        ZMQ_RCVHWM
        ZMQ_MULTICAST_HOPS
        ZMQ_RCVTIMEO
        ZMQ_SNDTIMEO
        ZMQ_IPV4ONLY
        ZMQ_LAST_ENDPOINT
        ZMQ_FAIL_UNROUTABLE
        ZMQ_DONTWAIT
        ZMQ_SNDMORE
        ZMQ_HWM
        ZMQ_SWAP
        ZMQ_NOBLOCK
    ),
    # only in v2.x
    qw(
        ZMQ_XREQ
        ZMQ_XREP
        ZMQ_UPSTREAM
        ZMQ_DOWNSTREAM
        ZMQ_HWM
        ZMQ_SWAP
    ) ],
    message => [ qw(
        ZMQ_MORE
        ZMQ_MSG_MORE
        ZMQ_MAX_VSM_SIZE
        ZMQ_DELIMITER
        ZMQ_VSM
        ZMQ_MSG_SHARED
        ZMQ_MSG_MASK
    ),
    # only in v2.x
    qw(
        ZMQ_MSG_MORE
        ZMQ_MAX_VSM_SIZE
        ZMQ_DELIMITER
        ZMQ_VSM
        ZMQ_MSG_SHARED
        ZMQ_MSG_MASK
    ) ],
    poller => [ qw(
        ZMQ_POLLIN
        ZMQ_POLLOUT
        ZMQ_POLLERR
    ) ],
    device => [ qw(
        ZMQ_STREAMER
        ZMQ_FORWARDER
        ZMQ_QUEUE
    ) ],
    errors => [ qw(
        ZMQ_HAUSNUMERO
        ENOTSUP
        EPROTONOSUPPORT
        ENOBUFS
        ENETDOWN
        EADDRINUSE
        EADDRNOTAVAIL
        ECONNREFUSED
        EINPROGRESS
        ENOTSOCK
        EFSM
        ENOCOMPATPROTO
        ETERM
        EMTHREAD
    ) ]
);
$EXPORT_TAGS{all} = [ @EXPORT_OK ];

our $VERSION = '1.01';

our $DEFAULT_VERSION = '2.1.11';

our %SOCKOPT_MAP;
sub set_sockopt_type {
    my $type = shift;
    foreach my $opt ( @_ ) {
        $SOCKOPT_MAP{ $opt } = $type;
    }
}
sub get_sockopt_type { $SOCKOPT_MAP{ $_[0] } }

set_sockopt_type(
    "int" => (
        ZMQ_TYPE,
        ZMQ_RCVMORE,
        ZMQ_SNDHWM,
        ZMQ_RCVHWM,
        ZMQ_RATE,
        ZMQ_RECOVERY_IVL,
        ZMQ_SNDBUF,
        ZMQ_RCVBUF,
        ZMQ_LINGER,
        ZMQ_RECONNECT_IVL,
        ZMQ_RECONNECT_IVL_MAX,
        ZMQ_MULTICAST_HOPS,
        ZMQ_RCVTIMEO,
        ZMQ_SNDTIMEO,
        ZMQ_IPV4ONLY,
        ZMQ_FD, # SOCKET on Windows... yikes, how do we handle this?
        ZMQ_EVENTS,
        ZMQ_BACKLOG,
    )
);

set_sockopt_type(
    "uint64" => (
        ZMQ_AFFINITY,
        ZMQ_HWM,
    )
);

set_sockopt_type(
    "int64" => (
        ZMQ_MAXMSGSIZE,
        ZMQ_RECOVERY_IVL_MSEC,
        ZMQ_SWAP,
    )
);

set_sockopt_type(
    "string" => (
        ZMQ_SUBSCRIBE,
        ZMQ_UNSUBSCRIBE,
        ZMQ_LAST_ENDPOINT,
        ZMQ_IDENTITY,
    )
);

our @CONSTANT_SETS;

sub register_set {
    my ($version, @args) = @_;
    my $cb = (ref $version eq 'CODE') ? $version : sub { $version eq $_[0] };

    push @CONSTANT_SETS, ZMQ::Constant::Set->new(
        matcher => $cb,
        @args
    );
}

sub import {
    my $class = shift;

    my ($version, @args);
    foreach my $arg ( @_ ) {
        if ( $arg =~ /^:v(\d+\.\d+\.\d+$)/ ) {
            $version = $1;
        } else {
            push @args, $arg;
        }
    }
    if (! $version ) {
        $class->export_to_level( 1, $class, @args );
        return;
    }
        
    my $klass = $version;
    $klass =~ s/\./_/g;
    $klass = "ZMQ::Constants::V$klass";
    eval "require $klass";
    if ($@) {
        Carp::croak($@);
    }

    foreach my $set ( @CONSTANT_SETS ) {
        next unless $set->match( $version );
        local %EXPORT_TAGS = (); # $set->get_tags;
        local @EXPORT_OK   = $set->get_export_oks;
        local @EXPORT      = $set->get_exports;
        $EXPORT_TAGS{all}  = [ sort @EXPORT_OK ];
        $class->export_to_level( 1, $class, @args );
        last;
    }
}

package
    ZMQ::Constant::Set;
use strict;

sub new {
    my ($class, %args) = @_;
    bless { %args }, $class;
}

sub match {
    my ($self, $key) = @_;
    $self->{matcher}->($key);
}

sub get_tags {
    my $t =  $_[0]->{tags} || {};
    return wantarray ? %$t : $t;
}

sub get_export_oks {
    my $t = $_[0]->get_tags;
    local $t->{all};
    delete $t->{all};
    my %u = map { ($_ => 1) } map { @$_ } values %$t;
    my $l = [ keys %u ];
    return wantarray ? @$l : $l;
}

sub get_exports {
    my $l = $_[0]->{exports} || [];
    return wantarray ? @$l : $l;
}

1;

__END__

=head1 NAME

ZMQ::Constants - Constants for libzmq

=head1 SYNOPSIS

    use ZMQ::Constants ':all'; # pulls in all constants for all versions
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

If don't care to be strict about which constants to import into your code, then don't bother with the ':vX.X.X' notation, just use like a normal module:

    use ZMQ::Constants qw(:all);     # pulls all known constants...
                                     # note: may contain extra constants
                                     # if we have clashes in the future
    
    use ZMQ::Constants qw(ZMQ_PUSH); # import just ZMQ_PUSH

=head1 SUPPORTED VERSIONS

I have checked that the constants for the following versions are available.
Please send pullreqs if there are new constants that are not defined.

=over 4

=item libzmq 2.1.11

=item libzmq 3.1.1

No ZMQ device related stuff

=item libzmq 3.1.2

NOTE: This is libzmq/master branch as of this writing. new constants may have been added.

Reintroduces ZMQ device related constants, and adds ZMQ_FAIL_UNROUTABLE

=back

=head1 FUNCTIONS

These functions are usually for internal use only. You should not need to
use them if you're just a ZMQ.pm user

=head2 register_set

Creates a new "set" of constants for a particular version.

=head2 get_sockopt_type

Gets the type for the given libzmq socket option. This is used when
ZMQ::getsockopt is called to determine the underlying socket option type

=head2 set_sockopt_type

Sets the type for the given libzmq socket option.

=head1 SEE ALSO

L<ZMQ::LibZMQ2>, L<ZMQ::LibZMQ3>, L<ZMQ::CZMQ>, L<ZMQ>

L<http://zeromq.org>

L<http://github.com/lestrrat/p5-ZMQ>

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 COPYRIGHT AND LICENSE

The ZeroMQ module is

Copyright (C) 2010 by Daisuke Maki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
