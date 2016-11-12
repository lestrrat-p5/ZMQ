package ZMQ::Constants::V4_0_4;
use strict;
use warnings;
use ZMQ::Constants ();
use Storable       ();

my %not_in_v4 = map { ( $_ => 1 ) } qw(

  ZMQ_DELIMITER
  ZMQ_DOWNSTREAM
  ZMQ_HWM
  ZMQ_MAX_VSM_SIZE
  ZMQ_MCAST_LOOP
  ZMQ_MSG_MASK
  ZMQ_MSG_MORE
  ZMQ_MSG_SHARED
  ZMQ_RECOVERY_IVL_MSEC
  ZMQ_SWAP
  ZMQ_UPSTREAM
  ZMQ_VSM
  ZMQ_TOS
  ZMQ_IPC_FILTER_PID
  ZMQ_IPC_FILTER_UID
  ZMQ_IPC_FILTER_GID
  ZMQ_CONNECT_RID
  ZMQ_GSSAPI_SERVER
  ZMQ_GSSAPI_PRINCIPAL
  ZMQ_GSSAPI_SERVICE_PRINCIPAL
  ZMQ_GSSAPI_PLAINTEXT
  ZMQ_HANDSHAKE_IVL
  ZMQ_SOCKS_PROXY
  ZMQ_XPUB_NODROP
  ZMQ_BLOCKY
  ZMQ_XPUB_MANUAL
  ZMQ_XPUB_WELCOME_MSG
  ZMQ_STREAM_NOTIFY
  ZMQ_INVERT_MATCHING
  ZMQ_HEARTBEAT_IVL
  ZMQ_HEARTBEAT_TTL
  ZMQ_HEARTBEAT_TIMEOUT
  ZMQ_XPUB_VERBOSER
  ZMQ_CONNECT_TIMEOUT
  ZMQ_TCP_MAXRT
  ZMQ_THREAD_SAFE
  ZMQ_MULTICAST_MAXTPDU
  ZMQ_VMCI_BUFFER_SIZE
  ZMQ_VMCI_BUFFER_MIN_SIZE
  ZMQ_VMCI_BUFFER_MAX_SIZE
  ZMQ_VMCI_CONNECT_TIMEOUT
  ZMQ_USE_FD

);

my $export_tags = Storable::dclone( \%ZMQ::Constants::EXPORT_TAGS );
$export_tags->{socket} = [
    'ZMQ_FAIL_UNROUTABLE', grep { !$not_in_v4{$_} } @{ $export_tags->{socket} }
];
$export_tags->{message} =
  [ grep { !$not_in_v4{$_} } @{ $export_tags->{message} } ];

ZMQ::Constants::register_set( '4.0.4' => ( tags => $export_tags, ) );

1;
