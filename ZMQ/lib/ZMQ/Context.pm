package ZMQ::Context;
use strict;
use ZMQ::Socket;

sub new {
    my $class = shift;
    $class->_wrap( ZMQ::call("zmq_init", @_) );
}

sub _wrap {
    my ($class, $cxt) = @_;
    bless { _cxt => $cxt, _sockets => [] }, $class;
}

sub term { 
    my $self = shift;
    foreach my $socket (@{ $self->{_sockets} }) {
        $socket->close();
    }

    ZMQ::call( "zmq_term", $self->{_cxt} );
}

sub socket {
    my $self = shift;
    my $sock = ZMQ::Socket->_wrap( 
        ZMQ::call( "zmq_socket", $self->{_cxt}, @_ )
    );
    push @{$self->{_sockets}}, $sock;
    return $sock;
}
    

1;

__END__

=head1 NAME

ZMQ::Context - ZMQ Context Object

=head1 SYNOPSIS

    my $cxt = ZMQ::Context->new(1);
    my $sock = $cxt->socket( ZMQ_PUB );
    $cxt->term();

=head1 DESCRIPTION

A ZMQ::Context object represents a 0MQ context.

=head1 METHODS

=head2 ZMQ::Context->new($io_threads)

Creates a new context object. Calls C<zmq_init>

=head2 $cxt->socket( $sock_type )

Creates a new socket object of C<$sock_type>.

=head2 $cxt->term();

Terminates the currenct context. May block if there are pending I/O operations.

=cut