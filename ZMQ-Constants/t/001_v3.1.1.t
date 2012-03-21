use strict;
use Test::More;

BEGIN {
    use_ok "ZMQ::Constants", ':v3.1.1', ':all';
};

ok scalar @ZMQ::Constants::V3_1_1::EXPORT_OK > 0;
can_ok __PACKAGE__, @ZMQ::Constants::V3_1_1::EXPORT_OK;
ok ! __PACKAGE__->can('ZMQ_STREAMER'), "3.1.1 should not have devices";
ok ! __PACKAGE__->can('ZMQ_FORWARDER'), "3.1.1 should not have devices";
ok ! __PACKAGE__->can('ZMQ_QUEUE'), "3.1.1 should not have devices";
ok ! __PACKAGE__->can('ZMQ_FAIL_UNROUTABLE'), "3.1.1 should not have FAIL_UNROUTABLE";


done_testing;