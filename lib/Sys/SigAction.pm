#
#   Copyright (c) 2004 Lincoln A. Baxter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file,
#   with the exception that it cannot be placed on a CD-ROM or similar media
#   for commercial distribution without the prior approval of the author.

package Sys::SigAction;
require 5.005;
use strict;
use warnings;
use POSIX ':signal_h' ;
require Exporter;
use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS );

#use Data::Dumper;

@ISA = qw( Exporter );
@EXPORT_OK = qw( set_sig_handler timeout_call sig_name sig_number );
$VERSION = 0.01;

my $have_threads = 0;
BEGIN {
   eval { 
      require thread;
      $have_threads = 1;
   };
   if ( not $have_threads )
   {
      sub lock { "DUMMY" }
   }
};

use Config;
my %signame = ();
my %signo = ();
{
   defined $Config{sig_name} or die "This OS does not support signals?";
   my $i = 0;     # Config prepends fake 0 signal called "ZERO".
   my @numbers = split( ' ' ,$Config{sig_num} );
   foreach my $name (split(' ', $Config{sig_name})) 
   {
      $signo{$name} = $numbers[$i];
      $signame{$signo{$name}} = $name;
      #print "name=$name num=" .$numbers[$i] ."\n" ;
      $i++;
   }
}

sub sig_name {
   my ($sig) = @_;
   return $sig if $sig !~ m/^\d+$/ ;
   return $signame{$sig} ;
}
sub sig_number {
   my ($sig) = @_;
   return $sig if $sig =~ m/^\d+$/;
   return $signo{$sig} ;
}

my $use_sigaction = ( $] >= 5.008 and $Config{d_sigaction} );

sub set_sig_handler( $$;$$ )
{
   my ( $sig ,$handler ,$attrs ) = @_;      
   $attrs = {} if not defined $attrs;
   if ( not $use_sigaction )
   {
      #warn '$flags not supported in perl versions < 5.8' if $] < 5.008 and defined $flags;
      $sig = sig_name( $sig );
      my $ohandler = $SIG{$sig};
      $SIG{$sig} = $handler;
      return if not defined wantarray;
      return Sys::SigAction->new( $sig ,$ohandler );
   }
   my $act = mk_sig_action( $handler ,$attrs );
   return set_sigaction( sig_number($sig) ,$act );
}
sub mk_sig_action($$)
{
   my ( $handler ,$attrs ) = @_;      
   die 'mk_sig_action requires perl 5.8.0 or later' if $] < 5.008;
   $attrs->{flags} = 0 if not defined $attrs->{flags};
   $attrs->{mask} = [] if not defined $attrs->{mask};
   #die '$sig is not defined' if not defined $sig;
   #$sig = sig_number( $sig );
   my @siglist = ();
   foreach (@{$attrs->{mask}}) { push( @siglist ,sig_number($_)); };
   my $mask = POSIX::SigSet->new( @siglist );
   my $act =  POSIX::SigAction->new( $handler ,$mask ,$attrs->{flags} ,$attrs->{safe} );
   return $act;
}


sub set_sigaction($$)
{ 
   my ( $sig ,$action  ) = @_;
   die 'set_sigaction() requires perl 5.8.0 or later' if $] < 5.008;
   die '$sig is not defined' if not defined $sig;
   die '$action is not a POSIX::SigAction' if not UNIVERSAL::isa( $action ,'POSIX::SigAction' );
   $sig = sig_number( $sig );
   if ( defined wantarray )
   {
      my $oact = POSIX::SigAction->new();
      sigaction( $sig ,$action ,$oact );
      return Sys::SigAction->new( $sig ,$oact );
   }
   else
   {
      sigaction( $sig ,$action );
   }
}

use constant TIMEDOUT => {};
sub timeout_call( $$;$ )
{
   my ( $timeout ,$code ) = @_;
   my $timed_out = 0;
   my $ex;
   eval {
      my $h = sub { $timed_out = 1; die TIMEDOUT; };
      my $sa = set_sig_handler( SIGALRM ,sub { $timed_out = 1; die TIMEDOUT; } );
      alarm( $timeout );
      &$code; 
      alarm(0);
   };
   alarm(0);
   if ($@)
   {
      #print "$@\n" ;
      die $@ if not ref $@;
      die $@ if $@ != TIMEDOUT;
   }
   return $timed_out;
}
sub new {
   my ($class,$sig,$act) = @_;
   bless { SIG=>$sig ,ACT => $act } ,$class ;
}
sub DESTROY 
{
   if ( $use_sigaction )
   {
      set_sigaction( $_[0]->{'SIG'} ,$_[0]->{'ACT'} );
   }
   else
   {
      $SIG{$_[0]->{'SIG'}} = $_[0]->{'ACT'} ;
   }
   return;
}

1;

__END__

=head1 NAME

Sys::SigAction - Perl extension for Consistent Signal Handling

=head1 SYNOPSYS

   #do something non-interupt able
   use Sys::SigAction qw( set_sig_handler );
   {
      my $h = set_sig_handler( 'INT' ,'mysubname' ,{ flags => SA_RESTART } );
      ... do stuff non-interupt able
   } #signal handler is reset when $h goes out of scope

or

   #timeout a system call:
   use Sys::SigAction qw( set_sig_handler );
   eval {
      my $h = set_sig_handler( 'ALRM' ,\&mysubname ,{ mask=>'ALRM' ,safe=>1 } );
      alarm(2)
      ... do something you want to timeout
      alarm(0);
   }; #signal handler is reset when $h goes out of scope
   alarm(0); 
   if ( $@ ) ...

or

   use Sys::SigAction;
   my $alarm = 0;
   eval {
      my $h = Sys::SigAction::set_sig_handler( 'ALRM' ,sub { $alarm = 1; } );
      alarm(2)
      ... do something you want to timeout
      alarm(0);
   };
   alarm(0); 
   if ( $@ or $alarm ) ...

or

   use Sys::SigAction;
   my $alarm = 0;
   Sys::SigAction::set_sig_handler( 'TERM' ,sub { "DUMMY" } );
   #code from here on uses new handler.... (old handler is forgotten)

or

   use Sys::SigAction qw( timeout_call );
   if ( timeout_call( 5 ,sub { $retval = DoSomething( @args ); } )
   {
      print "DoSomething() timed out\n" ;
   }

=head1 ABSTRACT

Implements sig_sethandler, which  sets up a signal handler and
(optionally) returns an object which causes the signal handler to be
reset to the previous value, when it goes out of scope.

=head1 DESCRIPTION

Perl has been changing the way unix signals are implemented in an attempt
to make them safer.  Changes were made between perl 5.6 and perl 5.8,
and more changes have been made in versions after perl 5.8.  The 5.8
changes broke this author's database connection timeouts.  Prior to
version 5.8 a signal handlers would interupt system calls like connect()
amd perl would immediately call the signal handler.

From the perl 5.8.2 perlvar man page:

   The default delivery policy of signals changed in Perl 5.8.0 
   from immediate (also known as "unsafe") to deferred, also 
   known as "safe signals".  

Infortunately this 'deferred signal' approach causes system calls to
be retried prior to the signal handler being called.  The result is
that might could never return. This is the case with the DBD-Oracle
connect call, when the host on which a database resides is not available.
This makes it impossible to implement open timeouts, at least with code
looks like this:

   eval {
      local $SIG{ALRM} = sub { die "timeout" };
      alarm 2;
      $sth = DBI->connect(...);
      alarm 0;
   };
   alarm 0;
   die if $@;

The workaround, if your system has sigaction(), is to use
POSIX::sigaction() to install the signal handler.  With sigaction(),
one gets control over both the signal mask, and the flags that are used
to install the handler. Further, with perl 5.8.2 and later a 'safe'
switch is provided which can be used to ask for 'safe' signal handling.
Using sigaction() does ensure that the system call is interupted, if
one calls die within the signal handler.  This is not longer the case
when one uses $SIG{name} to set signal handlers in perls >= 5.8.0.

The usage of sigaction() however is not well documented however and in
perls < 5.8.0 it does not work at all. (fortunately thats OK becase just
setting $SIG does work for this purpose in that case.)  Using sigaction()
requires approximately 4 or 5 lines of code where previously one only
had to set a code reference into the %SIG array.

This module wraps up the POSIX:: routines and objects necessary to call
sigaction() in a way that is as efficient from coding perspective as
just setting a localized $SIG{SIGNAL} with a code reference, with the
advantange that the user has control over the flags passed to sigaction().
By default no additional args are passed to sigaction(), and the signal
handler will be called when a signal (such as SIGALRM) is delivered.

While sigaction() is not fully functional in perl versions less than 5.8,
this module has been tested with perls going back to 5.005 (solaris).
With perls < 5.8 this modules just sets $SIG; the flags, mask and safe
keys in the attributes hash are silently ignored.

It is hoped that with the use of this module your signal handling behavior
can be coded in a way that does not change from one perl version to the
next, and that it makes using sigaction() a little easier.

=head1 FUNCTIONS

=head2  set_sig_handler 

   $sig ,$handler ,$attrs 
   

Install a new signal handler and (if not called in a void
context) returning a Sys::SigAction object containing the 
old signal handler, which will be restored on object 
destruction.

   $sig     is a signal name (without the 'SIG') or number.

   $handler is either the name (string) of a signal handler
            function or a subroutine CODE reference. 

   $attrs   if defined is a hash reference containing the 
            following keys:

            flags => the flags the passed sigaction

               ex: SA_RESTART (defined in your signal.h)

            mask  => the array reference: signals you
                     do not want delivered while the signal
                     handler is executing

               ex: [ SIGINT SIGUSR1 ] or
               ex: [ qw( INT USR1 ]

            safe  => A bolean value requesting 'safe' signal
                     handling (usd in 5.8.2 and greater)

=head2 timeout_call

   $timeout ,$coderef 

Given a code reference, and a timeout value (in seconds), timeout() will
(in an eval) setup a signal handler for SIGALRM which will die,
set an alarm clock, and execute the code reference.  

If the alarm goes off the code will be interupted.  The alarm is
canceled if the code returns before the alarm is fired.  The routine
returns true if the code being executed timed out. (was interrupted).
Exceptions thrown by the code executed are propagated out.

The original signal handler is restored, prior to returning to the caller.

=head1 sig_name

Return the signal name (string) from a signal number.

ex:

   sig_name( SIGINT ) returns 'INT'
   

=head1 sig_name

Return the signal number (integer) from a signal name (minus the SIG part).

ex:

   sig_number( 'INT' ) returns the integer values of SIGINT;



=head1 AUTHOR

   Lincoln A. Baxter <lab@lincolnbaxter.com.make.me.VALID>

=head1 SEE ALSO

   perldoc perlvar 
   perldoc POSIX

