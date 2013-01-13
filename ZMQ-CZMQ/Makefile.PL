use inc::Module::Install;

name 'ZMQ-CZMQ';
all_from 'lib/ZMQ/CZMQ.pm';

# For now, static because there's only libczmq 1.x
requires 'ZMQ::LibCZMQ1';

repository "git://github.com/lestrrat/p5-ZMQ.git";
homepage "https://github.com/lestrrat/p5-ZMQ";
bugtracker "https://github.com/lestrrat/p5-ZMQ/issues";

WriteAll;