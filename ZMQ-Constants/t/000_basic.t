use strict;
use Test::More;

BEGIN {
    use_ok "ZMQ::Constants", ":all" ;
}

can_ok __PACKAGE__, @ZMQ::Constants::EXPORT_OK;

done_testing;