# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Sys::SigAction') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
#use warnings;

use Carp qw( carp cluck croak confess );
use Data::Dumper;
use Sys::SigAction qw( set_sig_handler );
use POSIX  ':signal_h' ;

my @levels = ( 0 ,0 ,0 ,0 );
set_sig_handler( SIGALRM ,sub { print "level 0\n" ; $levels[0] = 1; } );
sub sighandler { print "level 1\n" ; $levels[1] = 1; }


eval {
   my $h1 = \&sighandler;
   my $ctx1 = set_sig_handler( 'ALRM' ,'sighandler' ); #,\&sighandler);
   if ( 1 ) { 
      eval {
         my $ctx2 = set_sig_handler( SIGALRM ,sub { print "level 2\n"; $levels[2] = 1; } );
         eval {
            my $ctx3 = set_sig_handler( 'ALRM' ,sub {  print "level 3\n"; $levels[3] = 1; } );
            kill ALRM => $$;
            #undef $ctx3;
         };
         if ($@)
         {
            print "handler died: $@\n";
         }
         kill ALRM => $$;
      };
      if ( $@ )
      {
         print "error: $@\n";
      }
   }
   kill ALRM => $$;
};
kill ALRM => $$;

my $i = 0;
foreach my $level ( @levels )
{
   ok( $level ,"level $i" );
   print "level $i = $level\n" ;
   $i++;
}


exit;
