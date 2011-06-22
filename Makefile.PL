# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use 5.005;
use ExtUtils::MakeMaker;
# add a number of tests to stop the smoke testers from reporting Failed
# in unsupported environments
#
print "Checking for Microsoft Windows... (not supported)\n";
if ( $^O =~ /MSWin32/ ) {
   die q{ 
   
   OS unsupported

   Sys::SigAction is not Supported on on $^O operating systems
   if you can make all or most of the tests work on this OS, then 
   please send patches to me, and I will consider them for a new 
   release that supports $^O.

   Note that smoke testers have had successful results in a Cygwin
   environment however.  So if you want to write scripts using
   signals on a Win32 environment consider Cygwin Bash.

   Lincoln
   };
}

print "Checking for multi-threaded Perl... (warning)\n";
use Config;
eval "use threads";
#belt and suspenders....
if ( ! $@ || $Config{usethreads} || $Config{useithreads} || $Config{use5005threads} ) {
   warn q{ 
   
   Using Signals in a multi-thread perl application is unsupported 
   by Sys::SigAction.

   Read the following from perldoc perlthrtut:

      ...mixing signals and threads may be problematic.
      Implementations are platform-dependent, and even the POSIX semantics
      may not be what you expect (and Perl doesn't even give you the full
      POSIX API).  For example, there is no way to guarantee that a signal
      sent to a multi-threaded Perl application will get intercepted by
      any particular thread.
      

   You are on your own if we use this module in a multi threaded application

   Lincoln

   };
}

print "Checking support for signals... (required)\n";
if ( ! defined $Config{sig_name} ) {
   die q{
       Signals are not supported in this OS or perl version.
   }
}

#is sigaction enabled?
print "Checking support for POSIX::sigaction... (required)\n";
if ( ( $] >= 5.008 ) && 
   ! ( $Config{useposix} && $Config{d_sigaction} ) ) {
   die q{ 
   
   This perl is not supported.
   Perl must be built with 'useposix' and 'sigaction' defined.

   Lincoln

   };
}

print "Checking for armv5tejl... (not supported)\n";
#belt and suspenders....
if ( $Config{archname} =~ m/armv5tejl/ ) {
   die q{

   Sys::SigAction is not supported on armv5tejl systems.
   I have communicated with the smoke tester on this OS, 
   and we believe that the base perl implementation of 
   POSIX:sigaction is probably the root cause.

   if you want to use this module anyway, or work on getting
   it supported by fixing the perl port, you can uncomment out
   this section of Makefile.PL to build Sys::SigAction.

   };
}

print "Checking for Time::HiRes (support for fractional seconds in timeouts)\n";
eval "use Time::HiRes qw( ualarm )";
if ( $@ ) {
   warn q(
   
   Time::HiRes is not available.  Fractional seconds in timeout_call()
   will be raised to the next high integer value with POSIX::ceil().
   
   );
}



#ok... enough defensiveness... 
my $args = {
    'NAME'		=> 'Sys::SigAction',
    'VERSION_FROM'	=> 'lib/Sys/SigAction.pm', # finds $VERSION
    'PREREQ_PM'		=> {
       'Test::More'  =>  0
       ,POSIX => 0 
    }, # e.g., Module::Name => 1.1
    'ABSTRACT_FROM' => 'lib/Sys/SigAction.pm', # retrieve abstract from module
    'AUTHOR'     => 'Lincoln A. Baxter <lab-at-lincolnbaxter-dot-com>' 
};

print "MakeMaker version = $ExtUtils::MakeMaker::VERSION\n";
if ($ExtUtils::MakeMaker::VERSION >= 6.3002 ) {
   $args->{LICENSE} = 'perl';
}

WriteMakefile( %$args );

