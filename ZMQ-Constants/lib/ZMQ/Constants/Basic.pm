package ZMQ::Constants::Basic;
use strict;
use base qw(Exporter);

my %constants;
BEGIN {
    %constants  = (
        ZMQ_PAIR                => 0,
        ZMQ_PUB                 => 1,
        ZMQ_SUB                 => 2,
        ZMQ_REQ                 => 3,
        ZMQ_REP                 => 4,
        ZMQ_DEALER              => 5,
        ZMQ_ROUTER              => 6,
        ZMQ_PULL                => 7,
        ZMQ_PUSH                => 8,
        ZMQ_XPUB                => 9,
        ZMQ_XSUB                => 10,
        ZMQ_AFFINITY            => 4,
        ZMQ_IDENTITY            => 5,
        ZMQ_SUBSCRIBE           => 6,
        ZMQ_UNSUBSCRIBE         => 7,
        ZMQ_RATE                => 8,
        ZMQ_RECOVERY_IVL        => 9,
        ZMQ_SNDBUF              => 11,
        ZMQ_RCVBUF              => 12,
        ZMQ_RCVMORE             => 13,
        ZMQ_FD                  => 14,
        ZMQ_EVENTS              => 15,
        ZMQ_TYPE                => 16,
        ZMQ_LINGER              => 17,
        ZMQ_RECONNECT_IVL       => 18,
        ZMQ_BACKLOG             => 19,
        ZMQ_RECONNECT_IVL_MAX   => 21,
        ZMQ_MAXMSGSIZE          => 22,
        ZMQ_SNDHWM              => 23,
        ZMQ_RCVHWM              => 24,
        ZMQ_MULTICAST_HOPS      => 25,
        ZMQ_RCVTIMEO            => 27,
        ZMQ_SNDTIMEO            => 28,
        ZMQ_IPV4ONLY            => 31,
        ZMQ_LAST_ENDPOINT       => 32,
        ZMQ_MORE                => 1,
        ZMQ_DONTWAIT            => 1,
        ZMQ_SNDMORE             => 2,
        ZMQ_POLLIN              => 1,
        ZMQ_POLLOUT             => 2,
        ZMQ_POLLERR             => 4,
        ZMQ_STREAMER            => 1,
        ZMQ_FORWARDER           => 2,
        ZMQ_QUEUE               => 3,
    );
}

use constant \%constants;
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
        ZMQ_DONTWAIT
        ZMQ_SNDMORE
    ) ],
    message => [ qw(
        ZMQ_MORE
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
);
$EXPORT_TAGS{all} = [ @EXPORT_OK ];

sub export_zmq_symbols {
    my $class = shift;
#    local @ZMQ::Constants::Basic::EXPORT_OK   = @EXPORT_OK;
#    local %ZMQ::Constants::Basic::EXPORT_TAGS = %EXPORT_TAGS;

    # levels
    # ZMQ::Constants::import
    # ZMQ::Constants::eval
    # ZMQ::Constants::V3_1_1
    $class->export_to_level(3, $class, @_);
}

1;
