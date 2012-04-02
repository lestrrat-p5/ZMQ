package ZMQ::Socket;
use strict;
use ZMQ;

sub CLONE_SKIP { 1 }

sub _wrap {
    my ($class, $sock) = @_;
    bless { _socket => $sock }, $class;
}

sub close {
    my $self = shift;
    if (! $self->{_closed}) {
        return ZMQ::call( "zmq_close", $self->{_socket} );
    }
    return;
}

BEGIN {
    foreach my $funcname ( qw( connect bind setsockopt getsockopt ) ) {
        eval sprintf <<'EOM', $funcname, $funcname;
            sub %s {
                my $self = shift;
                ZMQ::call( "zmq_%s", $self->{_socket}, @_ );
            }
EOM
        die if $@;
    }

    if ($ZMQ::BACKEND eq 'ZMQ::LibZMQ2') {
        eval <<'EOM';
            sub recv {
                my $self = shift;
                my $msg  = ZMQ::call( "zmq_recv", $self->{_socket}, @_ );
                if ( $msg ) {
                    return ZMQ::Message->_wrap( $msg );
                }
                return $msg;
            }

            sub send {
                my $self = shift;
                my $msg  = shift;

                if ( ref $msg && eval { $msg->isa( 'ZMQ::Message' ) } ) {
                    $msg = $msg->{_msg};
                }
                ZMQ::call( "zmq_send", $self->{_socket}, $msg, @_ );
            }
            sub sendmsg {
                Carp::croak( "ZMQ::Socket->sendmsg is not implemented in this version ($ZMQ::BACKEND)" );
            }
            sub recvmsg {
                Carp::croak( "ZMQ::Socket->recvmsg is not implemented in this version ($ZMQ::BACKEND)" );
            }

EOM
        die if $@;
    } else {
        eval <<'EOM';
            sub recvmsg {
                my $self = shift;
                my $msg  = ZMQ::call( "zmq_recvmsg", $self->{_socket}, @_ );
                if ( $msg ) {
                    return ZMQ::Message->_wrap( $msg );
                }
                return $msg;
            }

            sub sendmsg {
                my $self = shift;
                my $msg  = shift;

                if ( ref $msg && eval { $msg->isa( 'ZMQ::Message' ) } ) {
                    $msg = $msg->{_msg};
                }
                ZMQ::call( "zmq_sendmsg", $self->{_socket}, $msg, @_ );
            }

            sub recv {
                my $self = shift;
                my $msg  = shift;
                if ( ref $msg && eval { $msg->isa( 'ZMQ::Message' ) } ) {
                    $msg = $msg->{_msg};
                }
                ZMQ::cal( "zmq_recv", $msg, @_ );
            }
            sub send {
                my $self = shift;
                my $msg  = shift;
                if ( ref $msg && eval { $msg->isa( 'ZMQ::Message' ) } ) {
                    $msg = $msg->{_msg};
                }
                ZMQ::cal( "zmq_send", $msg, @_ );
            }
EOM
        die if $@;
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

