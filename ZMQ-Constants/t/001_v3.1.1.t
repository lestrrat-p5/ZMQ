use strict;
use Test::More;

BEGIN {
    use_ok "ZMQ::Constants", ':v3.1.1', ':all';
};

foreach my $set (@ZMQ::Constants::CONSTANT_SETS) {
    if ( $set->match( '3.1.1' ) ) {
        my @list = $set->get_export_oks();
        can_ok __PACKAGE__, @list;
    }
}

ok ! __PACKAGE__->can('ZMQ_STREAMER'), "3.1.1 should not have devices";
ok ! __PACKAGE__->can('ZMQ_FORWARDER'), "3.1.1 should not have devices";
ok ! __PACKAGE__->can('ZMQ_QUEUE'), "3.1.1 should not have devices";
ok ! __PACKAGE__->can('ZMQ_FAIL_UNROUTABLE'), "3.1.1 should not have FAIL_UNROUTABLE";


done_testing;