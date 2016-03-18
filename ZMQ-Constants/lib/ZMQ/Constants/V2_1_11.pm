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
