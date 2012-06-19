#!perl
use strict;
use Cwd ();
use File::Spec;


sub mysystem(@) {
    system(@_) == 0 or die "Failed to execute @_: $!";
}

my $root   = Cwd::abs_path( Cwd::cwd() );
my $target = $ENV{PERL_ZMQ_TEST_TARGET} || 'ZMQ-LibZMQ2';

if (! -d $target) {
    die "$target does not exist";
}

my $install_dir = File::Spec->catdir($root, "ext");

if ( $target eq 'ZMQ-LibZMQ2' ) {
    # install libzmq2
    my $base   = "zeromq-2.2.0";
    my $prefix = File::Spec->catdir($install_dir, $base);
    my $file   = "$base.tar.gz";
    mysystem("curl", "-LO", "http://download.zeromq.org/$file");
    mysystem("tar", "xzf", $file);
    chdir $base;
    mysystem("./configure", "--prefix", $prefix);
    mysystem("make");
    mysystem("make", "install");

    $ENV{ZMQ_HOME} = $prefix;
    chdir File::Spec->catdir($root, "ZMQ-LibZMQ2");
    mysystem("cpanm", "--notest", qw(
        inc::Module::Install
        Module::Install::AuthorTests
        Module::Install::CheckLib
        Module::Install::ReadmeFromPod
        Module::Install::TestTarget
        Module::Install::XSUtil
        Module::Install::Repository
    ));
    mysystem("cpanm", "--notest", "--installdeps", ".");
    mysystem("perl", "Makefile.PL");
    mysystem("make", "test");
} elsif ( $target eq 'ZMQ-LibZMQ3' ) {
    # install libzmq3
    my $base   = "zeromq-3.2.0-rc1";
    my $prefix = File::Spec->catdir($install_dir, $base);
    my $file   = "$base.tar.gz";
    mysystem("curl", "-LO", "http://download.zeromq.org/$file");
    mysystem("tar", "xzf", $file);
    chdir $base;
    mysystem("./configure", "--prefix", $prefix);
    mysystem("make");
    mysystem("make", "install");

    $ENV{ZMQ_HOME} = $prefix;
    chdir File::Spec->catdir($root, "ZMQ-LibZMQ3");
    mysystem("cpanm", "--notest", qw(
        inc::Module::Install
        Module::Install::AuthorTests
        Module::Install::CheckLib
        Module::Install::ReadmeFromPod
        Module::Install::TestTarget
        Module::Install::XSUtil
        Module::Install::Repository
    ));
    mysystem("cpanm", "--notest", "--installdeps", ".");
    mysystem("perl", "Makefile.PL");
    mysystem("make", "test");
}