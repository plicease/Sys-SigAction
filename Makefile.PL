use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Sys::SigAction',
    'VERSION_FROM'	=> 'lib/Sys/SigAction.pm', # finds $VERSION
    'PREREQ_PM'		=> {
       'Test::More'  =>  0
       ,POSIX => 0 
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM => 'lib/Sys/SigAction.pm', # retrieve abstract from module
    AUTHOR     => 'Lincoln A. Baxter <lab@lincolnbaxter.com.MAKE.ME.VALID>' 
);
