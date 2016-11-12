package ZMQ::Constants::V2_1_11;
use strict;
use warnings;
use Storable ();
use ZMQ::Constants ();

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
    ZMQ_FAIL_UNROUTABLE     => 1,
    ZMQ_ROUTER_BEHAVIOR     => 33,
    ZMQ_ROUTER_MANDATORY    => 33,
    ZMQ_TCP_KEEPALIVE       => 34,
    ZMQ_TCP_KEEPALIVE_CNT   => 35,
    ZMQ_TCP_KEEPALIVE_IDLE  => 36,
    ZMQ_TCP_KEEPALIVE_INTVL => 37,
    ZMQ_DELAY_ATTACH_ON_CONNECT => 39,
    ZMQ_IMMEDIATE           => 39,
    ZMQ_XPUB_VERBOSE        => 40,
    ZMQ_ROUTER_RAW          => 41,
    ZMQ_IPV6                => 42,
    ZMQ_MECHANISM           => 43,
    ZMQ_PLAIN_SERVER        => 44,
    ZMQ_PLAIN_USERNAME      => 45,
    ZMQ_PLAIN_PASSWORD      => 46,
    ZMQ_CURVE_SERVER        => 47,
    ZMQ_CURVE_PUBLICKEY     => 48,
    ZMQ_CURVE_SECRETKEY     => 49,
    ZMQ_CURVE_SERVERKEY     => 50,
    ZMQ_PROBE_ROUTER        => 51,
    ZMQ_REQ_CORRELATE       => 52,
    ZMQ_REQ_RELAXED         => 53,
    ZMQ_CONFLATE            => 54,
    ZMQ_ZAP_DOMAIN          => 55,
    ZMQ_ROUTER_HANDOVER     => 56,
    ZMQ_TOS                 => 57,
    ZMQ_IPC_FILTER_PID      => 58,
    ZMQ_IPC_FILTER_UID      => 59,
    ZMQ_IPC_FILTER_GID      => 60,
    ZMQ_CONNECT_RID         => 61,
    ZMQ_GSSAPI_SERVER       => 62,
    ZMQ_GSSAPI_PRINCIPAL    => 63,
    ZMQ_GSSAPI_SERVICE_PRINCIPAL => 64,
    ZMQ_GSSAPI_PLAINTEXT    => 65,
    ZMQ_HANDSHAKE_IVL       => 66,
    ZMQ_SOCKS_PROXY         => 68,
    ZMQ_XPUB_NODROP         => 69,
    ZMQ_BLOCKY              => 70,
    ZMQ_XPUB_MANUAL         => 71,
    ZMQ_XPUB_WELCOME_MSG    => 72,
    ZMQ_STREAM_NOTIFY       => 73,
    ZMQ_INVERT_MATCHING     => 74,
    ZMQ_HEARTBEAT_IVL       => 75,
    ZMQ_HEARTBEAT_TTL       => 76,
    ZMQ_HEARTBEAT_TIMEOUT   => 77,
    ZMQ_XPUB_VERBOSER       => 78,
    ZMQ_CONNECT_TIMEOUT     => 79,
    ZMQ_TCP_MAXRT           => 80,
    ZMQ_THREAD_SAFE         => 81,
    ZMQ_MULTICAST_MAXTPDU   => 84,
    ZMQ_VMCI_BUFFER_SIZE    => 85,
    ZMQ_VMCI_BUFFER_MIN_SIZE => 86,
    ZMQ_VMCI_BUFFER_MAX_SIZE => 87,
    ZMQ_VMCI_CONNECT_TIMEOUT => 88,
    ZMQ_USE_FD              => 89,
);

my $export_tags = Storable::dclone( \%ZMQ::Constants::EXPORT_TAGS );
$export_tags->{socket} = [
    (grep { ! $not_in_v2{$_} } @{ $export_tags->{socket} }),
];
$export_tags->{message} = [ qw(ZMQ_MAX_VSM_SIZE ZMQ_DELIMITER ZMQ_VSM ZMQ_MSG_MORE ZMQ_MSG_SHARED ZMQ_MSG_MASK) ];

ZMQ::Constants::register_set(
    '2.1.11' => (
        tags => $export_tags
    )
);

1;
