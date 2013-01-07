package ZMQ::CZMQ::Zframe;
use strict;
use ZMQ::CZMQ;
use Scalar::Util ();

sub new {
    my $class = shift;
    $class->_wrap(ZMQ::CZMQ::call("zframe_new", @_));
}

sub _wrap {
    my ($class, $frame) = @_;
    bless { _frame => $frame }, $class;
}

sub dup {
    my $self = shift;
    my $class = Scalar::Util::blessed($self);
    $class->_wrap( ZMQ::CZMQ::call("zframe_dup", $self->{_frame}) );
}

sub send {
    ZMQ::CZMQ::call("zframe_send", $_[0], $_[1]->{_socket});
}

# TODO: zframe_new_zero_copy

BEGIN {
    # those that construct a new zframe (dup is a special case)
    foreach my $method (qw(recv recv_nowait)) {
        eval <<EOM;
            sub $method {
                my \$class = shift;
                my \$raw_frame = ZMQ::CZMQ::call("zframe_$method", \@_);
                if (! \$raw_frame) {
                    return;
                }
                return \$class->_wrap(\$raw_frame);
            }
EOM
        die if $@;
    }


    foreach my $method (qw(destroy size data strhex strdup streq zero_copy more eq print reset)) {
        eval <<EOM;
            sub $method {
                my \$self = shift;
                ZMQ::CZMQ::call("zframe_$method", \$self->{_frame}, \@_);
            }
EOM
        die if $@;
    }
}

1;

__END__

=head1 NAME

ZMQ::CZMQ::Zframe - Wrapper Around zframe_t

=head1 SYNOPSIS

    use ZMQ::CZMQ;

    my $frame = zframe_new("foo", 3);

=cut