use strict;
use Test::More;

BEGIN {
    use_ok "ZMQ::Constants", ":v2.1.11", ":all";
}

foreach my $noexist ( qw(
    ZMQ_MAXMSGSIZE
    ZMQ_SNDHWM
    ZMQ_RCVHWM
    ZMQ_MULTICAST_HOPS
    ZMQ_RCVTIMEO
    ZMQ_SNDTIMEO
    ZMQ_IPV4ONLY
    ZMQ_LAST_ENDPOINT
)) {
    ok ! __PACKAGE__->can($noexist), "$noexist should not exist in v2.1.11";
}

foreach my $exist ( qw(
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
) ) {
    ok __PACKAGE__->can($exist), "$exist should exist in v2.1.11";
}

done_testing;
