# Let's start with the basics. If we detect that this is git clone,
# then it's very likely that we don't have all the Module::Install
# plugins and such, so run a separate script to detect it.
# Otherwise, do the usual.
BEGIN {
    if (-e '../.git') {
        do 'tools/check_mi_mods.pl';
    } else {
        unshift @INC, 'inc';
        require inc::Module::Install;
        Module::Install->import;
    }
}

# Usual boilder plate...
name 'ZMQ-LibZMQ3';
all_from 'lib/ZMQ/LibZMQ3.pm';

# Detect libzmq, and display it for sanity
do 'tools/detect_zmq.pl';
print "Detected the following ZMQ settings:\n";
foreach my $env (qw(ZMQ_HOME ZMQ_H ZMQ_INCLUDES ZMQ_LIBS ZMQ_TRACE)) {
    printf " + %s = %s\n", $env, exists $ENV{$env} ? $ENV{$env} : "(null)";
}

if (-f $ENV{ZMQ_H}) {
    printf "Detecting zmq version...\n";
    open my $fh, '<', $ENV{ZMQ_H} or die;
    my %version;
    while (<$fh>) {
        if (/#define\s+ZMQ_VERSION_(MAJOR|MINOR|PATCH)\s+(\d+)$/) {
            $version{$1} = $2;
        }
    }

    printf " + Detected libzmq version %d.%d.%d\n",
        $version{MAJOR},
        $version{MINOR},
        $version{PATCH},
    ;

    if ( $version{MAJOR} * 10000 + $version{MINOR} * 100 + $version{PATCH} < 30100) {
        print <<EOM;
*** WHAO THERE! ***

We have detected that you have libzmq version lower than 3.1.x.
ZMQ::LibZMQ3 only works with libzmq versions >= 3.1.0

Make sure to set your ZMQ paths correctly, e.g.:

    ZMQ_HOME=/usr/local/libzmq-3.1.0/ perl Makefile.PL
EOM
        exit 1;
    }
}

# XXX As of Devel::CheckLib 0.93, it seems like LIBS = "-L/path/to/foo"
# gets ignored (unlike what the docs say). So we manually strip and
# re-arrange the paths here
sub run_check
{
    my $check_sub = shift;
    my @libs = grep { -d $_ } map { s/^-L//; $_ } split /\s+/, $ENV{ZMQ_LIBS};
    local $ENV{LD_LIBRARY_PATH} = join(":", $ENV{LD_LIBRARY_PATH}, @libs);
    return &$check_sub(
        lib => 'zmq',
        header => 'zmq.h',
        incpath => [ split /\s+/, $ENV{ZMQ_INCLUDES} ],
        libpath => \@libs,
        debug => 1,
	@_
    );
}

run_check \&assertlibs;

requires 'Task::Weaken';
requires 'ZMQ::Constants';
test_requires 'Test::More', '0.98';
test_requires 'Test::TCP' => '1.08';
test_requires 'Test::Requires';
test_requires 'Test::Fatal';
use_xshelper '-clean';

use_ppport;
cc_warnings;
cc_include_paths split/\s+/, $ENV{ZMQ_INCLUDES};
cc_include_paths 'xs';
cc_src_paths 'xs';
cc_assert_lib 'zmq';

{
    my @libs = split /\s+/, $ENV{ZMQ_LIBS};
    if ($^O eq 'cygwin') {
        push @libs, '-lzmq', '-luuid'; # uuid for cygwin, but can't hurt
    } else {
        push @libs, '-lzmq';
    }
    cc_libs @libs;
    $ENV{ZMQ_LIBS} = join ' ', @libs;
}

if ($ENV{ZMQ_TRACE}) {
    cc_define qq|-DPERLZMQ_TRACE=$ENV{ZMQ_TRACE}|;
}

sub myguard (&) {
    bless [ $_[0] ], 'myguard';
}
sub myguard::DESTROY {
    $_[0]->[0]->();
}

my @constants;
my @clean = qw(xs/*.inc xs/typemap);

{
    my $found = 0;
    my %functions = (
        zmq_init        => 'zmq_init(0);',
        zmq_ctx_destroy => 'zmq_ctx_destroy(NULL);',
        zmq_ctx_get     => 'zmq_ctx_get(NULL, 0);',
        zmq_ctx_new     => 'zmq_ctx_new();',
        zmq_ctx_set     => 'zmq_ctx_set(NULL, 0, 0);',
        zmq_device      => 'if (0) zmq_device(0, NULL, NULL);', # cannot be executed without initialization on Windows
        zmq_msg_recv    => 'zmq_msg_recv(NULL, NULL, 0);',
        zmq_msg_send    => 'zmq_msg_send(NULL, NULL, 0);',
        zmq_proxy       => 'zmq_proxy(NULL, NULL, NULL);',
        zmq_recvmsg     => 'zmq_recvmsg(NULL, NULL, 0);',
        zmq_socket_monitor => 'zmq_socket_monitor(NULL, NULL, 0);',
        zmq_sendmsg     => 'zmq_sendmsg(NULL, NULL, 0);',
        zmq_term        => 'zmq_term(NULL);',
        zmq_unbind      => 'zmq_unbind(NULL, NULL);',
        zmq_disconnect  => 'zmq_disconnect(NULL, NULL);',
    );

    while (my ($name, $expr) = each %functions)
    {
        print STDERR "CHECK: Does your zmq have $name...\n";
        my $ok = run_check \&{Devel::CheckLib::check_lib}, function => "$expr; return 0;";

        print STDERR "CHECK: Does your zmq have $name...";
        print STDERR " @{[$ok ? 'YES' : 'NO']}\n";
        my $constname = sprintf "HAS_%s", uc $name;
        if ($ok) {
            $found++;
            cc_define "-D$constname";
        }
        push @constants, $constname;
    }

    if (! $found) {
        print STDERR <<EOM;

WHOA!

We were not able to compile any of the auto-detected functions.
It is very likely that there's some sort of problem in the compilation
options, and it is very likely that even if you are able to compile
this module, you will not be able to make any use of it.

EOM
    }
}

{ # Create constants-xs.inc
    my $file = 'xs/constants-xs.inc';
    open my $fh, '>', $file
        or die "Failed to create $file: $!";
    print $fh <<EOM;
        {
            HV *stash = gv_stashpv("ZMQ::LibZMQ3", TRUE);
EOM
    foreach my $const (@constants) {
        print $fh <<EOM;
#ifdef $const
            newCONSTSUB(stash, "$const", &PL_sv_yes);
#else
            newCONSTSUB(stash, "$const", &PL_sv_no);
#endif
EOM
    }
    print $fh <<EOM;
        }
EOM
    close $fh;
}
author_tests 'xt';
clean_files join " ", @clean;

repository "git://github.com/lestrrat/p5-ZMQ.git";
homepage "https://github.com/lestrrat/p5-ZMQ";
bugtracker "https://github.com/lestrrat/p5-ZMQ/issues";

do 'tools/genfiles.pl';
WriteAll;

if ($^O eq 'darwin' && -f "Makefile") {
    my $version = `sw_vers -productVersion`;
    chomp $version;
    $version =~ s/^(\d+\.\d+).\d+$/$1/;

    local @ARGV = qw(Makefile);
    local $^I = '';
    while (<>) {
        if ($^O eq 'darwin') {
            s/MACOSX_DEPLOYMENT_TARGET=(\d+\.\d+)/$1 < 10.5 ? "MACOSX_DEPLOYMENT_TARGET=$version" : "MACOSX_DEPLOYMENT_TARGET=$1"/e;
        }
        s/OTHERLDFLAGS =\s*$/OTHERLDFLAGS = -Wl,-rpath $ENV{ZMQ_LIBS}\n/;
        print;
    }
}

