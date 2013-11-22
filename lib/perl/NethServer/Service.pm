#
# NethServer Service
#

#
# Copyright (C) 2013 Nethesis S.r.l.
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

our $legacySupport = 1;

=head1 NAME

NethServer::Service module

=cut

=head2 ->new

Create a Service object

Arguments:

=over 1

=item $serviceName

The service to wrap

=item $configDb (optional)

An opened Configuration database

=back

=cut
sub new 
{
    my $class = shift;
    my $serviceName = shift;
    my $configDb = shift;

    if( ! $configDb ) {
	$configDb = esmith::ConfigDB->open_ro() || die("Could not open ConfigDB");
    }

    my $backend = 'none';
    
    if( -e "/etc/init/${serviceName}.conf") {
	$backend = 'upstart';
    } elsif( -e "/etc/rc.d/init.d/${serviceName}") {
	$backend = 'sysv';
    }

    my $self = {
	'serviceName' => $serviceName,
	'configDb' => $configDb,
	'verbose' => 0,
	'backend' => $backend
    };


    bless $self, $class;

    return $self;
}


=head2 ->start
    
Start the service if it is stopped

WARNING: Static invocation is supported for backward compatibility and
will be removed in the future.

=cut
sub start
{
    my $self = shift;

    if( $legacySupport && ! ref($self) ) {
	my $daemon = $self;
	$self = NethServer::Service->new($daemon);
    }

    if ( ! $self->is_running() ) {
	return $self->_set_running(1);
    }

    return 1;
}


=head2 ->stop
    
Stop the service if it is running

WARNING: Static invocation is supported for backward compatibility and
will be removed in the future.

=cut
sub stop
{
    my $self = shift;

    if( $legacySupport && ! ref($self) ) {
	my $daemon = $self;
	$self = NethServer::Service->new($daemon);
    }

    if($self->is_running()) {  
	return $self->_set_running(0);
    }

    return 1;
}

=head2 ->condrestart

=cut
sub condrestart
{
    my $self = shift;

    if($self->{'backend'} eq 'sysv') {
	return system($self->_get_command('condrestart')) == 0;	
    } elsif($self->{'backend'} eq 'upstart' && $self->is_running()) {
	return $self->restart();
    } 
    return 0;
}

=head2 ->restart

=cut
sub restart
{
    my $self = shift;

    if($self->{'backend'} eq 'sysv') {
	return system($self->_get_command('restart')) == 0;	
    } elsif($self->{'backend'} eq 'upstart') {
	return system('/sbin/restart', $self->{'serviceName'}) == 0;
    } 

    return 0;
}

=head2 ->reload

=cut
sub reload
{
    my $self = shift;

    if($self->{'backend'} eq 'sysv') {
	return system($self->_get_command('reload')) == 0;
    } elsif($self->{'backend'} eq 'upstart') {
	# Test if a "reload" task is defined:
	if( -e "/etc/init/$self->{serviceName}-reload.conf") {
	    return system('/sbin/start', "$self->{serviceName}-reload") == 0;
	} else {
	    return system('/sbin/reload', $self->{'serviceName'}) == 0;
	}
    } 

    return 0;
}


=head2 ->is_configured

Check if the service is defined in configuration database

=cut
sub is_configured
{
    my $self = shift;
    my $record = $self->{'configDb'}->get($self->{'serviceName'});
    if(defined $record && $record->prop('type') eq 'service') {
	return 1;
    }
    return 0;
}


=head2 ->is_enabled

Check if the service is enabled in configuration database. 

WARNING: Static invocation is supported for backward compatibility and
will be removed in the future. Optionally, you can pass an already
opened esmith::ConfigDB object in $configDb. Example:

  if(is_enabled($daemon)) {
     start($daemon);
  }

=cut
sub is_enabled
{
    my $self = shift;

    if( $legacySupport && ! ref($self) ) {
	my $daemon = shift;
	my $configDb = shift;

	$configDb = $daemon;
	$daemon = $self;
	$self = NethServer::Service->new($daemon, $configDb);
    }

    my $status = $self->{'configDb'}->get_prop($self->{'serviceName'}, 'status') || 'unknown';

    if($status eq 'enabled') {
	return 1;
    }

    return 0;
}

=head2 ->is_owned

Check if the service is owned by a currently installed package.

=cut
sub is_owned
{
    my $self = shift;
    my $typePath = '/etc/e-smith/db/configuration/defaults/' . $self->{'serviceName'} . '/type';

    if( -f $typePath ) {
	open(FH, '<', $typePath) || warn "[ERROR] $typePath:" . $! . "\n";
	my $line = <FH>;
	chomp $line;
	if($line eq 'service') {
	    return 1;
	}
	close(FH);
    }
    return 0;
}

=head2 ->is_running

Check if the service is running.

=cut
sub is_running
{
    my $self = shift;

    if($self->{'backend'} eq 'upstart') {
	# DBus hack to get job instance running state in exit code:
	$self->{'isRunning'} = _silent_system(
	    qw(/bin/dbus-send --system --print-reply --dest=com.ubuntu.Upstart), 
	    sprintf('/com/ubuntu/Upstart/jobs/%s/_', 
		    _escape_dbus($self->{'serviceName'})), 
	    qw(org.freedesktop.DBus.Properties.GetAll string:'')) == 0;
    } elsif($self->{'backend'} eq 'sysv') {
	$self->{'isRunning'} = _silent_system($self->_get_command('status')) == 0;
    } else {
	$self->{'isRunning'} = 0;
    }
   
    return $self->{'isRunning'};
}

=head2 ->adjust

Adjust the service startup state and running state according to its
configuration, status prop and the owning package installation status.

The output parameter $action is set to 'start' or 'stop' if the
service is actually started or stopped.

Parameters:
    $action string by ref (OUT) 

Returns a boolean value: success/failure

=cut
sub adjust
{
    my $self = shift;
    my $action = shift;
    my $success = 1;

    if($self->is_configured()) {
	my $staticState = $self->is_owned() && $self->is_enabled();
	if($self->{'backend'} eq 'sysv') {
	    if( ! $self->_set_sysv_startup($staticState)) {
		$success = 0;
	    }
	}
	if($staticState != $self->is_running()) {
	    if($self->_set_running($staticState)) {
		$$action = $staticState ? 'start' : 'stop';
	    } else {
		$success = 0;
	    }
	} 
    } 

    return $success;
}

=head2 ->get_name

Return the service name

=cut
sub get_name
{
    my $self = shift;
    return $self->{'serviceName'};
}

##################################################
# Private methods
##################################################

#
# Enable/disable the service automatic bootstrap startup. 
#
sub _set_sysv_startup
{
    my $self = shift;
    my $action = shift;

    if(system('/sbin/chkconfig', $self->{'serviceName'}, $action ? 'on' : 'off') != 0) {
	return 0; # FAILURE
    }

    return 1; # OK
}

#
# Start/stop the service 
#
sub _set_running
{
    my $self = shift;
    my $state = shift;

    if(system($self->_get_command($state ? 'start' : 'stop')) != 0) {
	return 0; # FAILURE
    }

    $self->{'isRunning'} = $state ? 1 : 0;
    return 1; # OK
}

#
# Get the right command to control the service
#
sub _get_command
{
    my $self = shift;
    my $action = shift;
    my $command;

    if($self->{'backend'} eq 'upstart') {
	$command = join(' ', '/sbin/initctl', $action, ,$self->{'serviceName'});
    } elsif($self->{'backend'} eq 'sysv') {
	$command = join(' ', '/sbin/service', $self->{'serviceName'}, $action);
    } else {
	$command = '/bin/false';
    }

    return $command;
}


#
# Execute system, closing STDOUT and STDERR descriptors
#
sub _silent_system
{
    if(fork()) {
	wait();
	return $?;
    } else {
	open(STDOUT, '/dev/null');
	open(STDERR, '/dev/null');
	exec(@_);
    }
}

#
# DBus job names have special chars escaped
#
sub _escape_dbus
{
    my $s = shift;
    $s =~ s/-/_2d/g;
    return $s;
}

1;
