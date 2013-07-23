# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
my $do_subsec = 0;

BEGIN { 
   use_ok('Sys::SigAction'); 
   if ( Sys::SigAction::have_hires() ) 
   {
      eval "use Time::HiRes qw( time );";
   }
}
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
#use warnings;

use Carp qw( carp cluck croak confess );
use Data::Dumper;
use Sys::SigAction qw( set_sig_handler timeout_call );
use POSIX  qw( pause :signal_h );

my $num_args_seen;
my $sum_args_seen;

sub hash { die { hash=>1 }; }
sub sleep_one { sleep 1; die "sleep_one"; }
sub immediate { die "immediate"; }
sub forever { pause; } 
sub forever_w_args {
   $num_args_seen = @_;
   $sum_args_seen += $_ for @_;
   forever();
}
my $ret = 0;

my $num_tests = 1; #start at 1 because of use_ok above
eval { 
   $ret = timeout_call( 1, \&hash ); 
};
ok( (ref( $@ ) and exists($@->{'hash'}))  ,'die with hash' ); $num_tests++;
ok( $ret == 0 ,'hash did not timeout' ); $num_tests++;

$ret = 0;
eval { 
   $ret = timeout_call( 1, \&immediate ); 
};
ok( (not ref($@) and $@ ),'immediate -- die with string' ); $num_tests++;
ok( $ret == 0 ,'immediate did not timeout' ); $num_tests++;

$ret = 0;
eval { 
   $ret = Sys::SigAction::timeout_call( 1, \&forever ); 
   #print "forever timed out\n" if $ret;
}; 
if ( $@ )
{ 
   print "why did forever throw exception:" .Dumper( $@ );
}
ok( (not $@ ) ,'forever did NOT die' ); $num_tests++;
ok( $ret ,'forever timed out' ); $num_tests++;

foreach my $args ([1], [2, 3]) {
   $ret = 0;
   my $num_args_ok = @$args;
   my $sum_args_ok = 0;
   $sum_args_ok += $_ for @$args;
   $num_args_seen = $sum_args_seen = 0;
   eval {
      $ret = Sys::SigAction::timeout_call( 1, \&forever_w_args, @$args );
   };
   local $" = ', ';
   ok( (not $@ ) ,"forever_w_args(@$args) did NOT die" ); $num_tests++;
   ok( $ret ,"forever_w_args(@$args) timed out" ); $num_tests++;
   ok( $num_args_seen == $num_args_ok,"forever_w_args(@$args) got $num_args_seen args" ); $num_tests++;
   ok( $sum_args_seen == $sum_args_ok,"forever_w_args(@$args) args sum is $sum_args_seen" ); $num_tests++;
}

if ( Sys::SigAction::have_hires() )
{
   diag( "fractional second timeout tests" );
   $ret = 0;
   my $btime;
   my $etime;
   eval { 
      $btime = time();
      $ret = Sys::SigAction::timeout_call( 0.1, \&forever ); 
   }; 
   if ( $@ )
   { 
      print "hires: why did forever throw exception:" .Dumper( $@ );
   }
   $etime =  time();

   ok( (not $@ ) ,'hires: forever did NOT die' ); $num_tests++;
   ok( $ret ,'hires: forever timed out' ); $num_tests++;
   ok( (($etime - $btime) < 0.2 ), "hires: timeout in < 0.2 seconds" ); $num_tests++;

   #diag( "testing HiRes where msecs would be greater than maxint (" .POSIX::INT_MAX.")" );
   my $toobig = POSIX::INT_MAX/1_000_000.0 + 1;
   $ret = 0;
   eval { 
      $ret = timeout_call( $toobig, \&sleep_one ); 
   };
   ok( (not ref($@) and $@ ),"immediate -- die with string (toobig=$toobig)" ); $num_tests++;
   ok( $ret == 0 ,"immediate did not timeout (with toobig=$toobig)" ); $num_tests++;

}
else
{
   diag "fractional second timeout test skipped: Time::HiRes is not installed" ;
}
plan tests => $num_tests;

exit;
