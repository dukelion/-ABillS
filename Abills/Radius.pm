#############################################################################
#                                                                           #
# Radius Client module for Perl 5                                           #
#                                                                           #
# Written by Carl Declerck <carl@miskatonic.inbe.net>, (c)1997              #
# All Rights Reserved. See the Perl Artistic License for copying & usage    #
# policy.                                                                   #
#                                                                           #
# Modified by Olexander Kapitanenko <kapitan@portaone.com>,                 #
#             Andrew Zhilenko <andrew@portaone.com>, 2002-2004.             #
#                                                                           #
# See the file 'Changes' in the distrution archive.                         #
#                                                                           #
#############################################################################
# 	$Id: Radius.pm,v 1.2.2.2 2008/10/25 11:55:06 abills Exp $


package Radius;

use strict;
use FileHandle;
use IO::Socket;
use IO::Select;
use Digest::MD5;

use vars qw($VERSION @ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(ACCESS_REQUEST ACCESS_ACCEPT ACCESS_REJECT
			 ACCOUNTING_REQUEST ACCOUNTING_RESPONSE ACCOUNTING_STATUS POD_REQUEST COA_REQUEST);
$VERSION = '0.12';

my (%dict_id, %dict_name, %dict_val, %dict_vendor_id, %dict_vendor_name );
my ($request_id) = $$ & 0xff;	# probably better than starting from 0
my ($radius_error) = 'ENONE';
my $debug = 0;

#
# we'll need to predefine these attr types so we can do simple password
# verification without having to load a dictionary
#

$dict_id{'not defined'}{1}{'type'} = 'string';	# set 'username' attr type to string
$dict_id{'not defined'}{2}{'type'} = 'string';	# set 'password' attr type to string
$dict_id{'not defined'}{4}{'type'} = 'ipaddr';	# set 'NAS-IP-Address' attr type to string

use constant ACCESS_REQUEST               => 1;
use constant ACCESS_ACCEPT                => 2;
use constant ACCESS_REJECT                => 3;
use constant ACCOUNTING_REQUEST           => 4;
use constant ACCOUNTING_RESPONSE          => 5;
use constant ACCOUNTING_STATUS            => 6;
use constant POD_REQUEST                  => 40;
use constant COA_REQUEST                  => 43;

sub new {
	my $class = shift;
	my %h = @_;
	my ($host, $port, $service);
	my $self = {};

	bless $self, $class;

	$self->set_error;
	$debug = $h{Debug};

	return $self->set_error('ENOHOST') unless $h{'Host'};
	($host, $port) = split(/:/, $h{'Host'});

	$service = $h{'Service'} ? $h{'Service'} : 'radius';

	$port = getservbyname($service, 'udp') unless $port;

	unless ($port) {
		my %services = ( radius        => 1812, 
		                 radacct       => 1646,
						         'radius-acct' => 1813 );
		if (exists($services{$service})) {
			$port = $services{$service};
		} else {
		  return $self->set_error('EBADSERV');
		}
	}

	$self->{'timeout'} = $h{'TimeOut'} ? $h{'TimeOut'} : 5;
	$self->{'secret'} = $h{'Secret'};
	print STDERR "Using Radius server $host:$port\n" if $debug;
	$self->{'sock'} = new IO::Socket::INET(
				PeerAddr => $host,
				PeerPort => $port,
				Type => SOCK_DGRAM,
				Proto => 'udp',
				TimeOut => $self->{'timeout'}
	) or return $self->set_error('ESOCKETFAIL');

	$self;
}

sub send_packet {
	my ($self, $type) = @_;
	my ($data);
	my $length = 20 + length($self->{'attributes'});

	$self->set_error;
        if (($type == ACCOUNTING_REQUEST) || ($type == POD_REQUEST) || ($type == COA_REQUEST)) {
	  $self->{'authenticator'} = "\0" x 16;
	  $self->{'authenticator'} =
	    $self->calc_authenticator($type, $request_id, $length)
	} else {
	  $self->gen_authenticator unless defined $self->{'authenticator'};
	}
	$data = pack('C C n', $type, $request_id, $length)
				. $self->{'authenticator'} . $self->{'attributes'};
	$request_id = ($request_id + 1) & 0xff;
#	if ($debug) {
#		print STDERR "Sending request:\n";
#		print HexDump $data;
#	}
	$self->{'sock'}->send ($data) || $self->set_error('ESENDFAIL');
}

sub recv_packet {
	my ($self) = @_;
	my ($data, $type, $id, $length, $auth, $sh);

	$self->set_error;

	$sh = new IO::Select($self->{'sock'}) or return $self->set_error('ESELECTFAIL');
	$sh->can_read($self->{'timeout'}) or return $self->set_error('ETIMEOUT');

	$self->{'sock'}->recv ($data, 65536) or return $self->set_error('ERECVFAIL');

#	if ($debug) {
#		print STDERR "Received response:\n";
#		print HexDump $data;
#	}


	($type, $id, $length, $auth, $self->{'attributes'}) = unpack('C C n a16 a*', $data);
	return $self->set_error('EBADAUTH') if $auth ne $self->calc_authenticator($type, $id, $length);

	$type;
}

sub check_pwd {
	my ($self, $name, $pwd, $nas) = @_;

	$self->clear_attributes;
	$self->add_attributes (
		{ Name => 1, Value => $name, Type => 'string' },
		{ Name => 2, Value => $pwd, Type => 'string' },
		{ Name => 4, Value => $nas || '127.0.0.1', Type => 'ipaddr' }
	);

	$self->send_packet(ACCESS_REQUEST);
	my $rcv = $self->recv_packet();
	return (defined($rcv) and $rcv == ACCESS_ACCEPT);
}

sub clear_attributes {
	my ($self) = @_;

	$self->set_error;

	delete $self->{'attributes'};

	1;
}

sub get_attributes {
	my ($self) = @_;
	my ($vendor, $vendor_id, $id, $length, $value, $type, $rawvalue, @a);
	my ($attrs) = $self->{'attributes'};

	$self->set_error;
	my $vendor_specific = $dict_name{'Vendor-Specific'}{'id'};

	while (length($attrs)) {
		($id, $length, $attrs) = unpack('C C a*', $attrs);
		($rawvalue, $attrs) = unpack('a' . ($length - 2) . ' a*', $attrs);
		if ( defined($vendor_specific) and $id == $vendor_specific ) {
			($vendor_id, $id, $length, $rawvalue) = unpack('N C C a*', $rawvalue);
			$vendor = defined $dict_vendor_id{$vendor_id}{'name'} ? $dict_vendor_id{$vendor_id}{'name'} : $vendor_id;
		} else {
			$vendor = 'not defined';
		}
		$type = $dict_id{$vendor}{$id}{'type'} || '';
		if ($type eq "string") {
			if ($id == 2 && $vendor eq 'not defined' ) {
				$value = '<encrypted>';
			} else {
				$value = $rawvalue;
			}
		} elsif ($type eq "integer") {
			$value = unpack('N', $rawvalue);
			$value = $dict_val{$id}{$value}{'name'} if defined $dict_val{$id}{$value}{'name'};
		} elsif ($type eq "ipaddr") {
			$value = inet_ntoa($rawvalue);
		} elsif ($type eq "avpair") {
			$value = $rawvalue;
			$value =~ s/^.*=//;
		} elsif ($type eq 'sublist') {
			# never got a chance to test it, since it seems that Digest attributes only come from clients
			my ($subid, $subvalue, $sublength, @values);
			$value = ''; my $subrawvalue = $rawvalue;
			while (length($subrawvalue)) {
			    ($subid, $sublength, $subrawvalue) = unpack('C C a*', $subrawvalue);
			    ($subvalue, $subrawvalue) = unpack('a' . ($sublength - 2) . ' a*', $subrawvalue);
			    my $subname = $dict_val{$id}->{$subid}->{'name'};
			    push @values, "$subname = \"$subvalue\"";
			}
			$value = join("; ", @values);
		}

		push (@a, {	'Name' => defined $dict_id{$vendor}{$id}{'name'} ? $dict_id{$vendor}{$id}{'name'} : $id,
					'Code' => $id,
					'Value' => $value,
					'RawValue' => $rawvalue,
					'Vendor' => $vendor }
		);
	}

	return @a;
}

sub add_attributes {
	my ($self, @a) = @_;
	my ($a, $vendor, $id, $type, $value);

	$self->set_error;

	for $a (@a) {
		$id = defined $dict_name{$a->{'Name'}}{'id'} ? $dict_name{$a->{'Name'}}{'id'} : int($a->{'Name'});
		$type = defined $a->{'Type'} ? $a->{'Type'} : $dict_name{$a->{'Name'}}{'type'};
		$vendor = defined $a->{'Vendor'} ? ( defined $dict_vendor_name{ $a->{'Vendor'} }{'id'} ? $dict_vendor_name{ $a->{'Vendor'} }{'id'} : int($a->{'Vendor'}) ) : ( defined $dict_name{$a->{'Name'}}{'vendor'} ? $dict_vendor_name{ $dict_name{$a->{'Name'}}{'vendor'} }{'id'} : 'not defined' );
		if ($type eq "string") {
			$value = $a->{'Value'};
			if ($id == 2 && $vendor eq 'not defined' ) {
				$self->gen_authenticator();
				$value = $self->encrypt_pwd($value);
			}
			$value = substr($value, 0, 253);
		} elsif ($type eq "integer") {
			my $enc_value;
			if ( defined $dict_val{$id}{$a->{'Value'}}{'id'} ) {
				$enc_value = $dict_val{$id}{$a->{'Value'}}{'id'};
			} else {
				$enc_value = int($a->{'Value'});
			}
			$value = pack('N', $enc_value);
		} elsif ($type eq "ipaddr") {
			$value = inet_aton($a->{'Value'});
		} elsif ($type eq "avpair") {
			$value = $a->{'Name'}.'='.$a->{'Value'};
			$value = substr($value, 0, 253);
		} elsif ($type eq 'sublist') {
		    # Digest attributes look like:
			# Digest-Attributes                = 'Method = "REGISTER"'
			my $digest = $a->{'Value'};
			my @pairs;
			if (ref($digest)) {
				next unless ref($digest) eq 'HASH';
				foreach my $key (keys %{$digest}) {
					push @pairs, [ $key => $digest->{$key} ];
				}
			} else {
				# string
				foreach my $z (split(/\"\; /, $digest)) {
					my ($subname, $subvalue) = split(/\s+=\s+\"/, $z, 2);
					$subvalue =~ s/\"$//;
					push @pairs, [ $subname => $subvalue ];
				}
			}
			$value = '';
			foreach my $da (@pairs) {
				my ($subname, $subvalue) = @{$da};
				my $subid = $dict_val{$id}->{$subname}->{'id'};
				next unless defined($subid);
				$value .= pack('C C', $subid, length($subvalue) + 2) . $subvalue;
			}
		} else {
			next;
		}
		print STDERR "Adding attribute $a->{Name} ($id) with value '$a->{Value}'\n" if $debug;
		if ( $vendor eq 'not defined' ) {
			$self->{'attributes'} .= pack('C C', $id, length($value) + 2) . $value;
		} else {
			$value = pack('N C C', $vendor, $id, length($value) + 2) . $value;
			$self->{'attributes'} .= pack('C C', $dict_name{'Vendor-Specific'}{'id'}, length($value) + 2) . $value;
		}
	}
	return 1;
}


sub calc_authenticator {
	my ($self, $type, $id, $length) = @_;
	my ($hdr, $ct);

	$self->set_error;

	$hdr = pack('C C n', $type, $id, $length);
	$ct = Digest::MD5->new;
	$ct->add ($hdr, $self->{'authenticator'}, $self->{'attributes'}, $self->{'secret'});

	$ct->digest();
}

sub gen_authenticator {
	my ($self) = @_;
	my ($ct);

	$self->set_error;

	$ct = Digest::MD5->new;
	# the following could be improved a lot
	$ct->add (sprintf("%08x%04x", time, $$), $self->{'attributes'} || '');

	$self->{'authenticator'} = $ct->digest();
}

sub encrypt_pwd {
	my ($self, $pwd) = @_;
	my ($i, $ct, @pwdp, @encrypted);

	$self->set_error;
	$ct = Digest::MD5->new();

	my $non_16 = length($pwd) % 16;
	$pwd .= "\0" x (16 - $non_16) if $non_16;
	@pwdp = unpack('a16' x (length($pwd) / 16), $pwd);
	for $i (0..$#pwdp) {
		my $authent = $i == 0 ? $self->{'authenticator'} : $encrypted[$i - 1];
		$ct->add($self->{'secret'},  $authent);
		$encrypted[$i] = $pwdp[$i] ^ $ct->digest();
	}
	return join('',@encrypted);
}
use vars qw(%included_files);

sub load_dictionary {
	shift;
	my ($file) = @_;
	my ($fh, $cmd, $name, $id, $type, $vendor);

	unless ($file) {
		$file = "/etc/raddb/dictionary";
	}
	# prevent infinite loop in the include files
	return undef if exists($included_files{$file});
	$included_files{$file} = 1;
	$fh = new FileHandle($file) or die "Can't open dictionary '$file' ($!)\n";
	print STDERR "Loading dictionary $file\n" if $debug;

	while (<$fh>) {
		chomp;
		($cmd, $name, $id, $type, $vendor) = split(/\s+/);
		next if (!$cmd || $cmd =~ /^#/);
		if (lc($cmd) eq 'attribute') {
			if( !$vendor ) {
				$dict_id{'not defined'}{$id}{'name'} = $name;
				$dict_id{'not defined'}{$id}{'type'} = $type;
			} else {
				$dict_id{$vendor}{$id}{'name'} = $name;
				$dict_id{$vendor}{$id}{'type'} = $type;
			}
			$dict_name{$name}{'id'} = $id;
			$dict_name{$name}{'type'} = $type;
			$dict_name{$name}{'vendor'} = $vendor if $vendor;
		} elsif (lc($cmd) eq 'value') {
			next unless exists($dict_name{$name});
			$dict_val{$dict_name{$name}->{'id'}}->{$type}->{'name'} = $id;
			$dict_val{$dict_name{$name}->{'id'}}->{$id}->{'id'} = $type;
		} elsif (lc($cmd) eq 'vendor') {
			$dict_vendor_name{$name}{'id'} = $id;
			$dict_vendor_id{$id}{'name'} = $name;
		} elsif (lc($cmd) eq '$include') {
			my @path = split("/", $file);
			pop @path; # remove the filename at the end
			my $path = ( $name =~ /^\// ) ? $name : join("/", @path, $name);
			load_dictionary('', $path);
		}
	}
	$fh->close;

	1;
}

sub set_error {
	my ($self, $error) = @_;

	$radius_error = $self->{'error'} = defined $error ? $error : 'ENONE';

	undef;
}

sub get_error {
	my ($self) = @_;

	$self->{'error'};
}

sub strerror {
	my ($self, $error) = @_;

	my %errors = (
		'ENONE',	'none',
		'ESELECTFAIL',	'select creation failed',
		'ETIMEOUT',	'timed out waiting for packet',
		'ESOCKETFAIL',	'socket creation failed',
		'ENOHOST',	'no host specified',
		'EBADAUTH',	'bad response authenticator',
		'ESENDFAIL',	'send failed',
		'ERECVFAIL',	'receive failed',
		'EBADSERV',	'unrecognized service'
	);

	return $errors{$radius_error} unless ref($self);
	$errors{defined $error ? $error : $self->{'error'}};
}


1;
__END__

=head1 NAME

Authen::Radius - provide simple Radius client facilities

=head1 SYNOPSIS

  use Authen::Radius;

  $r = new Authen::Radius(Host => 'myserver', Secret => 'mysecret');
  print "auth result=", $r->check_pwd('myname', 'mypwd'), "\n";

  $r = new Authen::Radius(Host => 'myserver', Secret => 'mysecret');
  Authen::Radius->load_dictionary();
  $r->add_attributes (
  		{ Name => 'User-Name', Value => 'myname' },
  		{ Name => 'Password', Value => 'mypwd' },
# RFC 2865 http://www.ietf.org/rfc/rfc2865.txt calls this attribute
# User-Password. Check your local RADIUS dictionary to find
# out which name is used on your system
#  		{ Name => 'User-Password', Value => 'mypwd' },
  		{ Name => 'h323-return-code', Value => '0' }, # Cisco AV pair
		{ Name => 'Digest-Attributes', Value => { Method => 'REGISTER' } }
  );
  $r->send_packet(ACCESS_REQUEST) and $type = $r->recv_packet();
  print "server response type = $type\n";
  for $a ($r->get_attributes()) {
  	print "attr: name=$a->{'Name'} value=$a->{'Value'}\n";
  }

=head1  DESCRIPTION

The C<Authen::Radius> module provides a simple class that allows you to 
send/receive Radius requests/responses to/from a Radius server.

=head1 CONSTRUCTOR

=over 4

=item new ( Host => HOST, Secret => SECRET [, TimeOut => TIMEOUT] [,Service => SERVICE] [, Debug => Bool])

Creates & returns a blessed reference to a Radius object, or undef on
failure.  Error status may be retrieved with C<Authen::Radius::get_error>
(errorcode) or C<Authen::Radius::strerror> (verbose error string).

The default C<Service> is C<radius>, the alternative is C<radius-acct>.
If you do not specify port in the C<Host> as a C<hostname:port>, then port
specified in your F</etc/services> will be used. If there is nothing
there, and you did not specify port either then default is 1645 for
C<radius> and 1813 for C<radius-acct>.

Optional parameter C<Debug> with a Perl "true" value turns on debugging
(verbose mode).

=back

=head1 METHODS

=over 4

=item load_dictionary ( [ DICTIONARY ] )

Loads the definitions in the specified Radius dictionary file (standard
Livingston radiusd format). Tries to load 'C</etc/raddb/dictionary>' when no
argument is specified, or dies. NOTE: you need to load valid dictionary
if you plan to send Radius requests with other attributes than just
C<User-Name>/C<Password>.

=item check_pwd ( USERNAME, PASSWORD [,NASIPADDRESS] )

Checks with the Radius server if the specified C<PASSWORD> is valid for user
C<USERNAME>. Unless C<NASIPADDRESS> is soecified, 127.0.0.1 will
be placed in the NAS-IP-Address attribute.
This method is actually a wrapper for subsequent calls to
C<clear_attributes>, C<add_attributes>, C<send_packet> and C<recv_packet>. It
returns 1 if the C<PASSWORD> is correct, or undef otherwise.

=item add_attributes ( { Name => NAME, Value => VALUE [, Type => TYPE] [, Vendor => VENDOR] }, ... )

Adds any number of Radius attributes to the current Radius object. Attributes
are specified as a list of anon hashes. They may be C<Name>d with their 
dictionary name (provided a dictionary has been loaded first), or with 
their raw Radius attribute-type values. The C<Type> pair should be specified 
when adding attributes that are not in the dictionary (or when no dictionary 
was loaded). Values for C<TYPE> can be 'C<string>', 'C<integer>', 'C<ipaddr>' or 'C<avpair>'.

=item get_attributes

Returns a list of references to anon hashes with the following key/value
pairs : { Name => NAME, Code => RAWTYPE, Value => VALUE, RawValue =>
RAWVALUE, Vendor => VENDOR }. Each hash represents an attribute in the current object. The 
C<Name> and C<Value> pairs will contain values as translated by the 
dictionary (if one was loaded). The C<Code> and C<RawValue> pairs always 
contain the raw attribute type & value as received from the server.

=item clear_attributes

Clears all attributes for the current object.

=item send_packet ( REQUEST_TYPE )

Packs up a Radius packet based on the current secret & attributes and
sends it to the server with a Request type of C<REQUEST_TYPE>. Exported
C<REQUEST_TYPE> methods are 'C<ACCESS_REQUEST>', 'C<ACCESS_ACCEPT>' ,
'C<ACCESS_REJECT>', 'C<ACCOUNTING_REQUEST>' and 'C<ACCOUNTING_RESPONSE>'.
Returns the number of bytes sent, or undef on failure.

=item recv_packet

Receives a Radius reply packet. Returns the Radius Reply type (see possible
values for C<REQUEST_TYPE> in method C<send_packet>) or undef on failure. Note 
that failure may be due to a failed recv() or a bad Radius response 
authenticator. Use C<get_error> to find out.

=item get_error

Returns the last C<ERRORCODE> for the current object. Errorcodes are one-word
strings always beginning with an 'C<E>'.

=item strerror ( [ ERRORCODE ] )

Returns a verbose error string for the last error for the current object, or
for the specified C<ERRORCODE>.

=back

=head1 AUTHOR

Carl Declerck <carl@miskatonic.inbe.net> - original design
Alexander Kapitanenko <kapitan@portaone.com> and Andrew Zhilenko <andrew@portaone.com> - later modifications.
Andrew Zhilenko <andrew@portaone.com> is a current module's maintaner at CPAN.

=cut

