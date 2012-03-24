package ZMQ::Socket;
use strict;
use ZMQ;

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
    foreach my $funcname ( qw( connect bind send recv setsockopt getsockopt ) ) {
        eval sprintf <<'EOM', $funcname, $funcname;
            sub %s {
                my $self = shift;
                ZMQ::call( "zmq_%s", $self->{_socket}, @_ );
            }
EOM
        die if $@;
    }

    foreach my $funcname ( qw( recvmsg sendmsg ) ) {
        eval sprintf <<'EOM', $funcname, $funcname, $funcname;
            sub %s {
                if ( $ZMQ::BACKEND->isa('ZMQ::LibZMQ2') ) {
                    Carp::croak( "%s is not implemented in this version ($ZMQ::BACKEND)" );
                }
                my $self = shift;
                ZMQ::call( "zmq_%s", $self->{_socket}, @_ );
            }
EOM
        die if $@;
    }
}

1;
