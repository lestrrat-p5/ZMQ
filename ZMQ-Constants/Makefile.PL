use strict;
use inc::Module::Install;

name 'ZMQ-Constants';
all_from 'lib/ZMQ/Constants.pm';

repository "git://github.com/lestrrat/p5-ZMQ.git";
homepage "https://github.com/lestrrat/p5-ZMQ";
bugtracker "https://github.com/lestrrat/p5-ZMQ/issues";

WriteAll;