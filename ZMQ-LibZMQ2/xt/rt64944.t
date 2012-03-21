use strict;
use Test::More;
BEGIN {
    if (! $ENV{TEST_LEAK}) {
        plan skip_all => "Set TEST_LEAK to run leak tests";
    }
}

use Test::Requires 'Test::Valgrind';

do 't/rt64944.t';

