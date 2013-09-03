#----------------------------------------------------------------------
# Copyright 1999-2005 Mitel Networks Corporation
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#----------------------------------------------------------------------

package esmith::event;

use strict;
use Exporter;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
use esmith::Logger;
use File::Basename;

=pod

=head1 NAME

esmith::event - Routines for handling e-smith events

=head1 SYNOPSIS

    use esmith::event;

    my $exitcode = event_signal($event, @args);

=head1 DESCRIPTION

=cut

our $VERSION = sprintf '%d.%03d', q$Revision: 1.16 $ =~ /: (\d+).(\d+)/;
our @ISA         = qw(Exporter);
our @EXPORT      = qw(event_signal);

our @EXPORT_OK   = ();
our %EXPORT_TAGS = ();
our $return_value = undef;

tie *LOG, 'esmith::Logger', 'esmith::event';

sub event_signal
{
    my ($event, @args) = @_;
    if ($event eq "actions")
    {
        warn("'actions' is not a valid event name.\n");
        return;
    }

    my $events = "/etc/e-smith/events";
    my $handlerDir = "$events/$event";

    #------------------------------------------------------------
    # get event handler filenames
    #------------------------------------------------------------
    opendir (DIR, $handlerDir)
        || die "Can't open directory $handlerDir\n";

    # Create a hash of handlers (ignore directories),
    # with value of basename(handler)
    my %handlers = ();
    foreach (grep {! -d "$handlerDir/$_"} readdir (DIR))
    {
	$handlers{"$handlerDir/$_"} = $_;
    }

    closedir (DIR);

    # Add generic handlers to list, if their metadata directories
    # exist
    $handlers{"$events/actions/generic_template_expand"} = "S05generic_template_expand"
	if ( -d "$handlerDir/templates2expand");
    $handlers{"$events/actions/adjust-services"} = "S90adjust-services"
	if ( -d "$handlerDir/services2adjust");

    #------------------------------------------------------------
    # Execute all handlers, sending any output to the system log.
    #
    # Event handlers are not supposed to generate error messages
    # under normal conditions, so we do not provide a mechanism
    # for event handlers to signal errors to the user. Errors can
    # only be written to the log file.
    #------------------------------------------------------------
    print LOG "Processing event: $event @args";

    #------------------------------------------------------------
    # Run handlers, logging all output.
    #------------------------------------------------------------

    # assume success
    my $exitcode = 1;

    foreach my $filename
	(sort { $handlers{$a} cmp $handlers{$b} } keys %handlers)
    {
        my $handler = basename $filename;
        my $startTime = [gettimeofday];

        my $status = -1;
        if (-x $filename)
        {
            print LOG "Running event handler: $filename";

            unless (($status = _mysystem(\*LOG, $filename, $event, @args)) == 0)
            {
                # if any handler fails, the entire event fails
                $exitcode = 0;
            }
        }
        else
        {
            print LOG "Skipping non-executable event handler: $filename";
	    next;
        }

        my $endTime = [gettimeofday];
        my $elapsedTime = tv_interval($startTime, $endTime);
        my $log = "$handler=action|Event|$event|Action|$handler";
        $log .= "|Start|@$startTime|End|@$endTime|Elapsed|$elapsedTime";
        $log .= "|Status|$status" if $status;
        print LOG $log;
    }

    return $exitcode;
}

sub _mysystem
{
    my ($logger, $filename, $event, @args) = @_;

    my $pid = open(PIPE, "-|");
    die "Failed to fork: $!\n" unless defined $pid;

    if ($pid)
    {
        # Parent
        while (my $line = <PIPE>)
        {
            print $logger $line;
        }
    }
    else
    {
        # Child
        open(STDERR, ">&STDOUT");
        exec($filename, $event, @args);
    }
    close(PIPE);
    return $?;
}


1;
