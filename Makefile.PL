require 5.000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'Tom',
	AUTHOR    => 'Delon Newman <delon.newman@gmail.com>',
    ABSTRACT  => 'Controlling Tomcat with simplicity',
	VERSION   => '1.0',
    PREREQ_PM => { 
                   'HTTP::Tiny' => 0, 
                   'Mojo::DOM'  => 0,
				   'File::Tail' => 0
                 },
    EXE_FILES => [ 'tom' ],
);
