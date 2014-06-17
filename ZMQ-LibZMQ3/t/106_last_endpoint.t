use strict;
use Test::More;
use File::Temp;

BEGIN {
    use_ok "ZMQ::LibZMQ3";
    use_ok "ZMQ::Constants", ":v3.1.1", qw(ZMQ_REQ ZMQ_LAST_ENDPOINT);
}

my $path = File::Temp->new(UNLINK => 0);

my $ctxt = zmq_init();
my $sock = zmq_socket($ctxt, ZMQ_REQ );
my $set_endpoint = $^O eq 'MSWin32' ? 'inproc://test' : "ipc://$path";
zmq_connect( $sock, $set_endpoint );

my $read_endpoint = zmq_getsockopt($sock, ZMQ_LAST_ENDPOINT);
is($read_endpoint, $set_endpoint, 'getsockopt ZMQ_LAST_ENDPOINT');
note('length($set_endpoint)  = ', length($set_endpoint));
note('length($read_endpoint) = ', length($read_endpoint));

unlink $path;

done_testing;
