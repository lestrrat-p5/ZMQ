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

ZMQ::Context -

=head1 SYNOPSIS

    my $cxt = ZMQ::Context->new(1);
    my $sock = $cxt->socket( ZMQ_PUB );
    $cxt->term();

=cut