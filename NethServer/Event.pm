#
# NethServer Event
#
# Copyright (C) 2012 Nethesis srl
#

package NethServer::Event;

our $QUEUE_DIR='/var/spool/nethserver/';
our $QUEUE_LINK= $QUEUE_DIR . 'current';

use strict;
use Data::UUID;
use esmith::event qw(event_signal);

=head1 NAME

NethServer::Event module

Extends the event_signal function with a queue.  The queue is
tipically enabled during system upgrade or installation by the
installer program. 

Refs #843

=cut


=head2 queue_is_enabled

Check if events are queued or not

=cut
sub queue_is_enabled
{
    return -l $QUEUE_LINK && -f $QUEUE_DIR . (readlink $QUEUE_LINK);
}

=head2 queue_flush

Flush the event queue without executing the events.

The queue is disabled after this operation.

=cut
sub queue_flush
{
    my $queue_file = $QUEUE_DIR . (readlink $QUEUE_LINK);

    if(-l $QUEUE_LINK) {
	unlink $QUEUE_LINK;
    }

    if(-f $queue_file) {
	unlink $queue_file;
    }
}

=head2 queue_signal

Signal enqueued events, then flush.

=cut
sub queue_signal
{
    if( ! queue_is_enabled()) {
	return 0; # Error
    }

    my $events = queue_read();
    my $errors = 0;

    foreach (@$events) {
	my $success = esmith::event::event_signal(@{$_});	
	if(! $success) {
	    $errors ++;
	}
    }

    queue_flush();
    return $errors == 0;
}


=head2 queue_read

Read the current queue content and return it.

The return value is an array reference to the event list.

=cut
sub queue_read
{
    open(my $queue_file, "<", $QUEUE_LINK);
    my $errors = 0;
    my $events = [];

    while(my $event_spec = <$queue_file>) {
	chomp($event_spec);
	push @$events, [split("\t", $event_spec)];
    }
    close($queue_file);

    return $events;
}

=head2 queue_initialize

Create an empty queue and enable it

=cut
sub queue_initialize
{
    my $uuid = new Data::UUID;
    my $queue_file = 'q-' . $uuid->to_string($uuid->create());

    queue_flush();
    
    my $current_mask = umask 0133;
    open(my $fd, ">", $QUEUE_DIR . $queue_file);
    close($fd);
    umask $current_mask;

    symlink $queue_file, $QUEUE_LINK;
}

=head2 queue_add(@event_spec) 

Store an event in the current queue for later invocation

=cut
sub queue_add
{
    my @args = @_;
    if(!queue_is_enabled()) {
	queue_initialize();
    }

    open(my $queue_file, ">>", $QUEUE_LINK);
    print $queue_file join("\t", @args) . "\n" ;
    close($queue_file);
}

=head2 signal($event, @args)

Wrap esmith::event::event_signal function, by checking if the event queue is enabled.

=cut
sub signal
{
    if(queue_is_enabled()) {
	queue_add(@_);
	return 1;
    } else {
	return event_signal(@_);
    }
}

1;
