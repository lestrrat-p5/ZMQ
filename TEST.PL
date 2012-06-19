#!perl
use strict;
use Cwd ();
use File::Spec;
use LWP::UserAgent;

sub mysystem(@) {
    system(@_) == 0 or die "Failed to execute @_: $!";
}

my $ua     = LWP::UserAgent->new();
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
    $ua->mirror("http://download.zeromq.org/$file");
    mysystem("tar", "xvzf", $file);
    chdir $base;
    mysystem("./configure", "--prefix", $prefix);
    mysystem("make");
    mysystem("make", "install");

    $ENV{ZMQ_HOME} = $prefix;
    chdir File::Spec->catdir($pwd, "ZMQ-LibZMQ2");
    mysystem("cpanm", "--notest", qw(
        inc::Module::Install
        Module::Install::AuthorTests
        Module::Install::CheckLib
        Module::Install::ReadmeFromPod
        Module::Install::TestTarget
        Module::Install::XSUtil
        Module::Install::Repository
    );
    mysystem("cpanm", "--notest", "--installdeps", ".");
    mysystem("perl", "Makefile.PL");
    mysystem("make", "test");
}