use strict;
use Test::More;

BEGIN {
    use_ok "ZMQ::Constants", ':v3.1.2', ':all';
};

foreach my $set (@ZMQ::Constants::CONSTANT_SETS) {
    if ( $set->match( '3.1.2' ) ) {
        my @list = $set->get_export_oks();
        can_ok __PACKAGE__, @list;
    }
}

is ZMQ_PAIR, 0, "sanity";

ok __PACKAGE__->can('ZMQ_STREAMER'), "3.1.2 should have devices";
ok __PACKAGE__->can('ZMQ_FORWARDER'), "3.1.2 should have devices";
ok __PACKAGE__->can('ZMQ_QUEUE'), "3.1.2 should have devices";
ok __PACKAGE__->can('ZMQ_FAIL_UNROUTABLE'), "3.1.2 should have ZMQ_FAIL_UNROUTABLE";

foreach my $noexist ( qw(
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
    ok ! __PACKAGE__->can($noexist), "3.1.2 should not have $noexist";
}

done_testing;