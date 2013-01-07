package ZMQ::CZMQ::Zctx;
use strict;
use ZMQ::CZMQ;

sub new {
    bless {
        _ctx => ZMQ::CZMQ::call('zctx_new'),
        _sockets => {}
    }, shift;
}

sub socket_destroy {
    my ($self, $socket) = @_;
    ZMQ::CZMQ::call("zsocket_destroy", $self->{_ctx}, $socket->{_socket});
    delete $self->{_sockets}->{$socket};
}

sub socket {
    my $self = shift;
    my $sock = ZMQ::CZMQ::Zsocket->_wrap(
        ZMQ::CZMQ::call("zsocket_new", $self->{_ctx}, @_)
    );
    $self->{_sockets}->{$sock} = $sock;
    return $sock;
}

sub DESTROY {
    my $self = shift;
    my $sockets = $self->{_sockets};
    foreach my $k (keys %$sockets) {
        $self->socket_destroy($sockets->{$k});
    }
}

BEGIN {
    # simply proxy 
    foreach my $method (qw(destroy shadow set_io_threads set_linger set_hwm)) {
        eval <<EOM;
            sub $method {
                my \$self = shift;
                zctx_$method(\$self->{_ctx}, \@_);
            }
EOM
        die if $@;
    }
}

1;

__END__

=head1 NAME

ZMQ::CZMQ::Ctx - Wrapper Around zctx_t

=head1 SYNOPSIS

    use ZMQ::CZMQ;
    use ZMQ::Constants qw(ZMQ_REQ);

    my $ctx = ZMQ::CZMQ::Ctx->new;
    $ctx->destroy; # be careful!
    $ctx->shadow;
    $ctx->set_io_threads($io_threads);
    $ctx->set_linger($linger);
    $ctx->set_hwm($hwm);

    my $sock = $ctx->socket(ZMQ_REQ);

=head1 METHODS

=head2 destroy

=head2 new

=head2 set_hwm

=head2 set_io_threads

=head2 set_linger

=head2 shadow

=head2 socket

=head2 socket_destroy

For now, internal use for ZMQ::CZMQ::Zctx.

=cut