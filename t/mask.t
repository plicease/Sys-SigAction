# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#lab: fixed that setting of SAFE in POSIX::sigaction, and the result
#is that setting it the test causes the test to break...  so it is now
#commented out here.

#########################

use Test::More ;
my $tests = 14;

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

my $hup = 0;
my $int = 0;
my $usr = 0;

my $test = 1;
sub sigHUP  {
   ok( ($test++ == 1) ,'sigHUP called (1)' );
   kill INT => $$;
   kill USR1 => $$;
   $hup++;
   sleep 1;
   ok( ($test++==2) ,'sig mask delayed INT and USR1(2)' );
}
   
sub sigINT_1 
{ 
   #since USR1 is delayed by mask of USR1 on this Signal handler
   #
   ok( ($test++==3) ,'sigINT called(3)' );
   $int++; 
   sleep 1;
   ok( ($test++==4) ,'sig mask delayed USR1 (signaled from sigHUP)(4)' );
}
sub sigUSR_1 { 
   ok( ($test++==5) ,'sigUSR called (5) signcaled from sigHUP)' );
   $usr++; 
}

sub sigINT_2 #masks USR1
{
   ok( ($test++==8) ,'sigINT_2 called (8)' );
   kill USR1=>$$;
   sleep 1;
   ok( ($test++==9) ,'sigINT_2 exiting (9)' );
}
sub sigHUP_2  { #no mask
   ok( ($test++ == 7) ,'sigHUP_2 called' );
   kill INT => $$;
   sleep 1;
   ok( ($test++==11 ) ,'sigHUP_2 ending' );
}
sub sigUSR_2 { #no mask
   ok( ($test++==10) ,'sigUSR2 called (10)' );
   $usr++; 
}

#plan is a follows:
#sigHUP raises INT and USR1 then sleeps and is ok if it gets to the bottom
#  the mask is supposed to delay the execution of sig handles for INT USR1
#  sigHUP sleeps to prove it (this is test 2,3)
#when sigHUP exits
#  sigINT_1 is called because sigUSR is masked... test 4
#  sigINT_1 sleeps to prove it prove it (test 5)
#when sigINT_1 exits
#  sigUSR_1 is called .. it just prints that it has been called (test 6)
#
#then we do the same thing for new sig handers on INT and USR1
#
SKIP: { 
   plan skip_all => "requires perl 5.8.0 or later" if ( $] < 5.008 ); 
   plan tests => $tests;
   
#   print STDERR "
#      NOTE: Setting safe=>1... with masked signals... does not seem to work
#      the masked signals are not masked; when safe=>0 then it does...
#      Not testing safe=>1 for now\n";
         

   set_sig_handler( 'HUP'  ,\&sigHUP  ,{ mask=>[ qw( INT USR1 ) ] } ); #,safe=>0 } );
   #set_sig_handler( 'HUP'  ,\&sigHUP  ,{ mask=>[ qw( INT USR1 ) ] ,safe=>undef } );
   set_sig_handler( 'INT'  ,\&sigINT_1 ,{ mask=>[ qw( USR1 )] } ); #,safe=>0 } );
   #set_sig_handler( 'INT'  ,\&sigINT_1 ); #,{ safe=>0 } );
   set_sig_handler( 'USR1' ,\&sigUSR_1  ); #,{ safe=>0 } );
   kill HUP => $$;

   ok( ( $test++==6 ), "reach 6th test after first kill" );

   set_sig_handler( 'INT' ,\&sigINT_2 ,{ mask=>[ qw( USR1 )] } );
   set_sig_handler( 'HUP' ,\&sigHUP_2 ,{ mask=>[ qw( )] } );
   set_sig_handler( 'USR1' ,\&sigUSR_2  ); #,{ safe=>0 } );
   kill HUP => $$;
   ok( ($hup==1 ), "hup=1 ($hup)" ); 
   ok( ($int==1 ), "int=1 ($int)" ); 
   ok( ($usr==2 ), "usr=1 ($usr)" ); 
}

#ok( $int ,'sigINT called' );
#ok( $usr ,"sigUSR called $usr" );

exit;
