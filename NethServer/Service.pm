#
# NethServer Service
#
# Copyright (C) 2012 Nethesis srl
#

package NethServer::Service;

use strict;
use esmith::ConfigDB;

=head1 NAME

NethServer::Service module

=cut

=head2 start($daemon)
    
Start $daemon if it is stopped

=cut
sub start
{
    my $service = '/sbin/service';
    my $daemon = shift;

    qx($service $daemon status >/dev/null);
    if ( $? != 0 ) {
	qx($service $daemon start);
    }
    return ($? == 0 ? 1 : 0);
}


=head2 stop($daemon)
    
Stop $daemon if it is running

=cut
sub stop
{
    my $service = '/sbin/service';
    my $daemon = shift;

    qx($service $daemon status >/dev/null);
    if ( $? != 0 ) {
	return 0;
    } 

    qx($service $daemon stop);
    return ($? == 0 ? 1 : 0);
}


=head2 is_enabled($daemon)

Check if $daemon is enabled in the current runlevel. 

  if(is_enabled($daemon)) {
     start($daemon);
  }

=cut
sub is_enabled
{
    my $daemon = shift;
    my $configurationDb = esmith::ConfigDB->open_ro();
    my $status = $configurationDb->get_prop($daemon, 'status') || 'unknown';
    my %runlevels = map { $_ => 1 } split(',', $configurationDb->get_prop($daemon, 'Runlevels'));

    my $currentRunlevel = qx('/sbin/runlevel');
    chomp($currentRunlevel);
    $currentRunlevel = [split(' ', $currentRunlevel)]->[1];

    if( $runlevels{$currentRunlevel} == 1 ) {
	return 1;
    }

    return 0;
}


1;
