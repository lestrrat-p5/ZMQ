package ZMQ::Message;
use strict;

sub new {
    my $class = shift;
    my $msg = @_ == 1 ?
        ZMQ::call( "zmq_msg_init_data", @_ ) :
        ZMQ::call( "zmq_msg_init" )
    ;
    return $class->_wrap( $msg );
}

sub _wrap {
    my ($class, $msg) = @_;
    bless { _msg => $msg }, $class;
}

BEGIN {
    foreach my $funcname ( qw(data size close) ) {
        eval sprintf <<'EOM', $funcname, $funcname;
            sub %s {
                my ($self) = @_;
                ZMQ::call( "zmq_msg_%s", $self->{_msg} );
            }
EOM
        die if $@;
    }

    foreach my $funcname ( qw(copy move) ) {
        eval sprintf <<'EOM', $funcname, $funcname;
            sub %s {
                my ($dst, $src) = @_;
                ZMQ::call( "zmq_msg_%s", $dst->{_msg}, $src->{_msg} );
            }
EOM
        die if $@;
    }
}

1;
