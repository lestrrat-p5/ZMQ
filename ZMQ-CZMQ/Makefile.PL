use inc::Module::Install;

name 'ZMQ-CZMQ';
all_from 'lib/ZMQ/CZMQ.pm';

# For now, static because there's only libczmq 1.x
requires 'ZMQ::LibCZMQ1';
auto_set_repository;

WriteAll;