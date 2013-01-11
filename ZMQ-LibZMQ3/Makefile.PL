# Let's start with the basics. If we detect that this is git clone,
# then it's very likely that we don't have all the Module::Install
# plugins and such, so run a separate script to detect it.
# Otherwise, do the usual.
BEGIN {
    if (-e '.git') {
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
{
    my @libs = grep { -d $_ } map { s/^-L//; $_ } split /\s+/, $ENV{ZMQ_LIBS};
    assertlibs
        lib => 'zmq',
        header => 'zmq.h',
        incpath => [ split /\s+/, $ENV{ZMQ_INCLUDES} ],
        libpath => \@libs,
    ;
}

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
my $zmqcheck_dir = "tools/zmqcheck";
{
    my $pwd = Cwd::abs_path();
    my $guard = myguard { chdir $pwd };
    chdir $zmqcheck_dir;
    if (system($^X, "Makefile.PL") != 0) {
        die "Failed to execute $zmqcheck_dir/Makefile.PL";
    }

    my $found = 0;
    foreach my $file (glob("*.c")) {
        my $name = $file;
        $name =~ s/\.c$//;
        push @clean, "$zmqcheck_dir/$name";
        print STDERR "CHECK: Does your zmq have $name...";

        my $ok = (system("make", $name) == 0);
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

Here's the output from the compilation:

EOM
        if (! open my $fh, '<', 'zmqcheck.out') {
            print STDERR <<EOM;

WHOA! No logs generated! You have some SERIOUS problem!

EOM
        } else {
            print STDERR "=== START zmqcheck.out ===\n";
            while (<$fh>) { print STDERR $_ }
            print STDERR "=== END zmqcheck.out ===\n";
        }
    }

    print STDERR "Cleaning up $zmqcheck_dir...\n";
    system "make", "clean";
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

repository "https://github.com/lestrrat/p5-ZMQ";

do 'tools/genfiles.pl';
WriteAll;

if ($^O eq 'darwin' && -f "Makefile") {
    my $version = `sw_vers -productVersion`;
    chomp $version;
    $version =~ s/\.\d+$//;

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

