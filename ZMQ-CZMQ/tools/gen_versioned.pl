use strict;

my $info = `./zmqinfo`;
my ($major) = (split /\n/, $info);

my %symbols = (
    2 => [
        'int  zsockopt_hwm (void *socket);',
        'int  zsockopt_swap (void *socket);',
        'int  zsockopt_affinity (void *socket);',
        'int  zsockopt_rate (void *socket);',
        'int  zsockopt_recovery_ivl (void *socket);',
        'int  zsockopt_recovery_ivl_msec (void *socket);',
        'int  zsockopt_mcast_loop (void *socket);',
        'int  zsockopt_sndbuf (void *socket);',
        'int  zsockopt_rcvbuf (void *socket);',
        'int  zsockopt_linger (void *socket);',
        'int  zsockopt_reconnect_ivl (void *socket);',
        'int  zsockopt_reconnect_ivl_max (void *socket);',
        'int  zsockopt_backlog (void *socket);',
        'int  zsockopt_type (void *socket);',
        'int  zsockopt_rcvmore (void *socket);',
        'int  zsockopt_fd (void *socket);',
        'int  zsockopt_events (void *socket);',
        'void zsockopt_set_hwm (void *socket, int hwm);',
        'void zsockopt_set_swap (void *socket, int swap);',
        'void zsockopt_set_affinity (void *socket, int affinity);',
        'void zsockopt_set_identity (void *socket, char * identity);',
        'void zsockopt_set_rate (void *socket, int rate);',
        'void zsockopt_set_recovery_ivl (void *socket, int recovery_ivl);',
        'void zsockopt_set_recovery_ivl_msec (void *socket, int recovery_ivl_msec);',
        'void zsockopt_set_mcast_loop (void *socket, int mcast_loop);',
        'void zsockopt_set_sndbuf (void *socket, int sndbuf);',
        'void zsockopt_set_rcvbuf (void *socket, int rcvbuf);',
        'void zsockopt_set_linger (void *socket, int linger);',
        'void zsockopt_set_reconnect_ivl (void *socket, int reconnect_ivl);',
        'void zsockopt_set_reconnect_ivl_max (void *socket, int reconnect_ivl_max);',
        'void zsockopt_set_backlog (void *socket, int backlog);',
        'void zsockopt_set_subscribe (void *socket, char * subscribe);',
        'void zsockopt_set_unsubscribe (void *socket, char * unsubscribe);',
    ],
    3 => [
        'int  zsockopt_sndhwm (void *socket);',
        'int  zsockopt_rcvhwm (void *socket);',
        'int  zsockopt_affinity (void *socket);',
        'int  zsockopt_rate (void *socket);',
        'int  zsockopt_recovery_ivl (void *socket);',
        'int  zsockopt_sndbuf (void *socket);',
        'int  zsockopt_rcvbuf (void *socket);',
        'int  zsockopt_linger (void *socket);',
        'int  zsockopt_reconnect_ivl (void *socket);',
        'int  zsockopt_reconnect_ivl_max (void *socket);',
        'int  zsockopt_backlog (void *socket);',
        'int  zsockopt_maxmsgsize (void *socket);',
        'int  zsockopt_type (void *socket);',
        'int  zsockopt_rcvmore (void *socket);',
        'int  zsockopt_fd (void *socket);',
        'int  zsockopt_events (void *socket);',
        'void zsockopt_set_sndhwm (void *socket, int sndhwm);',
        'void zsockopt_set_rcvhwm (void *socket, int rcvhwm);',
        'void zsockopt_set_affinity (void *socket, int affinity);',
        'void zsockopt_set_identity (void *socket, char * identity);',
        'void zsockopt_set_rate (void *socket, int rate);',
        'void zsockopt_set_recovery_ivl (void *socket, int recovery_ivl);',
        'void zsockopt_set_sndbuf (void *socket, int sndbuf);',
        'void zsockopt_set_rcvbuf (void *socket, int rcvbuf);',
        'void zsockopt_set_linger (void *socket, int linger);',
        'void zsockopt_set_reconnect_ivl (void *socket, int reconnect_ivl);',
        'void zsockopt_set_reconnect_ivl_max (void *socket, int reconnect_ivl_max);',
        'void zsockopt_set_backlog (void *socket, int backlog);',
        'void zsockopt_set_maxmsgsize (void *socket, int maxmsgsize);',
        'void zsockopt_set_subscribe (void *socket, char * subscribe);',
        'void zsockopt_set_unsubscribe (void *socket, char * unsubscribe);',
        'void zsockopt_set_hwm (void *socket, int hwm);',
    ],
    4 => [
        'int  zsockopt_sndhwm (void *socket);',
        'int  zsockopt_rcvhwm (void *socket);',
        'int  zsockopt_affinity (void *socket);',
        'int  zsockopt_rate (void *socket);',
        'int  zsockopt_recovery_ivl (void *socket);',
        'int  zsockopt_sndbuf (void *socket);',
        'int  zsockopt_rcvbuf (void *socket);',
        'int  zsockopt_linger (void *socket);',
        'int  zsockopt_reconnect_ivl (void *socket);',
        'int  zsockopt_reconnect_ivl_max (void *socket);',
        'int  zsockopt_backlog (void *socket);',
        'int  zsockopt_maxmsgsize (void *socket);',
        'int  zsockopt_type (void *socket);',
        'int  zsockopt_rcvmore (void *socket);',
        'int  zsockopt_fd (void *socket);',
        'int  zsockopt_events (void *socket);',
        'void zsockopt_set_sndhwm (void *socket, int sndhwm);',
        'void zsockopt_set_rcvhwm (void *socket, int rcvhwm);',
        'void zsockopt_set_affinity (void *socket, int affinity);',
        'void zsockopt_set_rate (void *socket, int rate);',
        'void zsockopt_set_recovery_ivl (void *socket, int recovery_ivl);',
        'void zsockopt_set_sndbuf (void *socket, int sndbuf);',
        'void zsockopt_set_rcvbuf (void *socket, int rcvbuf);',
        'void zsockopt_set_linger (void *socket, int linger);',
        'void zsockopt_set_reconnect_ivl (void *socket, int reconnect_ivl);',
        'void zsockopt_set_reconnect_ivl_max (void *socket, int reconnect_ivl_max);',
        'void zsockopt_set_backlog (void *socket, int backlog);',
        'void zsockopt_set_maxmsgsize (void *socket, int maxmsgsize);',
        'void zsockopt_set_subscribe (void *socket, char * subscribe);',
        'void zsockopt_set_unsubscribe (void *socket, char * unsubscribe);',
        'void zsockopt_set_hwm (void *socket, int hwm);',
    ]
);

my $this_version = delete $symbols{$major};
my %unavailable;
while ( my ($v, $list) = each %symbols ) {
    %unavailable = ( %unavailable, map { ($_ => 1) } @$list );
}
delete @unavailable{ @$this_version };

my $parse_prologue = sub {
    my ($params) = @_;
    my (@names, @decls);
    foreach my $arg ( split qr{\s*,\s*}, $params ) {
        if ($arg =~ m{^void \*socket}) {
            push @names, 'socket';
            push @decls, "PerlCZMQ_zsocket_raw *socket";
        } elsif ( $arg =~ m{^.* (\w+)$} ) {
            push @names, $1;
            push @decls, $arg;
        }
    }
    sprintf "(%s)\n%s", 
        join( ", ", @names ),
        join( "\n", map { "        $_;" } @decls )
    ;
};

foreach my $func ( @{$this_version} ) {
    $func =~ s/\((.*)\);/$parse_prologue->($1)/egx;

    print $func, "\n\n";
}

foreach my $func ( keys %unavailable) {
    $func =~ s/\((.*)\);/$parse_prologue->($1)/egx;
    my($is_void) =~ /^\s*void\s*(?!\*)/;
    my($name) = ($func =~ /\s([\S]+)\s*\(/);
    print <<EOM
$func
    CODE:
        @{[ $is_void ? "PERL_UNUSED_VAR(RETVAL);" : "" ]}
        croak( "$name is not available in this version of czmq" );

EOM
}
        

