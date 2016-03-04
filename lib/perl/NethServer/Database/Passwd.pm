

use strict;
package NethServer::Database::Passwd;

sub TIEHASH {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub FETCH {
    my $self = shift;    
    my $key = shift;
    my @pwent = getpwnam($key);    
    if( ! @pwent) {
        return undef;
    }
    my @fields = qw(name passwd uid gid quota comment gecos dir shell expire);
    my %H = ();
    @H{@fields} = @pwent;
    my $value = 'passwd';
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
    return defined getpwnam($key);
}

sub FIRSTKEY {
    setpwent();
    return scalar getpwent();
}

sub NEXTKEY {
    return scalar getpwent();
}

1;