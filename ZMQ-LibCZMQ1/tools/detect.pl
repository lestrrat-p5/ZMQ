#!/usr/bin/env perl
use strict;
use File::Spec;

# probe env vars first, as you may have wanted to override
# any auto-discoverable values
probe_envvars();
probe_pkgconfig();

sub probe_envvars {
    print "Probing environment variables:\n";
    my $home = $ENV{"CZMQ_HOME"};

    if (! $ENV{"CZMQ_INCLUDES"}) {
        my @incpaths;
        if ($ENV{INCLUDES}) {
            print " + Detected CZMQ_INCLUDES from INCLUDES (deprecated)...\n";
            push @incpaths, $ENV{INCLUDES};
        }

        if ($home) {
            my $zmq_inc = File::Spec->catdir( $home, 'include' );
            if (-e $zmq_inc) {
                print " + Detected CZMQ_INCLUDES from CZMQ_HOME...\n";
                push @incpaths, $zmq_inc;
            }
        }

        if (@incpaths) {
            $ENV{"CZMQ_INCLUDES"} = join ' ', @incpaths;
        }
    }

    if (! $ENV{"CZMQ_H"}) {
        if ($home) {
            my $zmq_header = File::Spec->catfile( $home, 'include', 'czmq.h' );
            if ( -f $zmq_header ) {
                print " + Detected CZMQ_H from CZMQ_HOME...\n";
                $ENV{"CZMQ_H"} = $zmq_header;
            }
        }
    }

    if (! $ENV{"CZMQ_LIBS"}) {
        my @libs;
        if ($ENV{LIBS}) {
            print " + Detected CZMQ_LIBS from LIBS (deprecated)...\n";
            push @libs, $ENV{LIBS};
        }

        if ($home) {
            my $zmq_lib = File::Spec->catdir( $home, 'lib' );
            if (-e $zmq_lib) {
                print " + Detected CZMQ_LIBS from CZMQ_HOME...\n";
                push @libs, sprintf '-L%s', $zmq_lib;
            }
        }

        if (@libs) {
            $ENV{"CZMQ_LIBS"} = join ' ', @libs;
        }
    }
}

# Note: At this point probe_envvars should have taken care merging
# deprecated INCLUDES/LIBS into %ENV
sub probe_pkgconfig {
    my $pkg_config = $ENV{ PKGCONFIG_CMD } || 'pkg-config';
    foreach my $pkg ( qw(libczmq) ) {
        print "Probing $pkg via $pkg_config ...\n";
        my $version = qx/$pkg_config --modversion $pkg/;
        chomp $version;
        if (! $version) {
            print " - No $pkg found...\n";
            next;
        }

        print " + found $pkg $version\n";

        my ($major, $minor, $micro) = split /\./, $version;
        if ($major == 1 && $minor <= 1) {
            print " * detected a version of czmq where the following functions are declared with void return value...\n";
            my @fucked = qw(
                zsocket_connetct
                zframe_send
                zmsg_push
                zmsg_add
                zmsg_pushmem
                zmsg_addmem
            );
            foreach my $fucked (@fucked) {
                print "   - $fucked\n";
            }
            $ENV{ CZMQ_VOID_RETURN_VALUES } = 1;
        }
        $ENV{CZMQ_VERSION_MAJOR} = $major;
        $ENV{CZMQ_VERSION_MINOR} = $minor;
        $ENV{CZMQ_VERSION_PATCH} = $micro;

        if (! $ENV{CZMQ_INCLUDES}) {
            if (my $cflags = qx/$pkg_config --cflags-only-I $pkg/) {
                chomp $cflags;
                print " + Detected CZMQ_INCLUDES from $pkg_config...\n";
                my @paths = map { s/^-I//; $_ } split /\s+/, $cflags;
                $ENV{CZMQ_INCLUDES} = join ' ', @paths;
                if (! $ENV{CZMQ_H}) {
                    foreach my $path (@paths) {
                        my $zmq_h = File::Spec->catfile($path, 'zmq.h');
                        if (-f $zmq_h) {
                            print " + Detected CZMQ_H from $pkg_config...\n";
                            $ENV{CZMQ_H} = $zmq_h;
                            last;
                        }
                    }
                }
            }
        }

        if (! $ENV{CZMQ_LIBS}) {
            if (my $libs = qx/$pkg_config --libs $pkg/) {
                chomp $libs;
                print " + Detected CZMQ_LIBS from $pkg_config...\n";
                $ENV{CZMQ_LIBS} = $libs;
            }
        }

        last;
    }
}