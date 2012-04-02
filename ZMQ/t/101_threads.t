BEGIN {
     require Config;
     if (!$Config::Config{useithreads}) {
        print "1..0 # Skip: no ithreads\n";
        exit 0;
     }
}

use strict;
use warnings;
use threads;
use Test::More;
use Test::Fatal;
use ZMQ;
use ZMQ::Constants qw/:all/;

note 'sanity'; {
    my $cxt = ZMQ::Context->new(1);
    isa_ok($cxt, 'ZMQ::Context');

    my $main_socket = $cxt->socket(ZMQ_PUSH);
    isa_ok($main_socket, "ZMQ::Socket");
    $main_socket->close();

    my $t = threads->new(sub {
        note "created thread " . threads->tid;
        my $sock = $cxt->socket(ZMQ_PAIR );
        ok $sock, "created server socket";
        is exception {
            $sock->bind("inproc://myPrivateSocket");
        }, undef, "bound server socket";
    
        my $client = $cxt->socket(ZMQ_PAIR); # sender
        ok $client, "created client socket";
        is exception {
            $client->connect("inproc://myPrivateSocket");
        }, undef, "connected client socket";

        my $data;
        if ( $ZMQ::BACKEND eq 'ZMQ::LibZMQ2' ) {
            $client->send( "Wee Woo" );
            $data = $sock->recv();
        } else {
            $client->sendmsg( "Wee Woo" );
            $data = $sock->recvmsg();
        }
        my $ok = 0;
        if (ok $data, "got data") {
            $ok = is $data->data(), "Wee Woo", "got same message";
        }
        return $ok;
    });

    note "Now waiting for thread to join";
    my $ok = $t->join();

    note "Thread joined";
    ok($ok, "socket and context not defined in subthread");
};

note 'invalidate socket between threads'; {
    my $cxt = ZMQ::Context->new();
    my $sock = $cxt->socket( ZMQ_PUSH );
    my $msg = ZMQ::Message->new( "Wee Woo" );
    my $t   = threads->create( sub {
        my ($t_cxt, $t_sock, $t_msg) = @_;
        ok $t_cxt;
        is $$t_sock, undef;
        return $t_msg->data eq "Wee Woo" &&
            $t_msg->size() == 7;
    }, $cxt, $sock, $msg );
    my $ok = $t->join();
    ok $ok, "cxt and message is available, but socket is under in a different thread";
};

done_testing;

