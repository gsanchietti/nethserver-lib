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

Check if $daemon is enabled in the current runlevel. Example

  if(is_enabled($daemon)) {
     start($daemon);
  }

=cut
sub is_enabled
{
    my $daemon = shift;
    my $configurationDb = esmith::ConfigDB->open_ro();
    my $status = $configurationDb->get_prop($daemon, 'status') || 'unknown';
    my @managedBy = split(',', $configurationDb->get_prop($daemon, 'managedBy') || '');

    if($status ne 'enabled') {
	return 0;
    }

    # Refs #1043. If a service is not managed by any package it is "disabled"
    if( ! @managedBy) {
	return 0;
    }

    my %runlevels = map { $_ => 1 } split(',', $configurationDb->get_prop($daemon, 'Runlevels'));

    my $currentRunlevel = qx('/sbin/runlevel');
    chomp($currentRunlevel);
    $currentRunlevel = [split(' ', $currentRunlevel)]->[1];

    if( $runlevels{$currentRunlevel} == 1 ) {
	return 1;
    }

    return 0;
}

=head2 manage_add($package, $service [, $service])

Mark $service as being managed by the given $package. Example, let
pkg1 manage svc1 and svc2

  manage_add('pkg1', 'svc1', 'svc2');

=cut 
sub manage_add
{
    my $packageName = shift;

    my $configDb = esmith::ConfigDB->open();

    foreach(@_) {
	my $serviceRecord = $configDb->get($_);

	if($configDb->prop('type') eq 'service') {	    
	    my %packageMap = map { $_ ne '' ? ($_ => 1) : () } split(',', $serviceRecord->prop('managedBy')), $packageName;
	    $configDb->set_prop('managedBy', join(',', keys %packageMap));
	} else {
	    warn "Unknown service key: $_, skipping";
	}
    }
}

=head2 manage_remove($package, $service [, $service])

Mark $service as being no more managed by the given $package. Example,
let pkg1 manage svc1 and svc2 anymore

  manage_remove('pkg1', 'svc1', 'svc2');

=cut 
sub manage_remove
{
    my $packageName = shift;

    my $configDb = esmith::ConfigDB->open();

    foreach(@_) {
	my $serviceRecord = $configDb->get($_);
	if($configDb->prop('type') eq 'service') {	    
	    my @packageList = grep { $_ ne $packageName && $_ ne '' } split(',', $serviceRecord->prop('managedBy'));
	    $configDb->set_prop('managedBy', join(',', @packageList));
	} else {
	    warn "Unknown service key: $_, skipping";
	}
    }
}

1;
