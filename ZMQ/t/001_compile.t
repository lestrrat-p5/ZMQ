use strict;
use Test::More;

use_ok "ZMQ";

diag "Using libzmq " . ZMQ::call( "zmq_version" );

ok exists $INC{ 'ZMQ/Context.pm' }, "ZMQ::Context is loaded";
ok exists $INC{ 'ZMQ/Message.pm' }, "ZMQ::Message is loaded";
ok exists $INC{ 'ZMQ/Socket.pm' }, "ZMQ::Socket is loaded";

done_testing;