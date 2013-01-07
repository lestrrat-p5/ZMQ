package ZMQ::CZMQ::Zmsg;
use strict;
use ZMQ::CZMQ;

sub new {
    my $class = shift;
    $class->_wrap( ZMQ::CZMQ::call("zmsg_new") );
}

sub _wrap {
    my $class = shift;
    bless { _msg => $_[0] }, $class;
}

BEGIN {
    # These create zframe objects
    foreach my $method (qw(
        first
        next
        last
        pop
        unwrap
    )) {
        eval <<EOM;
            sub $method {
                my \$self = shift;
                ZMQ::CZMQ::Zframe->_wrap(ZMQ::CZMQ::call("zmsg_$method", \$self->{_msg}, \@_));
            }
EOM
        die if $@;
    }

    # These create zmsg objects
    foreach my $method (qw(
        save
        load 
        dup
    )) {
        eval <<EOM;
            sub $method {
                my \$self = shift;
                ZMQ::CZMQ::Zmsg->_wrap(ZMQ::CZMQ::call("zmsg_$method", \$self->{_msg}, \@_));
            }
EOM
        die if $@;
    }

    # These accept frame as its argument
    foreach my $method (qw(
        push
        add
        wrap
        remove
    )) {
        eval <<EOM;
            sub $method {
                my \$self = shift;
                my \$frame = shift;
                ZMQ::CZMQ::call("zmsg_$method", \$self->{_msg}, \$frame->{_frame}, \@_);
            }
EOM
        die if $@;
    }

    foreach my $method (qw(
        size
        content_size
        pushmem
        addmem
        pushstr
        addstr
        popstr
        dump
    )) {
        eval <<EOM;
            sub $method {
                my \$self = shift;
                ZMQ::CZMQ::call("zmsg_$method", \$self->{_msg}, \@_);
            }
EOM
        die if $@;
    }

    # TODO: decode/encode hmmm, what to do ?
}

1;

__END__

=head1 NAME

ZMQ::CZMQ::Zmsg - Wrapper Around zmsg_t

=head1 SYNOPSIS

    use ZMQ::CZMQ;

    my $msg = zmsg_new();

    # Note: these methods invalidate the frame objects, because
    # memory ownership for the underlying buffer is now in zmq
    $msg->wrap($frame);
    $msg->push($frame);
    $msg->add($frame);

=cut