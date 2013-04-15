#
# NethServer Service
#

#
# Copyright (C) 2012 Nethesis S.r.l.
# http://www.nethesis.it - support@nethesis.it
# 
# This script is part of NethServer.
# 
# NethServer is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License,
# or any later version.
# 
# NethServer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with NethServer.  If not, see <http://www.gnu.org/licenses/>.
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

    qx($service $daemon status >/dev/null 2>&1);
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

    qx($service $daemon status >/dev/null 2>&1);
    if ( $? != 0 ) {
	return 0;
    } 

    qx($service $daemon stop >/dev/null 2>&1);
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

    if($status ne 'enabled') {
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

1;
