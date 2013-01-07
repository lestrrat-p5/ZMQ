package ZMQ::CZMQ::Zsocket;
use strict;
use ZMQ::CZMQ;
use Scalar::Util ();

sub _wrap {
    my $class = shift;
    bless { _socket => $_[0] }, $class;
}

# Oh why, oh why did you name zsocket_destroy and
# yet you made the first argument zctx_t, not zsocket_t?
sub destroy {
    my ($self, $ctx) = @_;
    $ctx->socket_destroy($self);
}

BEGIN {
    foreach my $method (qw(bind connect disconnect poll type_str)) {
        eval <<EOM;
            sub $method {
                my \$self = shift;
                ZMQ::CZMQ::call("zsocket_$method", \$self->{_socket}, \@_);
            }
EOM
        die if $@;
    }
}

sub send {
    my $self = shift;
    my $thing = shift;

    my $klass = Scalar::Util::blessed($thing);
    if (! $klass) { # 
        return ZMQ::CZMQ::call("zstr_send", $self->{_socket}, $thing, @_);
    } else {
        return $thing->send($self);
    }
}

sub sendm {
    my $self = shift;
    return ZMQ::CZMQ::call("zstr_sendm", $self->{_socket}, @_);
}

1;

__END__

=head1 NAME

    use ZMQ::CZMQ;
    use ZMQ::Constants (ZMQ_REQ);

    my $ctx = ZMQ::CZMQ::Ctx->new;
    my $sock = $ctx->socket(ZMQ_REQ);
    $sock->bind($endpoint);
    $sock->connect($endpoint);
    $sock->disconnect;
    $sock->poll($msecs);
    $sock->type_str;
    $sock->destroy($ctx);

    # send() is overloaded
    $sock->send($msg);
    $sock->send($frame);
    $sock->send($fmt, ...);

    $sock->sendm($fmt, ...);

=cut