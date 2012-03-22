#
# NethServer Service
#
# Copyright (C) 2012 Nethesis srl
#

package NethServer::Service;

use strict;

=head1 NAME

NethServer::Servicem module

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

1;
