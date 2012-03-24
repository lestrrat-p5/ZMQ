BEGIN {
    if (-e '.git') {
        do 'tools/check_mi_mods.pl';
    } else {
        unshift @INC, 'inc';
        require inc::Module::Install;
        Module::Install->import;
    }
}

name 'ZMQ-LibZMQ3';
all_from 'lib/ZMQ/LibZMQ3.pm';

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
ZMQ.pm only works with libzmq versions >= 3.1.0

Make sure to set your ZMQ paths correctly, e.g.:

    ZMQ_HOME=/usr/local/libzmq-3.1.0/ perl Makefile.PL
EOM
        exit 1;
    }
}

# XXX As of Devel::CheckLib 0.93, it seems like LIBS = "-L/path/to/foo"
# gets ignored (unlike what the docs say). So we manually strip and
# re-arrange the paths here
assertlibs
    lib => 'zmq',
    header => 'zmq.h',
    incpath => [ split /\s+/, $ENV{ZMQ_INCLUDES} ],
    libpath => [ grep { -d $_ } map { s/^-L//; $_ } split /\s+/, $ENV{ZMQ_LIBS} ]
;

auto_set_repository;
requires 'Task::Weaken';
requires 'ZMQ::Constants';
test_requires 'Test::More', '0.98';
test_requires 'Test::TCP' => '1.08';
test_requires 'Test::Requires';
test_requires 'Test::Fatal';
recommends 'JSON' => '2.00';
use_xshelper '-clean';

use_ppport;
cc_warnings;
cc_include_paths split/\s+/, $ENV{ZMQ_INCLUDES};
cc_libs $ENV{ZMQ_LIBS};
cc_include_paths 'xs';
cc_src_paths 'xs';
cc_assert_lib 'zmq';
cc_libs 'zmq', 'uuid'; # uuid for cygwin, but can't hurt
if ($ENV{ZMQ_TRACE}) {
    cc_define qq|-DPERLZMQ_TRACE=$ENV{ZMQ_TRACE}|;
}

author_tests 'xt';
clean_files "xs/*.inc xs/typemap";

do 'tools/genfiles.pl';
WriteAll;