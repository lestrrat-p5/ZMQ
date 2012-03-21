use strict;
use Test::More;

BEGIN {
    use_ok "ZMQ::Constants", ":v2.1.11", ":all";
}

foreach my $set (@ZMQ::Constants::CONSTANT_SETS) {
    if ( $set->match( '2.1.11' ) ) {
        my @list = $set->get_export_oks();
        can_ok __PACKAGE__, @list;
    }
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
    ZMQ_FAIL_UNROUTABLE
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
    my $code = __PACKAGE__->can($exist),;
    ok $code, "$exist should exist in v2.1.11";
    eval {
        $code->();
    };
    ok !$@, "$exist is callable";
}



done_testing;
