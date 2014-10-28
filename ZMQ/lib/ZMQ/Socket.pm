package ZMQ::Socket;
use strict;
use ZMQ;
use ZMQ::Constants qw/ZMQ_SNDMORE ZMQ_RCVMORE/;
use Sub::Name ();

sub CLONE_SKIP { 1 }

sub _wrap {
    my ($class, $sock) = @_;
    bless { _socket => $sock }, $class;
}

sub send_multipart {
    my ($self, $msg, $flags) = @_;

    $flags = 0 if !defined $flags;

    my @frames = @$msg;

    if (@frames) { # There is at least one part
        my $last = pop @frames;
        for (@frames) {
            $self->_send_message($_, ZMQ_SNDMORE|$flags);
        }
        $self->_send_message($last, $flags);
    }

    return;
}

sub recv_multipart {
    my ($self, $flags) = @_;
    $flags = 0 if !defined $flags;

    my @frames;

    push @frames, $self->_recv_message($flags);

    while ($self->getsockopt(ZMQ_RCVMORE)) {
        push @frames, $self->_recv_message($flags);
    }

    return @frames;
}

sub close {
    my $self = shift;
    if (! $self->{_closed}) {
        return ZMQ::call( "zmq_close", $self->{_socket} );
    }
    return;
}

BEGIN {
    my %methods;

    foreach my $funcname ( qw( connect bind setsockopt getsockopt ) ) {
        $methods{$funcname} = sub {
            my $self = shift;
            ZMQ::call( "zmq_$funcname", $self->{_socket}, @_ );
        };
    }

    if ($ZMQ::BACKEND eq 'ZMQ::LibZMQ2') {
        $methods{recv} = sub {
            my $self = shift;
            my $msg  = ZMQ::call( "zmq_recv", $self->{_socket}, @_ );
            if ( ref $msg && eval { $msg->isa('ZMQ::LibZMQ2::Message') } ) {
                return ZMQ::Message->_wrap( $msg );
            }
            return;
        };
        $methods{send} = sub {
            my $self = shift;
            my $msg  = shift;

            if ( ref $msg && eval { $msg->isa( 'ZMQ::Message' ) } ) {
                $msg = $msg->{_msg};
            }
            ZMQ::call( "zmq_send", $self->{_socket}, $msg, @_ );
        };
        $methods{sendmsg} = sub {
            Carp::croak( "ZMQ::Socket->sendmsg is not implemented in this version ($ZMQ::BACKEND)" );
        };
        $methods{recvmsg} = sub {
            Carp::croak( "ZMQ::Socket->recvmsg is not implemented in this version ($ZMQ::BACKEND)" );
        }
    } else {
        $methods{"recvmsg"} = sub {
            my $self = shift;
            my $msg  = ZMQ::call( "zmq_recvmsg", $self->{_socket}, @_ );
            if ( ref $msg && eval { $msg->isa('ZMQ::LibZMQ3::Message') } ) {
                return ZMQ::Message->_wrap( $msg );
            }
            return;
        };
        $methods{sendmsg} = sub {
            my $self = shift;
            my $msg  = shift;

            if ( ref $msg && eval { $msg->isa( 'ZMQ::Message' ) } ) {
                $msg = $msg->{_msg};
            }
            ZMQ::call( "zmq_sendmsg", $self->{_socket}, $msg, @_ );
        };
        $methods{recv} = sub {
            my $self = shift;
            my $msg  = shift;
            if ( ref $msg && eval { $msg->isa( 'ZMQ::Message' ) } ) {
                $msg = $msg->{_msg};
            }
            ZMQ::call( "zmq_recv", $msg, @_ );
        };
        $methods{send} = sub {
            my $self = shift;
            my $msg  = shift;
            if ( ref $msg && eval { $msg->isa( 'ZMQ::Message' ) } ) {
                $msg = $msg->{_msg};
            }
            ZMQ::call( "zmq_send", $msg, @_ );
        };
    }

    foreach my $name (keys %methods) {
        no strict 'refs';
        *{$name} = Sub::Name::subname($name, $methods{$name});
    }


    if ($ZMQ::BACKEND eq 'ZMQ::LibZMQ2') {
        *_send_message = \&send;
        *_recv_message = \&recv;
    }
    else {
        *_send_message = \&sendmsg;
        *_recv_message = \&recvmsg;
    }
}

1;

__END__


=head1 NAME

ZMQ::Socket - ZMQ Socket object

=head1 SYNOPSIS

    use ZMQ;
    use ZMQ::Constants qw(ZMQ_PUSH);

    my $cxt  = ZMQ::Context->new();
    my $sock = $cxt->socket( ZMQ_PUSH );

    # zmq 2.1.x
    $sock->send( $msg );
    my $msg = $sock->recv();

    # zmq 3.1.x
    $sock->send( $data, $len, $flags );
    $sock->recv( $msg, $len, $flags );
    $sock->sendmsg( $msg );
    my $msg = $sock->recvmsg();

=head1 DESCRIPTION

A ZMQ::Socket object represents a 0MQ socket.

ZMQ::Socket object can only be created via ZMQ::Context objects, so there are
no public constructors.

The types of sockets that you can create, and the semantics of the socket
object varies greatly on the underlying version of libzmq, so please read
the documents for libzmq for details.

=head1 METHODS

=head2 bind

The C<bind($endpoint)> method function creates an endpoint for accepting
connections and binds it to the socket.

=over 2

=item inproc

Local in-process (inter-thread) communication transport.

=item ipc

Local inter-process communication transport.

=item tcp

Unicast transport using TCP.

=item pgm, epgm

Reliable multicast transport using PGM.

=back

=head2 connect

Connect to an existing endpoint. Takes an enpoint string as argument,
see the documentation for C<bind($endpoint)> above.

If an error occurs ( C<zmq_connect()> returns a non-zero status ), then an exception is throw.

=head2 close

Closes and terminates the socket.

=head2 send 

The semantics of this function varies greatly depending on the underlying 
version of libzmq. 

For ZMQ::LibZMQ2:

    $sock->send( $msg [, $flags] );
    $sock->send( $raw_string [, $flags] );

For ZMQ::LibZMQ3:

    $sock->send( $msg, $len [, $flags] );

=head2 sendmsg ( $msg [, $flags] )

The C<sendmsg($msg, $flags)> method queues the given message to be sent to the
socket. The flags argument is a combination of the flags defined below.

C<sendmsg> is only available if you are using C<ZMQ::LibZMQ3> as the underlying library.

=head2 recv

The semantics of this function varies greatly depending on the underlying 
version of libzmq. 

For ZMQ::LibZMQ2:

    $msg = $sock->recv();

For ZMQ::LibZMQ3:

    $sock->recv( $msg, $len [, $flags] );

=head2 recvmsg

The C<my $msg = $sock-E<gt>recvmsg($flags)> method receives a message from
the socket and returns it as a new C<ZMQ::Message> object.
If there are no messages available on the specified socket
the C<recvmsg()> method blocks until the request can be satisfied.
The flags argument is a combination of the flags defined below.

C<recvmsg> is only available if you are using C<ZMQ::LibZMQ3> as the underlying library.

=head2 send_multipart( \@frames [, $flags] )

The C<send_multipart(\@frames, $flags)> method sends a multipart message to the
socket. The method will send the frames with the C<ZMQ_SNDMORE> flag, except
for the last. The flags argument is a combination of the flags defined below.
There is no return value.

This method will use the right method for sending independent of the backend
that is used.

=head2 recv_multipart( [$flags] )

The C<recv_multipart($flags)> method receives a multipart message from the
socket and returns an array of C<ZMQ::Message> objects. The method will receive
frames as long as the C<ZMQ_RCVMORE> flag is set on the socket. The flags argument
is a combination of the flags defined below.

This method will use the right method for receiving independent of the backend
that is used.

=head2 getsockopt

The C<my $optval = $sock-E<gt>getsockopt(ZMQ_SOME_OPTION)> method call
retrieves the value for the given socket option.

The list of option names (constants) varies depending on the underlying libzmq 
version. Please refer to the manual for libzmq for the correct list.

=head2 setsockopt

The C<$sock-E<gt>setsockopt(ZMQ_SOME_OPTION, $value)> method call
sets the specified option to the given value.

The list of option names (constants) varies depending on the underlying libzmq 
version. Please refer to the manual for libzmq for the correct list.

=head1 CAVEATS

C<ZMQ::Socket> objects aren't thread safe due to the underlying library.
Therefore, they are currently not cloned when a new Perl ithread is spawned. 
The variables in the new thread that contained the socket in the parent 
thread will be a scalar reference to C<undef> in the new thread.
This makes the Perl wrapper thread safe (i.e. no segmentation faults).

=head1 SEE ALSO

L<ZMQ>, L<ZMQ::Socket>

L<http://zeromq.org>

=head1 AUTHOR

Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 COPYRIGHT AND LICENSE

The ZMQ module is

Copyright (C) 2010 by Daisuke Maki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

