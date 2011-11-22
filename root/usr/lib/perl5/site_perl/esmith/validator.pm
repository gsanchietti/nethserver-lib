#----------------------------------------------------------------------
# Copyright 2011 Nethesis - www.nethesis.it
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#----------------------------------------------------------------------

package esmith::validator;

use strict;
use Exporter;
use File::Basename;
use File::Temp qw/ :mktemp /;
use esmith::ConfigDB;
use POSIX;

use constant DEBUG => 0;


=pod

=head1 NAME

esmith::validator - Routines for handling system-wide validators

=head1 SYNOPSIS

    use esmith::validator;

    my $exitcode = validate($validator, @args);

=head1 DESCRIPTION

Validator uses bash exit values behaviour: 0 for success, 1 otherwise
Like esmith::event, validator search for all validators inside '/etc/e-smith/validators' directory and executes all scripts.
A success validation occurs when all scripts return 0 (success validation) or at least one script returns 2 (sufficient valid condition). 

Validator directory contains a variable name of scripts. Each script must return one of these exit values:

  0: successfull validation

  1: validation failed

  2: sufficient validation

When a script returns 2 (sufficient validation) no further script will be processed.

=cut

our $VERSION = sprintf '%d.%03d', q$Revision: 0.1 $ =~ /: (\d+).(\d+)/;
our @ISA         = qw(Exporter);
our @EXPORT      = qw(validate);

our @EXPORT_OK   = ();
our %EXPORT_TAGS = ();
our $return_value = undef;


sub validate
{
    my ($validator, @args) = @_;

    my $validators = "/etc/e-smith/validators";
    my $handlerDir = "$validators/$validator";

    #------------------------------------------------------------
    # get validator handler filenames
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

    #------------------------------------------------------------
    # Validator handlers are not supposed to generate error messages
    # under normal conditions, so we do not provide a mechanism
    # for validator handlers to signal errors to the user. Errors can
    # only be written to the log file.
    #------------------------------------------------------------
    debug("Processing validator: $validator @args");

    #------------------------------------------------------------
    # Run handlers, logging all output.
    #------------------------------------------------------------

    # assume success
    my $exitcode = 0;

    foreach my $filename
	(sort { $handlers{$a} cmp $handlers{$b} } keys %handlers)
    {
        my $handler = basename $filename;

        my $status = 0;
        if (-x $filename)
        {
            debug("Running validator handler: $filename");

            system($filename, @args);
            $status = $? >> 8; # real exit value is shifted right by eight
            debug("$filename: $status");
            if ($status == 0) # VALID
            {
            } elsif ($status == 1) # NOT VALID
            {
                # if any handler fails, the entire validator fails
                debug("INVALID");
                return 1;
            } elsif ($status == 2) # SUFFICIENT
            {
                debug("SUFFICIENT");
                return 0;
            }
        }
        else
        {
            debug("Skipping non-executable validator handler: $filename");
	    next;
        }

    }

    debug("validate: $exitcode");
    return $exitcode;
}

sub debug
{
    my $msg = shift;
    print "DEBUG: $msg\n" if DEBUG;
}

1;
