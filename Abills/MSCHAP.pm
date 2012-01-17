# MSCHAP.pm
# Implements MSCHAP algorithms as described in 
# draft-ietf-pppext-mschap-00.txt and RFC3079
# Requires Digest-MD4-1.0 or better, available from CPAN and 
# ActiveState
#
# Author: Mike McCauley (mikem@open.com.au)
#
# This code is offered on the same terms as draft-ietf-pppext-mschap-00.txt
# $Id: MSCHAP.pm,v 1.2.2.1 2007/11/15 11:05:20 abills Exp $

package Radius::MSCHAP;
use strict;
use Digest::MD4;
use Abills::DES;

# Convert an ascii plaintext password into its unicode
# equivalent, by interposing NUL chars after each ASCII char
sub ASCIItoUnicode
{
    return join('', map {($_, "\0")} split(//, $_[0]));
}

sub LmChallengeResponse
{
    my ($challenge, $password) = @_;

    my $pwhash = LmPasswordHash($password);
    return ChallengeResponse($challenge, $pwhash);
}

# password is 0 to 14 chars
sub LmPasswordHash
{
    my ($password) = @_;

    my $ucpw = uc $password . "\0" x (14 - length($password));
    my $pwhash = DesHash(substr($ucpw, 0, 7));
    $pwhash .= DesHash(substr($ucpw, 7, 7));
    return $pwhash;
}

# Make Cypher an irreversibly encrypted form of Clear by
# encrypting known text using Clear as the secret key.
# The known text consists of the string
#    KGS!@#$%
sub DesHash
{
    my ($clear) = @_;

    return DesEncrypt('KGS!@#$%', $clear);
}

sub NtChallengeResponse
{
    my ($challenge, $password) = @_;

    my $pwhash = NtPasswordHash($password);
    return ChallengeResponse($challenge, $pwhash);
}

sub NtPasswordHash
{
    my ($password) = @_;

    my $md4 = new Digest::MD4;
    return $md4->hash($password);
}

# Need to convert the 7 byte key into 8 bytes of odd parity
# but the DESencryptor ignores the parity so we always
# set the parity bit to 0
sub DesParity
{
    my ($key) = @_;

    my $ks = unpack('B*', $key);
    my ($index, $pkey);
    foreach $index (0 .. 7)
    {
	$pkey .= pack('B*',  substr($ks, $index * 7, 7) . '0'); # parity bit is 0
    }
    return $pkey;
}

sub DesEncrypt
{
    my ($clear, $key) = @_;

    my $pkey = DesParity($key);
    my @ks =  Radius::DES::des_set_key($pkey);
    return Radius::DES::des_ecb_encrypt(\@ks, 1, $clear);   
}

sub ChallengeResponse
{
    my ($challenge, $pwhash) = @_;

    my $response;
    # Pad PasswordHash zero-padded to 21 octets
    my $zpwhash = $pwhash . "\0" x (21 - length($pwhash));
 
    $response = DesEncrypt($challenge, substr($zpwhash, 0, 7));
    $response .= DesEncrypt($challenge, substr($zpwhash, 7, 7));
    $response .= DesEncrypt($challenge, substr($zpwhash, 14, 7));


    return $response;
}





sub bin2hex ($) {
 my $bin = shift;
 my $hex = '';
 
 
 for my $c (unpack("H*",$bin)){
   $hex .= $c;
 }
 return $hex;
}




# MSCHAP V2 support:
# See draft-ietf-radius-ms-vsa-01.txt,
# draft-ietf-pppext-mschap-v2-00.txt and RFC 2548

sub GenerateNTResponse
{
    my ($authchallenge, $peerchallenge, $username, $password) = @_;

    my $challenge = ChallengeHash
	($peerchallenge, $authchallenge, $username);
    my $passwordhash = NtPasswordHash($password);
    my $response = ChallengeResponse($challenge, $passwordhash);
    return $response;
}

sub ChallengeHash
{
    my ($peerchallenge, $authchallenge, $username) = @_;

    require Digest::SHA1;
    return substr(Digest::SHA1::sha1($peerchallenge . $authchallenge . $username ), 0, 8);
}

my $magic1 = pack('H*', '4D616769632073657276657220746F20636C69656E74207369676E696E6720636F6E7374616E74');
my $magic2 = pack('H*', '50616420746F206D616B6520697420646F206D6F7265207468616E206F6E6520697465726174696F6E');

# Pass this one a prehashed password
sub GenerateAuthenticatorResponseHash
{
    require Digest::SHA1;

    my ($pwhashhash, $ntresponse, $peerchallenge, $authchallenge, $username) = @_;

    my $digest = Digest::SHA1::sha1($pwhashhash . $ntresponse . $magic1);

    my $challenge = ChallengeHash($peerchallenge, $authchallenge, $username);
    $digest = Digest::SHA1::sha1($digest . $challenge . $magic2);
    return "S=" . uc(unpack('H*', $digest));
}

# Obsolete?
sub GenerateAuthenticatorResponse
{
    require Digest::SHA1;

    my ($password, $ntresponse, $peerchallenge, $authchallenge, $username) = @_;

    return GenerateAuthenticatorResponseHash
	(NtPasswordHash(NtPasswordHash($password)), 
	 $ntresponse, $peerchallenge, $authchallenge, $username);
}

# Following is support for RFC3079 MPPE send and recv keys

my $SHSpad1 = "\x00" x 40;
my $SHSpad2 = "\xf2" x 40;
my $mppeMagic1 = pack('H*', '5468697320697320746865204d505045204d6173746572204b6579');
my $mppeMagic2 = pack('H*', '4f6e2074686520636c69656e7420736964652c2074686973206973207468652073656e64206b65793b206f6e207468652073657276657220736964652c206974206973207468652072656365697665206b65792e');
my $mppeMagic3 = pack('H*', '4f6e2074686520636c69656e7420736964652c2074686973206973207468652072656365697665206b65793b206f6e207468652073657276657220736964652c206974206973207468652073656e64206b65792e');

sub mppeGetKeys
{
    my ($nt_hashhash, $nt_response, $requiredlen) = @_;

    my $masterkey = GetMasterKey($nt_hashhash, $nt_response);
    return (GetAsymmetricStartKey($masterkey, $requiredlen, 1, 1), 
	    GetAsymmetricStartKey($masterkey, $requiredlen, 0, 1));
}

sub GetMasterKey
{
    my ($nt_hashhash, $nt_response) = @_;

    require Digest::SHA1;
    return substr(Digest::SHA1::sha1($nt_hashhash . $nt_response . $mppeMagic1), 0, 16);
}

sub GetAsymmetricStartKey {
    my ($masterkey, $requiredlen, $issend, $isserver) = @_;

    my $s = ($issend ^ $isserver) ? $mppeMagic2 : $mppeMagic3;
    require Digest::SHA1;
    return substr(Digest::SHA1::sha1($masterkey . $SHSpad1 . $s . $SHSpad2), 0, $requiredlen);
}


1;
