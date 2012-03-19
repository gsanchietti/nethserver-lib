#----------------------------------------------------------------------
# Copyright 1999-2005 Mitel Networks Corporation
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#----------------------------------------------------------------------

package esmith::ethernet;

#----------------------------------------------------------------------

use strict;

=head1 NAME

esmith::ethernet - Ethernet-related utility routines for e-smith

=head1 VERSION

This file documents C<esmith::ethernet> version B<1.4.0>

=head1 SYNOPSIS

    use esmith::ethernet;

=head1 DESCRIPTION

This module contains routines for 


=pod

=head2 listDevices()

Query udev for all devices

=cut

sub listDevices ()
{
    open("UDEV", "/sbin/udevadm info --export-db|");
    my @list;
    my $dev;
    while (my $line = <UDEV>) {
       chomp($line);
       if($line =~ /^P: (.*)/)
       {
           push (@list, $dev);
           $dev = {};
           $dev->{'name'} = $1;
       } elsif ($line =~ /^E: (.*)=(.*)/) {
           $dev->{$1} = $2;
       }
    }
    close (UDEV);

    return @list;
}



=pod

=head2 probeAdapters()

Probe for any recognised adapters

=cut

sub probeAdapters ()
{
    my $adapters  = '';
    my @devs = listDevices();
    my $index = 1;
    foreach my $nic (@devs) {
        if($nic->{'SUBSYSTEM'} eq "net" && $nic->{'INTERFACE'} ne 'lo' ) 
        {
          $adapters .=
          "EthernetDriver" . $index++ . "\t" . $nic->{INTERFACE_NAME} . "\t"
          . $nic->{'MATCHADDR'} . "\t" . $nic->{ID_MODEL_FROM_DATABASE} . "\n";
        }
    }
    return $adapters;
}


#----------------------------------------------------------------------
# Return one to make the import process return success.
#----------------------------------------------------------------------

1;

=pod

=AUTHOR

SME Server Developers <bugs@e-smith.com>

For more information see http://www.e-smith.org/

=cut

