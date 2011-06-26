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
use POSIX  ':signal_h' ;

sub hash { die { hash=>1 }; }
sub immediate { die "immediate"; }
sub forever { while ( 1 ) { 1; } } 
my $ret = 0;

my $num_tests = 1; #start at 1 because of use_ok above
eval { 
   $ret = timeout_call( 1, sub { hash(); } ); 
};
ok( (ref( $@ ) and exists($@->{'hash'}))  ,'die with hash' ); $num_tests++;
ok( $ret == 0 ,'hash did not timeout' ); $num_tests++;

$ret = 0;
eval { 
   $ret = timeout_call( 1, sub { immediate(); } ); 
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


if ( Sys::SigAction::have_hires() )
{
   diag( "testing fractional second timeout" );
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
#   diag(  $btime );
#   diag(  $etime );
#   diag(  ($etime-$btime) );

   ok( (not $@ ) ,'hires: forever did NOT die' ); $num_tests++;
   ok( $ret ,'hires: forever timed out' ); $num_tests++;
   ok( (($etime - $btime) < 0.2 ), "hires: timeout in < 0.2 seconds" ); $num_tests++;
}
else
{
   diag "fractional second timeout test skipped: Time::HiRes is not installed" ;
}
plan tests => $num_tests;

#foreach my $level ( @levels )
#{
#   ok( $level ,"level $i" );
#   print "level $i = $level\n" ;
#   $i++;
#}


exit;
