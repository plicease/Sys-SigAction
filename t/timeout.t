# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('Sys::SigAction') };

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
sub forever { my $t = <STDIN>; } #read from stdin as a blocking call
my $ret = 0;

eval { 
   $ret = timeout_call( 1, sub { hash(); } ); 
};
ok( (ref( $@ ) and exists($@->{'hash'}))  ,'die with hash' );
ok( $ret == 0 ,'hash did not timeout' );

$ret = 0;
eval { 
   $ret = timeout_call( 1, sub { immediate(); } ); 
};
ok( (not ref($@) and $@ ),'immediate -- die with string' );
ok( $ret == 0 ,'immediate did not timeout' );
   
$ret = 0;
eval { 
   $ret = Sys::SigAction::timeout_call( 1, \&forever ); 
   #print "forever timed out\n" if $ret;
}; 
if ( $@ )
{ 
   print "why did forever throw exception:" .Dumper( $@ );
}
ok( (not $@ ) ,'forever did NOT die' );
ok( $ret ,'forever timed out' );


#foreach my $level ( @levels )
#{
#   ok( $level ,"level $i" );
#   print "level $i = $level\n" ;
#   $i++;
#}


exit;
