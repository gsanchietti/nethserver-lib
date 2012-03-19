#
# NethServer Password
#
# @copyright (C) 2012 Nethesis srl
#

package NethServer::Password;

use MIME::Base64 qw(encode_base64);

=head1 NAME

NethServer::Password module

=cut

=head2 makePassword($length)

Generate and returns a  random password of $length characters

=cut
sub makePassword
{
    my $length = shift || 16;
    my $password;
    open(RANDOM, "<", "/dev/urandom") or { warn "Cannot open /dev/urandom"; return undef };
    read(RANDOM, $password, 128);
    encode_base64($password);
    close(RANDOM);
    return substr($password, 0, $length);
}
