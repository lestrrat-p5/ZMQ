use strict;
use Test::More;
use Test::Requires qw(Test::TCP Proc::Guard);
use ZMQ::LibZMQ3;
use ZMQ::Constants ':v3.1.1', ':all';

my $MAX_MESSAGES = 1_000;

my $port = Test::TCP::empty_port();
my $server = Proc::Guard->new(code => sub {
    my $ctxt = zmq_init();
    my $sender = zmq_socket($ctxt, ZMQ_PUSH);
    zmq_bind( $sender, "tcp://*:$port");

    # XXX hacky synchronization
    sleep 3;

    # The first message is "0" and signals start of batch
    #$sender->send('0');

    my $ident=0;
    while ($ident < $MAX_MESSAGES) {
        note "sending ".$ident++,"\n";
        zmq_sendmsg($sender, zmq_msg_init_data($ident));
    }

    note "Done sending";
    sleep(1);              # Give 0MQ time to deliver
});

{
    my $ctxt = zmq_init();

    # Socket to receive messages on
    my $receiver = zmq_socket($ctxt, ZMQ_PULL);
    zmq_connect($receiver, "tcp://localhost:" . $port);

    for my $expected (1..$MAX_MESSAGES) {
        my $msg = zmq_recvmsg($receiver);
        is zmq_msg_data($msg), $expected;
    }
}

undef $server;

done_testing;

