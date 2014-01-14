use strict;
use Test::More;

BEGIN {
    use_ok "ZMQ::Constants", ':v4.0.4', ':all';
};

foreach my $set (@ZMQ::Constants::CONSTANT_SETS) {
    if ( $set->match( '4.0.4' ) ) {
        my @list = $set->get_export_oks();
        can_ok __PACKAGE__, @list;
    }
}

is ZMQ_PAIR, 0, "sanity";

ok __PACKAGE__->can('ZMQ_STREAMER'), "4.0.4 should have devices";
ok __PACKAGE__->can('ZMQ_FORWARDER'), "4.0.4 should have devices";
ok __PACKAGE__->can('ZMQ_QUEUE'), "4.0.4 should have devices";
ok __PACKAGE__->can('ZMQ_FAIL_UNROUTABLE'), "4.0.4 should have ZMQ_FAIL_UNROUTABLE";

foreach my $noexist ( qw(

            ZMQ_DELIMITER
            ZMQ_DOWNSTREAM
            ZMQ_HWM
            ZMQ_MAX_VSM_SIZE
            ZMQ_MCAST_LOOP
            ZMQ_MSG_MASK
            ZMQ_MSG_MORE
            ZMQ_MSG_SHARED
            ZMQ_RECOVERY_IVL_MSEC
            ZMQ_SWAP
            ZMQ_UPSTREAM
            ZMQ_VSM

            ) ) {
    ok ! __PACKAGE__->can($noexist), "4.0.4 should not have $noexist";
}

done_testing;
