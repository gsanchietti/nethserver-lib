use strict;
package NethServer::Database;

sub TIEHASH {
    my $class = shift;
    my $connstring = shift;
    my @parts = split(/;/, $connstring);

    if($parts[0] =~ /::/) {
        # Remove any path prefix from the module name. This is 
        # almost equivalent to basename():            
        $parts[0] = (split(m|/|, $parts[0]))[-1];
    } else {
        unshift(@parts, 'esmith::config');
    }

    if( ! eval "require $parts[0]; 1") {    
        die("Cannot load module: $@");
    }
    return $parts[0]->TIEHASH($parts[1], @parts[2..$#parts], @_);
}

1;