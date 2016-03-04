

use strict;
package NethServer::Database::Group;

sub TIEHASH {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub FETCH {
    my $self = shift;    
    my $key = shift;
    my @grent = getgrnam($key);    
    if( ! @grent) {
        return undef;
    }
    my @fields = qw(name passwd gid members);
    my %H = ();
    @H{@fields} = @grent;    
    my $value = 'group';
    foreach (keys %H) {
        if(defined $H{$_}) {
            $value .= '|' . $_ . '|' . $H{$_};
        }
    }    
    return $value;
}

sub EXISTS {
    my $self = shift;
    my $key = shift;
    return defined getgrnam($key);
}

sub FIRSTKEY {
    setgrent();
    return scalar getgrent();
}

sub NEXTKEY {
    return scalar getgrent();
}

1;