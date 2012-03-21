package ZMQ::Constants::V2_1_11;
use strict;
use Storable ();
use ZMQ::Constants ();

ZMQ::Constants::add_constant(
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
    ZMQ_XREQ                => ZMQ::Constants::ZMQ_DEALER(),
    ZMQ_XREP                => ZMQ::Constants::ZMQ_ROUTER(),
    ZMQ_UPSTREAM            => ZMQ::Constants::ZMQ_PULL(),
    ZMQ_DOWNSTREAM          => ZMQ::Constants::ZMQ_PUSH(),
);

my %not_in_v2 = (
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
);

my $export_tags = Storable::dclone( \%ZMQ::Constants::EXPORT_TAGS );
$export_tags->{socket} = [
    (grep { ! $not_in_v2{$_} } @{ $export_tags->{socket} }),
    qw(
        ZMQ_MCAST_LOOP
        ZMQ_MAX_VSM_SIZE
        ZMQ_DELIMITER
        ZMQ_VSM
        ZMQ_HWM
        ZMQ_SWAP
        ZMQ_RECOVERY_IVL_MSEC
        ZMQ_NOBLOCK
        ZMQ_XREQ
        ZMQ_XREP
        ZMQ_UPSTREAM
        ZMQ_DOWNSTREAM
    ),
];
$export_tags->{message} = [ qw(ZMQ_MSG_MORE ZMQ_MSG_SHARED ZMQ_MSG_MASK) ];

ZMQ::Constants::register_set(
    '2.1.11' => (
        tags => $export_tags
    )
);

1;
