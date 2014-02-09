#!perl
use strict;
use Cwd ();
use File::Spec;

my $ROOT   = Cwd::abs_path( Cwd::cwd() );
my $EXTDIR = File::Spec->catdir($ROOT, "ext");
my $target = $ENV{PERL_ZMQ_TEST_TARGET} || 'ZMQ-LibZMQ2';

sub myguard::DESTROY {
    if ($_[0]->{code}) {
        $_[0]->{code}->();
    }
}
sub myguard(&) {
    bless { code => $_[0] }, 'myguard';
}

if (! -d $target) {
    die "$target does not exist";
}

sub mysystem(@) {
    print STDERR "===> @_\n";
    system(@_) == 0 or die "Failed to execute @_: $!";
}

sub install_libzmq(@) {
    my ($basename, $opts) = @_;

    mysystem("sudo", "apt-get", "install", "uuid-dev");

    my $tail = $opts->{tail} || '';
    my $prefix = File::Spec->catdir($EXTDIR, $basename);
    my $file   = "$basename$tail.tar.gz";
    if (! -e $file) {
        mysystem("curl", "-LO", "http://download.zeromq.org/$file");
    }
    if (! -e $basename) {
        mysystem("tar", "xzf", $file);
    }
    my $cwd = Cwd::abs_path();
    my $guard = myguard { chdir $cwd };
    chdir $basename;
    mysystem("./configure", "--prefix", $prefix, @{$opts->{extra_configure_args} ||[]});
    mysystem("make");
    mysystem("make", "install");

    return $prefix;
}

sub cpanm (@) {
    eval {
        mysystem("cpanm", "--verbose", "--notest", @_);
    };
    if (my $e = $@) {
        my $cpanm_log = "/home/travis/.cpanm/build.log";
        open my $fh, '<', $cpanm_log;
        while (<$fh>) {
            print;
        }
        die $e;
    }
}

sub test_binding {
    my $subdir = shift;
    my $cwd = Cwd::abs_path();
    my $guard = myguard { chdir $cwd };
    chdir File::Spec->catdir($ROOT, $subdir);
    cpanm("--installdeps", ".");
    mysystem("perl", "Makefile.PL");
    mysystem("make", "test");
}

sub install_libczmq {
    my $zmq_version = shift;

    print STDERR "===> Installing libczmq against zeromq-$zmq_version\n";
    $ENV{ZMQ_HOME} = install_libzmq("zeromq-$zmq_version");
    install_libzmq("czmq-1.3.2", {
        extra_configure_args => [
            sprintf('--with-libzmq=%s', File::Spec->catdir($EXTDIR, "zeromq-$zmq_version")),
        ]
    });
}

if ( $target eq 'ZMQ-Constants' ) {
    cpanm(qw(
        inc::Module::Install
        Test::Requires
    ));
    test_binding("ZMQ-Constants");
} elsif ( $target eq 'ZMQ-CZMQ' ) {
    cpanm(qw(
        inc::Module::Install
        Module::Install::XSUtil
        Module::Install::CheckLib
        Test::Requires
        Test::TCP
    ));
    foreach my $zmq_version( qw(2.2.0 3.2.2) ) {
        $ENV{CZMQ_HOME} = install_libczmq($zmq_version);
        cpanm(File::Spec->catdir($ROOT, "ZMQ-LibCZMQ1"));
        test_binding("ZMQ-CZMQ");
        if ($ENV{ZMQ_HOME} && -d $ENV{ZMQ_HOME}) {
            mysystem("rm", "-rf", $ENV{ZMQ_HOME});
        }
    }
} elsif ( $target eq 'ZMQ-LibCZMQ1' ) {
    cpanm(qw(
        inc::Module::Install
        Module::Install::XSUtil
        Module::Install::CheckLib
        Test::Requires
        Test::TCP
    ));
    foreach my $zmq_version ( qw(2.2.0 3.2.2) ) {
        $ENV{CZMQ_HOME} = install_libczmq($zmq_version);
        test_binding("ZMQ-LibCZMQ1");
        if ($ENV{ZMQ_HOME} && -d $ENV{ZMQ_HOME}) {
            mysystem("rm", "-rf", $ENV{ZMQ_HOME});
        }
    }
} elsif ( $target eq 'ZMQ-LibZMQ2' ) {
    $ENV{ZMQ_HOME} = install_libzmq("zeromq-2.2.0");
    cpanm(qw(
        inc::Module::Install
        Module::Install::AuthorTests
        Module::Install::CheckLib
        Module::Install::XSUtil
    ));
    test_binding("ZMQ-LibZMQ2");
    cpanm(qw(AnyEvent Proc::Guard));
    test_binding("ZMQ-LibZMQ2");
} elsif ( $target eq 'ZMQ-LibZMQ3' ) {
    $ENV{ZMQ_HOME} = install_libzmq("zeromq-3.2.2");
    cpanm(qw(
        inc::Module::Install
        Module::Install::AuthorTests
        Module::Install::CheckLib
        Module::Install::XSUtil
    ));

    print STDERR "===\n\nTesting $target w/o optional dependencies...\n\n===\n";
    test_binding("ZMQ-LibZMQ3");
    print STDERR "===\n\nTesting $target with optional dependencies...\n\n===\n";
    cpanm(qw(AnyEvent Test::TCP Proc::Guard));
    test_binding("ZMQ-LibZMQ3");
} elsif ( $target eq 'ZMQ' ) {
    cpanm(qw(
        inc::Module::Install
        Module::Install::AuthorTests
        Module::Install::CheckLib
        Module::Install::XSUtil
    ));

    foreach my $zmq_version(qw(2.2.0 3.2.2)) {
        my $backend = sprintf 'LibZMQ%d', substr($zmq_version, 0, 1);
        $ENV{ZMQ_HOME} = install_libzmq("zeromq-$zmq_version");
        cpanm(File::Spec->catdir($ROOT, "ZMQ-$backend"));
        $ENV{PERL_ZMQ_BACKEND} = "ZMQ::$backend";
        test_binding("ZMQ");
        if ($ENV{ZMQ_HOME} && -d $ENV{ZMQ_HOME}) {
            mysystem("rm", "-rf", $ENV{ZMQ_HOME});
        }
    }
}