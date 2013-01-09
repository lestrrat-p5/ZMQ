use inc::Module::Install;

do "tools/detect_zmq.pl";
do "tools/detect_czmq.pl";

name 'ZMQ-LibCZMQ1';
all_from 'lib/ZMQ/LibCZMQ1.pm';

use_xshelper '-clean';
cc_warnings;

if ($ENV{ZMQ_INCLUDES}) {
    $ENV{CZMQ_INCLUDES} =
        join " ", $ENV{ZMQ_INCLUDES}, $ENV{CZMQ_INCLUDES};
}

if ($ENV{ZMQ_LIBS}) {
    $ENV{CZMQ_LIBS} =
        join " ", $ENV{ZMQ_LIBS}, $ENV{CZMQ_LIBS};
}

cc_include_paths split/\s+/, $ENV{CZMQ_INCLUDES};
cc_libs "$ENV{CZMQ_LIBS} -lzmq -lczmq";
cc_include_paths 'src';
cc_src_paths 'src';
cc_assert_lib 'zmq', 'czmq';

sub myguard (&) {
    bless [ $_[0] ], 'myguard';
}
sub myguard::DESTROY {
    $_[0]->[0]->();
}

my @clean = qw(xs/*.inc xs/typemap);

my $zmqcheck_dir = "tools/zmqcheck";
{
    my $pwd = Cwd::abs_path();
    my $guard = myguard { chdir $pwd };
    chdir $zmqcheck_dir;
    if (system($^X, "Makefile.PL") != 0) {
        die "Failed to execute $zmqcheck_dir/Makefile.PL";
    }

    foreach my $file (glob("*.c")) {
        my $name = $file;
        $name =~ s/\.c$//;
        push @clean, "$zmqcheck_dir/$name.c";
        print STDERR "CHECK: Does your zmq have $name...";

        my $ok = (system("make", $name) == 0);
        print STDERR " @{[$ok ? 'YES' : 'NO']}\n";
        if ($ok) {
            cc_define sprintf "-DHAS_%s", uc $name;
        }
    }
    print STDERR "Cleaning up $zmqcheck_dir...\n";
    system "make", "clean";
}



if ($ENV{CZMQ_VOID_RETURN_VALUES}) {
    cc_define qq{-DCZMQ_VOID_RETURN_VALUES};
}

do 'tools/genfiles.pl';

clean_files @clean;

auto_set_repository;
requires 'ZMQ::Constants';

WriteAll;