use strict;
use Test::More;
use_ok "ZMQ::LibZMQ3";

my ($major, $minor, $patch) = ZMQ::LibZMQ3::zmq_version();
my $version = join('.', $major, $minor, $patch);
my $warning = sprintf(<<EOM, $version);

*** WARNING ***

You're using libzmq '%s'!

It is known that when used with libzmq < 2.1, some calls to 
    \$socket->recv()
does not terminate even when a signal is sent (in such cases you
need to resort to using SIGKILL). 

You should really be thinking about upgrading your libzmq to 2.1 or
higher, and recompile ZMQ::LibZMQ3.pm against the new library.

***************

EOM

diag sprintf( 
    "\n   This is ZMQ::LibZMQ3.pm version %s\n   Linked against zeromq2 %s\n%s",
    $ZMQ::LibZMQ3::VERSION,
    $version, 
    ($major + $minor / 10) < 2.1 ? $warning : ''
);



done_testing;
