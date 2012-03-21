use strict;
use Test::More;

BEGIN {
    use_ok "ZMQ::Constants::Basic";
    ZMQ::Constants::Basic->import( @ZMQ::Constants::Basic::EXPORT_OK );
}

can_ok __PACKAGE__, @ZMQ::Constants::Basic::EXPORT_OK;

done_testing;