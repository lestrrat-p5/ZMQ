use strict;
use Test::More;
use Test::Requires qw(Test::TCP Proc::Guard);
use ZMQ::LibZMQ3;
use ZMQ::Constants ':all';

sub start_proxy {
    my @ports = map { Test::TCP::empty_port() } 1..3;

    my $proc = Proc::Guard->new(code => sub {
        my $in_addr  = sprintf 'tcp://127.0.0.1:%d', $ports[0];
        my $out_addr = sprintf 'tcp://127.0.0.1:%d', $ports[1];
        my $cap_addr = sprintf 'tcp://127.0.0.1:%d', $ports[2];

        my $ctx     = zmq_init(1);
        my $sub_in  = zmq_socket($ctx, ZMQ_SUB);
        my $pub_out = zmq_socket($ctx, ZMQ_PUB);
        my $cap_out = zmq_socket($ctx, ZMQ_PUB);

        zmq_setsockopt($sub_in, ZMQ_SUBSCRIBE, '');
        zmq_bind($sub_in,  $in_addr);
        zmq_bind($pub_out, $out_addr);
        zmq_bind($cap_out, $cap_addr);

        note "Starting proxy.. IN -> $in_addr, OUT -> $out_addr, CAP -> $cap_addr";
        zmq_proxy($sub_in, $pub_out, $cap_out);
        diag "Proxy process exiting";
    });

    # Wait till the proxy is up
    Test::TCP::wait_port($_) for @ports;

    return ($proc, @ports);
}

sub start_publisher {
    my ($port, $messages) = @_;

    my $proc = Proc::Guard->new(code => sub {
        note "Sleeping for 3 seconds to give the main process to set up things";
        sleep 3;
        my $ctx = zmq_init();
        my $sock = zmq_socket($ctx, ZMQ_PUB);

        my $endpoint = sprintf "tcp://127.0.0.1:%d", $port;
        note "Publisher: connect to $endpoint";
        if (zmq_connect($sock, $endpoint) != 0) {
            die "Failed to connect to $endpoint: $!";
        }
        note "Sleeping for 1 seconds to give time for the zmq_connect() to, you know, connect...";
        sleep 1;

        foreach my $topic (keys %$messages) {
            my @messages = @{$messages->{$topic}};
            unshift @messages, $topic;
            for (my $i = 0; $i < @messages; $i++) {
                my @args = ($messages[$i]);
                if ($i < $#messages) {
                    push @args, ZMQ_SNDMORE;
                }
                note "Sending '@args'...";
                if (zmq_sendmsg($sock, @args) != length($messages[$i])) {
                    die "Failed to send message: $!";
                }
            }
        }
    });
    return $proc;
}

sub start_capturer {
    my $port = shift;

    return Proc::Guard->new(code => sub {
        my $ctx = zmq_init();
        my $sock = zmq_socket($ctx, ZMQ_SUB);

        my $endpoint = sprintf "tcp://127.0.0.1:%d", $port;
        note "Capturer: connect to $endpoint";
        zmq_setsockopt($sock, ZMQ_SUBSCRIBE, '');
        zmq_connect($sock, $endpoint);

        while (1) {
            my $msg = zmq_recvmsg($sock);
            next unless $msg;
            note "Capture: Received " . zmq_msg_data($msg);
        }
    });
}

my %messages = (
    hello_world => [ "This is a simple Hello, World!", "Hope you had a nice day" ],
    random_string => [ map { rand(10000000) } 1..10 ],
    ordered_ints => [ 1..100 ],
);

my ($proxy_proc, $in_port, $out_port, $cap_port) = start_proxy();
my $publisher_proc = start_publisher($in_port, \%messages);
my $cap_proc = start_capturer($cap_port);

# The main process is the subscriber
{
    my $ctx = zmq_init();
    my $sock = zmq_socket($ctx, ZMQ_SUB);

    my $endpoint = sprintf "tcp://127.0.0.1:%d", $out_port;
    note "Subscriber: connect to $endpoint";
    zmq_setsockopt($sock, ZMQ_SUBSCRIBE, '');
    zmq_connect($sock, $endpoint);
    
    my $timeout = time() + 20;
    my $loop = 1;
    while ($loop && $timeout > time()) {
        my $msg = zmq_recvmsg($sock, ZMQ_DONTWAIT);
        if (! $msg) {
            note "no message received...";
            select(undef, undef, undef, rand());
            next;
        }
        my $topic;
        my $fragments;
        while ($msg) {
            note "Received message...";
            my $data = zmq_msg_data($msg);
            if (! $topic) {
                $topic = $data;
                note "Received topic $topic";
                if (! ok ($fragments = delete $messages{$topic})) {
                    diag "Could not find messages for topic $topic!";
                    die;
                }
            } else {
                my $expect = shift @$fragments;
                is $data, $expect, "Got expected message for topic $topic";
            }

            if (zmq_getsockopt($sock, ZMQ_RCVMORE)) {
                note "RCVMORE = true, try zmq_recvmsg again";
                $msg = zmq_recvmsg($sock);
            } else {
                note "We're done reading messages for topic $topic";
                undef $msg;
            }
        }

        if (scalar keys %messages <= 0) {
            $loop = 0;
        }
        note "new iteration!";
    }

    ok scalar keys %messages == 0, "Exhausted messages";
}

done_testing;
