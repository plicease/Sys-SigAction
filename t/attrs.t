# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 9;
BEGIN { use_ok('Sys::SigAction') };

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
   ok( (++$test == 2) ,'sigHUP called' );
   kill INT => $$;
   kill USR1 => $$;
   $hup++;
   sleep 1;
   ok( (++$test==3) ,'sig mask delayed INT and USR1' );
}
   
sub sigINT 
{ 
   ok( (++$test==4) ,'sigINT called' );
   $int++; 
   sleep 2;
   ok( (++$test==5) ,'sig mask delayed USR1' );
}
sub sigUSR { 
   ok( (++$test==6) ,'sigUSR called' );
   $usr++; 
}

set_sig_handler( 'HUP' ,\&sigHUP ,{ mask=>[ qw( INT USR1 ) ] ,safe=>1 } );
set_sig_handler( 'INT' ,\&sigINT ,{ mask=>[ qw( USR1 )] ,safe=>0 } );
set_sig_handler( 'USR1' ,\&sigUSR ,{ safe=>1 } );

kill HUP => $$;


sub sigHUP_2  {
   ok( (++$test == 7) ,'sigHUP_2 called' );
   kill INT => $$;
   sleep 1;
   ok( (++$test==9) ,'no mask/safe=0 INT_2 called before exit of HUP_2' );
}
sub sigINT_2 
{
   ok( (++$test==8) ,'sigINT_2 called' );
}
set_sig_handler( 'INT' ,\&sigINT_2 ,{ mask=>[ qw( USR1 )] ,safe=>0 } );
set_sig_handler( 'HUP' ,\&sigHUP_2 ,{ mask=>[ qw( )] ,safe=>0 } );

kill HUP => $$;

#ok( $int ,'sigINT called' );
#ok( $usr ,"sigUSR called $usr" );

exit;
