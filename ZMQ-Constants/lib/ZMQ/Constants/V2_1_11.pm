package ZMQ::Constants::V2_1_11;
use strict;
use base qw(ZMQ::Constants::Basic);

use constant +{
    ZMQ_MCAST_LOOP          => 10,
    ZMQ_MAX_VSM_SIZE        => 30,
    ZMQ_DELIMITER           => 31,
    ZMQ_VSM                 => 32,
    ZMQ_MSG_MORE            => 1,
    ZMQ_MSG_SHARED          => 128,
    ZMQ_MSG_MASK            => 129,
    ZMQ_HWM                 => 1,
    ZMQ_SWAP                => 3,
    ZMQ_RECOVERY_IVL_MSEC   => 20,
    ZMQ_NOBLOCK             => 1,
};

my %not_in_v2 = (
    ZMQ_MAXMSGSIZE          => 22,
    ZMQ_SNDHWM              => 23,
    ZMQ_RCVHWM              => 24,
    ZMQ_MULTICAST_HOPS      => 25,
    ZMQ_RCVTIMEO            => 27,
    ZMQ_SNDTIMEO            => 28,
    ZMQ_IPV4ONLY            => 31,
    ZMQ_LAST_ENDPOINT       => 32,
);

*ZMQ_XREQ = \&ZMQ::Constants::Basic::ZMQ_DEALER;
*ZMQ_XREP = \&ZMQ::Constants::Basic::ZMQ_ROUTER;
*ZMQ_UPSTREAM = \&ZMQ::Constants::Basic::ZMQ_PULL;
*ZMQ_DOWNSTREAM = \&ZMQ::Constants::Basic::ZMQ_PUSH;

our @EXPORT_OK = (
    (grep { ! $not_in_v2{$_} } @ZMQ::Constants::Basic::EXPORT_OK),
    qw(
        ZMQ_MCAST_LOOP
        ZMQ_MAX_VSM_SIZE
        ZMQ_DELIMITER
        ZMQ_VSM
        ZMQ_MSG_MORE
        ZMQ_MSG_SHARED
        ZMQ_MSG_MASK
        ZMQ_HWM
        ZMQ_SWAP
        ZMQ_RECOVERY_IVL_MSEC
        ZMQ_NOBLOCK
        ZMQ_UPSTREAM
        ZMQ_DOWNSTREAM
        ZMQ_XREP
        ZMQ_XREQ
    )
);
our %EXPORT_TAGS = (
    socket => [ qw(
        ZMQ_PAIR
        ZMQ_PUB
        ZMQ_SUB
        ZMQ_REQ
        ZMQ_REP
        ZMQ_XREQ
        ZMQ_XREP
        ZMQ_XSUB
        ZMQ_XPUB
        ZMQ_ROUTER
        ZMQ_DEALER
        ZMQ_PULL
        ZMQ_PUSH
        ZMQ_UPSTREAM
        ZMQ_DOWNSTREAM
        ZMQ_BACKLOG
    ),
# socket send/recv flags
    qw(
        ZMQ_NOBLOCK
        ZMQ_SNDMORE
    ),
# get/setsockopt options
    qw(
        ZMQ_HWM
        ZMQ_SWAP
        ZMQ_AFFINITY
        ZMQ_IDENTITY
        ZMQ_SUBSCRIBE
        ZMQ_UNSUBSCRIBE
        ZMQ_RATE
        ZMQ_RECOVERY_IVL
        ZMQ_RECOVERY_IVL_MSEC
        ZMQ_MCAST_LOOP
        ZMQ_SNDBUF
        ZMQ_RCVBUF
        ZMQ_RCVMORE
        ZMQ_RECONNECT_IVL
        ZMQ_RECONNECT_IVL_MAX
        ZMQ_LINGER
        ZMQ_FD
        ZMQ_EVENTS
        ZMQ_TYPE
    ),
# i/o multiplexing
    qw(
        ZMQ_POLLIN
        ZMQ_POLLOUT
        ZMQ_POLLERR
    ),
    ],
# devices
    device => [ qw(
        ZMQ_QUEUE
        ZMQ_FORWARDER
        ZMQ_STREAMER
    ), ],
# max size of vsm message
    message => [ qw(
        ZMQ_MAX_VSM_SIZE
    ),
# message types
    qw(
        ZMQ_DELIMITER
        ZMQ_VSM
    ),
# message flags
    qw(
        ZMQ_MSG_MORE
        ZMQ_MSG_SHARED
        ZMQ_MSG_MASK
    ),]
);
$EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ];

1;
