# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#lab: this could be a clone of mask.t.  The idea would be to turn on safe 
#signal handling and verify the same results.  The problem is that it does 
#not appear to work.
#

#########################

use Test::More ;
my $tests = 1;

#BEGIN { use_ok('Sys::SigAction') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
#use warnings;


use Carp qw( carp cluck croak confess );
use Data::Dumper;
use POSIX ':signal_h' ;
use Sys::SigAction qw( set_sig_handler sig_name sig_number );

SKIP: { 
   plan skip_all => "requires perl 5.8.2 or later" if ( $] < 5.008002 ); 
   plan tests => $tests;
   
   print STDERR "
      
      NOTE: Setting safe=>1... with masked signals... does not seem to work
      the masked signals are not masked; when safe=>0 they are
      see mask.t for how we could try it.

      If you have an application for safe=>1 and can come up with 
      a test that works in the context of this module's installation
      please send me an update.
      
      Lincoln
      \n";
         
   ok( 1, "skipping test of safe flag for now" ); 
}

#ok( $int ,'sigINT called' );
#ok( $usr ,"sigUSR called $usr" );

exit;
