#!/usr/bin/perl
# A very simple perl web server used by Webmin

# Require basic libraries
package miniserv;
use Socket;
use POSIX;

# Find and read config file
if (@ARGV != 1) {
	die "Usage: miniserv.pl <config file>";
	}
if ($ARGV[0] =~ /^\//) {
	$conf = $ARGV[0];
	}
else {
	chop($pwd = `pwd`);
	$conf = "$pwd/$ARGV[0]";
	}
open(CONF, $conf) || die "Failed to open config file $conf : $!";
while(<CONF>) {
	s/\r|\n//g;
	if (/^#/ || !/\S/) { next; }
	/^([^=]+)=(.*)$/;
	$name = $1; $val = $2;
	$name =~ s/^\s+//g; $name =~ s/\s+$//g;
	$val =~ s/^\s+//g; $val =~ s/\s+$//g;
	$config{$name} = $val;
	}
close(CONF);

# Check is SSL is enabled and available
if ($config{'ssl'}) {
	eval "use Net::SSLeay";
	if (!$@) {
		$use_ssl = 1;
		# These functions only exist for SSLeay 1.0
		eval "Net::SSLeay::SSLeay_add_ssl_algorithms()";
		eval "Net::SSLeay::load_error_strings()";
		if (defined(&Net::SSLeay::X509_STORE_CTX_get_current_cert) &&
		    defined(&Net::SSLeay::CTX_load_verify_locations) &&
		    defined(&Net::SSLeay::CTX_set_verify)) {
			$client_certs = 1;
			}
		}
	}

# Check if the syslog module is available to log hacking attempts
if ($config{'syslog'} && !$config{'inetd'}) {
	eval "use Sys::Syslog qw(:DEFAULT setlogsock)";
	if (!$@) {
		$use_syslog = 1;
		}
	}

# check if the TCP-wrappers module is available
if ($config{'libwrap'}) {
	eval "use Authen::Libwrap qw(hosts_ctl STRING_UNKNOWN)";
	if (!$@) {
		$use_libwrap = 1;
		}
	}

# Get miniserv's perl path and location
$miniserv_path = $0;
open(SOURCE, $miniserv_path);
<SOURCE> =~ /^#!(\S+)/; $perl_path = $1;
close(SOURCE);
@miniserv_argv = @ARGV;

# Check vital config options
%vital = ("port", 80,
	  "root", "./",
	  "server", "MiniServ/0.01",
	  "index_docs", "index.html index.htm index.cgi index.php",
	  "addtype_html", "text/html",
	  "addtype_txt", "text/plain",
	  "addtype_gif", "image/gif",
	  "addtype_jpg", "image/jpeg",
	  "addtype_jpeg", "image/jpeg",
	  "realm", "MiniServ",
	  "session_login", "/session_login.cgi",
	  "password_form", "/password_form.cgi",
	  "password_change", "/password_change.cgi",
	  "maxconns", 50,
	  "pam", "webmin",
	  "sidname", "sid",
	  "unauth", "^/unauthenticated/ ^[A-Za-z0-9\\-/]+\\.jar\$ ^[A-Za-z0-9\\-/]+\\.class\$ ^[A-Za-z0-9\\-/]+\\.gif\$ ^[A-Za-z0-9\\-/]+\\.conf\$",
	  "max_post", 10000
	 );
foreach $v (keys %vital) {
	if (!$config{$v}) {
		if ($vital{$v} eq "") {
			die "Missing config option $v";
			}
		$config{$v} = $vital{$v};
		}
	}
if (!$config{'sessiondb'}) {
	$config{'pidfile'} =~ /^(.*)\/[^\/]+$/;
	$config{'sessiondb'} = "$1/sessiondb";
	}
if (!$config{'errorlog'}) {
	$config{'logfile'} =~ /^(.*)\/[^\/]+$/;
	$config{'errorlog'} = "$1/miniserv.error";
	}
$sidname = $config{'sidname'};
die "Session authentication cannot be used in inetd mode"
	if ($config{'inetd'} && $config{'session'});

# check if the PAM module is available to authenticate
if (!$config{'no_pam'}) {
	eval "use Authen::PAM;";
	if (!$@) {
		# check if the PAM authentication can be used by opening a
		# PAM handle
		local $pamh;
		if (ref($pamh = new Authen::PAM($config{'pam'}, "root",
						  \&pam_conv_func))) {
			# Now test a login to see if /etc/pam.d/XXX is set
			# up properly.
			$pam_conv_func_called = 0;
			$pam_username = "test";
			$pam_password = "test";
			$pamh->pam_authenticate();
			if ($pam_conv_func_called) {
				$pam_msg = "PAM authentication enabled";
				$use_pam = 1;
				}
			else {
				$pam_msg = "PAM test failed - maybe /etc/pam.d/$config{'pam'} does not exist";
				}
			}
		else {
			$pam_msg = "PAM initialization of Authen::PAM failed";
			}
		}
	else {
		$pam_msg = "Perl module Authen::PAM needed for PAM is not installed : $@";
		}
	}
if ($config{'pam_only'} && !$use_pam) {
	$pam_msg2 = "PAM use is mandatory, but could not be enabled!";
	}

# init days and months for http_date
@weekday = ( "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" );
@month = ( "Jan", "Feb", "Mar", "Apr", "May", "Jun",
	   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" );

# Change dir to the server root
chdir($config{'root'});
$user_homedir = (getpwuid($<))[7];

# Read users file
if ($config{'userfile'}) {
	open(USERS, $config{'userfile'});
	while(<USERS>) {
		s/\r|\n//g;
		local @user = split(/:/, $_);
		$users{$user[0]} = $user[1];
		$certs{$user[0]} = $user[3] if ($user[3]);
		if ($user[4] =~ /^allow\s+(.*)/) {
			$allow{$user[0]} = $config{'alwaysresolve'} ?
				[ split(/\s+/, $1) ] :
				[ &to_ipaddress(split(/\s+/, $1)) ];
			}
		elsif ($user[4] =~ /^deny\s+(.*)/) {
			$deny{$user[0]} = $config{'alwaysresolve'} ?
				[ split(/\s+/, $1) ] :
				[ &to_ipaddress(split(/\s+/, $1)) ];
			}
		}
	close(USERS);
	}

# Setup SSL if possible and if requested
if (!-r $config{'keyfile'} ||
    $config{'certfile'} && !-r $config{'certfile'}) {
	# Key file doesn't exist!
	$use_ssl = 0;
	}
if ($use_ssl) {
	$ssl_ctx = Net::SSLeay::CTX_new() ||
		die "Failed to create SSL context : $!";
	$client_certs = 0 if (!-r $config{'ca'} || !%certs);
	if ($client_certs) {
		Net::SSLeay::CTX_load_verify_locations(
			$ssl_ctx, $config{'ca'}, "");
		Net::SSLeay::CTX_set_verify(
			$ssl_ctx, &Net::SSLeay::VERIFY_PEER, \&verify_client);
		}
	if ($config{'extracas'}) {
		foreach $p (split(/\s+/, $config{'extracas'})) {
			Net::SSLeay::CTX_load_verify_locations(
				$ssl_ctx, $p, "");
			}
		}

	Net::SSLeay::CTX_use_RSAPrivateKey_file(
		$ssl_ctx, $config{'keyfile'},
		&Net::SSLeay::FILETYPE_PEM) || die "Failed to open SSL key";
	Net::SSLeay::CTX_use_certificate_file(
		$ssl_ctx, $config{'certfile'} || $config{'keyfile'},
		&Net::SSLeay::FILETYPE_PEM) || die "Failed to open SSL cert";
	}

# Setup syslog support if possible and if requested
if ($use_syslog) {
	eval 'openlog($config{"pam"}, "cons,pid,ndelay", "authpriv"); setlogsock("unix")';
	if ($@) {
		$use_syslog = 0;
		}
	else {
		local $msg = ucfirst($config{'pam'})." starting";
		eval { syslog("info", $msg); };
		if ($@) {
			eval {
				setlogsock("inet");
				syslog("info", $msg);
				};
			if ($@) {
				# All attempts to use syslog have failed..
				$use_syslog = 0;
				}
			}
		}
	}

# Read MIME types file and add extra types
if ($config{"mimetypes"} ne "") {
	open(MIME, $config{"mimetypes"});
	while(<MIME>) {
		chop; s/#.*$//;
		if (/^(\S+)\s+(.*)$/) {
			$type = $1; @exts = split(/\s+/, $2);
			foreach $ext (@exts) {
				$mime{$ext} = $type;
				}
			}
		}
	close(MIME);
	}
foreach $k (keys %config) {
	if ($k !~ /^addtype_(.*)$/) { next; }
	$mime{$1} = $config{$k};
	}
	
# get the time zone
if ($config{'log'}) {
	local(@gmt, @lct, $days, $hours, $mins);
	@make_date_marr = ("Jan", "Feb", "Mar", "Apr", "May", "Jun",
		 	   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
	@gmt = gmtime(time());
	@lct = localtime(time());
	$days = $lct[3] - $gmt[3];
	$hours = ($days < -1 ? 24 : 1 < $days ? -24 : $days * 24) +
		 $lct[2] - $gmt[2];
	$mins = $hours * 60 + $lct[1] - $gmt[1];
	$timezone = ($mins < 0 ? "-" : "+"); $mins = abs($mins);
	$timezone .= sprintf "%2.2d%2.2d", $mins/60, $mins%60;
	}

# build anonymous access list
foreach $a (split(/\s+/, $config{'anonymous'})) {
	if ($a =~ /^([^=]+)=(\S+)$/) {
		$anonymous{$1} = $2;
		}
	}

# build IP access list
foreach $a (split(/\s+/, $config{'ipaccess'})) {
	if ($a =~ /^([^=]+)=(\S+)$/) {
		$ipaccess{$1} = $2;
		}
	}

# build unauthenticated URLs list
@unauth = split(/\s+/, $config{'unauth'});

# build redirect mapping
foreach $r (split(/\s+/, $config{'redirect'})) {
	if ($r =~ /^([^=]+)=(\S+)$/) {
		$redirect{$1} = $2;
		}
	}

# start up external authentication program, if needed
if ($config{'extauth'}) {
	socketpair(EXTAUTH, EXTAUTH2, AF_UNIX, SOCK_STREAM, PF_UNSPEC);
	if (!($extauth = fork())) {
		close(EXTAUTH);
		close(STDIN);
		close(STDOUT);
		open(STDIN, "<&EXTAUTH2");
		open(STDOUT, ">&EXTAUTH2");
		exec($config{'extauth'});
		print STDERR "exec failed : $!\n";
		exit 1;
		}
	close(EXTAUTH2);
	local $os = select(EXTAUTH);
	$| = 1; select($os);
	}

# Re-direct STDERR to a log file
if ($config{'errorlog'} ne '-') {
	open(STDERR, ">>$config{'errorlog'}") || die "failed to open $config{'errorlog'} : $!";
	if ($config{'logperms'}) {
		chmod(oct($config{'logperms'}), $config{'errorlog'});
		}
	}

# Init allow and deny lists
@deny = split(/\s+/, $config{"deny"});
@deny = &to_ipaddress(@deny) if (!$config{'alwaysresolve'});
@allow = split(/\s+/, $config{"allow"});
@allow = &to_ipaddress(@allow) if (!$config{'alwaysresolve'});
if ($config{'allowusers'}) {
	@allowusers = split(/\s+/, $config{'allowusers'});
	}
elsif ($config{'denyusers'}) {
	@denyusers = split(/\s+/, $config{'denyusers'});
	}

if ($config{'inetd'}) {
	# We are being run from inetd - go direct to handling the request
	$SIG{'HUP'} = 'IGNORE';
	$SIG{'TERM'} = 'DEFAULT';
	$SIG{'PIPE'} = 'DEFAULT';
	open(SOCK, "+>&STDIN");

	# Check if it is time for the logfile to be cleared
	if ($config{'logclear'}) {
		local $write_logtime = 0;
		local @st = stat("$config{'logfile'}.time");
		if (@st) {
			if ($st[9]+$config{'logtime'}*60*60 < time()){
				# need to clear log
				$write_logtime = 1;
				unlink($config{'logfile'});
				}
			}
		else { $write_logtime = 1; }
		if ($write_logtime) {
			open(LOGTIME, ">$config{'logfile'}.time");
			print LOGTIME time(),"\n";
			close(LOGTIME);
			}
		}

	# Initialize SSL for this connection
	if ($use_ssl) {
		$ssl_con = Net::SSLeay::new($ssl_ctx);
		Net::SSLeay::set_fd($ssl_con, fileno(SOCK));
		Net::SSLeay::accept($ssl_con) || exit;
		}

	# Work out the hostname for this web server
	$host = &get_socket_name(SOCK);
	$host || exit;
	$port = $config{'port'};
	$acptaddr = getpeername(SOCK);
	$acptaddr || exit;

	while(&handle_request($acptaddr, getsockname(SOCK))) { }
	close(SOCK);
	exit;
	}

# Build list of sockets to listen on
if ($config{"bind"} && $config{"bind"} ne "*") {
	push(@sockets, [ inet_aton($config{'bind'}), $config{'port'} ]);
	}
else {
	push(@sockets, [ INADDR_ANY, $config{'port'} ]);
	}
foreach $s (split(/\s+/, $config{'sockets'})) {
	if ($s =~ /^(\d+)$/) {
		# Just listen on another port on the main IP
		push(@sockets, [ $sockets[0]->[0], $s ]);
		}
	elsif ($s =~ /^(\S+):(\d+)$/) {
		# Listen on a specific port and IP
		push(@sockets, [ $1 eq "*" ? INADDR_ANY : inet_aton($1), $2 ]);
		}
	elsif ($s =~ /^([0-9\.]+):\*$/ || $s =~ /^([0-9\.]+)$/) {
		# Listen on the main port on another IP
		push(@sockets, [ inet_aton($1), $sockets[0]->[1] ]);
		}
	}

# Open all the sockets
$proto = getprotobyname('tcp');
for($i=0; $i<@sockets; $i++) {
	$fh = "MAIN$i";
	socket($fh, PF_INET, SOCK_STREAM, $proto) ||
		die "Failed to open socket : $!";
	setsockopt($fh, SOL_SOCKET, SO_REUSEADDR, pack("l", 1));
	for($j=0; $j<5; $j++) {
		last if (bind($fh, pack_sockaddr_in($sockets[$i]->[1],
						    $sockets[$i]->[0])));
		sleep(1);
		}
	die "Failed to bind to $sockets[$i]->[1] : $!" if ($j == 5);
	listen($fh, SOMAXCONN);
	push(@socketfhs, $fh);
	}

if ($config{'listen'}) {
	# Open the socket that allows other webmin servers to find this one
	$proto = getprotobyname('udp');
	if (socket(LISTEN, PF_INET, SOCK_DGRAM, $proto)) {
		setsockopt(LISTEN, SOL_SOCKET, SO_REUSEADDR, pack("l", 1));
		bind(LISTEN, pack_sockaddr_in($config{'listen'}, INADDR_ANY));
		listen(LISTEN, SOMAXCONN);
		}
	else {
		$config{'listen'} = 0;
		}
	}

# Split from the controlling terminal
if (fork()) { exit; }
setsid();

# Close standard file handles
open(STDIN, "</dev/null");
open(STDOUT, ">/dev/null");
&log_error("miniserv.pl started");
&log_error($pam_msg) if ($pam_msg);
&log_error($pam_msg2) if ($pam_msg2);

# write out the PID file
open(PIDFILE, "> $config{'pidfile'}");
printf PIDFILE "%d\n", getpid();
close(PIDFILE);

# Start the log-clearing process, if needed. This checks every minute
# to see if the log has passed its reset time, and if so clears it
if ($config{'logclear'}) {
	if (!($logclearer = fork())) {
		&close_all_sockets();
		close(LISTEN);
		while(1) {
			local $write_logtime = 0;
			local @st = stat("$config{'logfile'}.time");
			if (@st) {
				if ($st[9]+$config{'logtime'}*60*60 < time()){
					# need to clear log
					$write_logtime = 1;
					unlink($config{'logfile'});
					}
				}
			else { $write_logtime = 1; }
			if ($write_logtime) {
				open(LOGTIME, ">$config{'logfile'}.time");
				print LOGTIME time(),"\n";
				close(LOGTIME);
				}
			sleep(5*60);
			}
		exit;
		}
	push(@childpids, $logclearer);
	}

# Setup the logout time dbm if needed
if ($config{'session'}) {
	eval "use SDBM_File";
	dbmopen(%sessiondb, $config{'sessiondb'}, 0700);
	eval "\$sessiondb{'1111111111'} = 'foo bar';";
	if ($@) {
		dbmclose(%sessiondb);
		eval "use NDBM_File";
		dbmopen(%sessiondb, $config{'sessiondb'}, 0700);
		}
	else {
		delete($sessiondb{'1111111111'});
		}
	}

# Run the main loop
$SIG{'HUP'} = 'miniserv::trigger_restart';
$SIG{'TERM'} = 'miniserv::term_handler';
$SIG{'PIPE'} = 'IGNORE';
while(1) {
	# wait for a new connection, or a message from a child process
	local ($i, $rmask);
	if (@childpids <= $config{'maxconns'}) {
		# Only accept new main socket connects when ready
		local $s;
		foreach $s (@socketfhs) {
			vec($rmask, fileno($s), 1) = 1;
			}
		}
	else {
		printf STDERR "too many children (%d > %d)\n",
			scalar(@childpids), $config{'maxconns'};
		}
	if ($config{'passdelay'} || $config{'session'}) {
		for($i=0; $i<@passin; $i++) {
			vec($rmask, fileno($passin[$i]), 1) = 1;
			}
		}
	vec($rmask, fileno(LISTEN), 1) = 1 if ($config{'listen'});

	local $sel = select($rmask, undef, undef, 10);
	if ($need_restart) { &restart_miniserv(); }
	local $time_now = time();

	# Clean up finished processes
	local $pid;
	do {	$pid = waitpid(-1, WNOHANG);
		@childpids = grep { $_ != $pid } @childpids;
		} while($pid > 0);

	# run the unblocking procedure to check if enough time has passed to
	# unblock hosts that heve been blocked because of password failures
	if ($config{'blockhost_failures'}) {
		$i = 0;
		while ($i <= $#deny) {
			if ($blockhosttime{$deny[$i]} && $config{'blockhost_time'} != 0 &&
			    ($time_now - $blockhosttime{$deny[$i]}) >= $config{'blockhost_time'}) {
				# the host can be unblocked now
				$hostfail{$deny[$i]} = 0;
				splice(@deny, $i, 1);
				}
			$i++;
			}
		}

	if ($config{'session'} && (++$remove_session_count%50) == 0) {
		# Remove sessions with more than 7 days of inactivity,
		local $s;
		foreach $s (keys %sessiondb) {
			local ($user, $ltime) = split(/\s+/, $sessiondb{$s});
			if ($time_now - $ltime > 7*24*60*60) {
				local @sdb = split(/\s+/, $sessiondb{$s});
				&run_logout_script($s, $sdb[0]);
				delete($sessiondb{$s});
				if ($use_syslog) {
					syslog("info", "Timeout of $sdb[0]");
					}
				}
			}
		}
	next if ($sel <= 0);

	# Check if any of the main sockets have received a new connection
	local $sn = 0;
	foreach $s (@socketfhs) {
		if (vec($rmask, fileno($s), 1)) {
			# got new connection
			$acptaddr = accept(SOCK, $s);
			if (!$acptaddr) { next; }
			binmode(SOCK);	# turn off any Perl IO stuff

			# create pipes
			local ($PASSINr, $PASSINw, $PASSOUTr, $PASSOUTw);
			if ($config{'passdelay'} || $config{'session'}) {
				local $p;
				local %taken = map { $_, 1 } @passin;
				for($p=0; $taken{"PASSINr$p"}; $p++) { }
				$PASSINr = "PASSINr$p";
				$PASSINw = "PASSINw$p";
				$PASSOUTr = "PASSOUTr$p";
				$PASSOUTw = "PASSOUTw$p";
				pipe($PASSINr, $PASSINw);
				pipe($PASSOUTr, $PASSOUTw);
				select($PASSINw); $| = 1;
				select($PASSINr); $| = 1;
				select($PASSOUTw); $| = 1;
				select($PASSOUTw); $| = 1;
				}
			select(STDOUT);

			# Check username of connecting user
			local ($peerp, $peera) = unpack_sockaddr_in($acptaddr);
			$localauth_user = undef;
			if ($config{'localauth'} && inet_ntoa($peera) eq "127.0.0.1") {
				if (open(TCP, "/proc/net/tcp")) {
					# Get the info direct from the kernel
					while(<TCP>) {
						s/^\s+//;
						local @t = split(/[\s:]+/, $_);
						if ($t[1] eq '0100007F' &&
						    $t[2] eq sprintf("%4.4X", $peerp)) {
							$localauth_user = getpwuid($t[11]);
							last;
							}
						}
					close(TCP);
					}
				else {
					# Call lsof for the info
					local $lsofpid = open(LSOF,
						"$config{'localauth'} -i TCP\@127.0.0.1:$peerp |");
					while(<LSOF>) {
						if (/^(\S+)\s+(\d+)\s+(\S+)/ &&
						    $2 != $$ && $2 != $lsofpid) {
							$localauth_user = $3;
							}
						}
					close(LSOF);
					}
				}

			# Work out the hostname for this web server
			$host = &get_socket_name(SOCK);
			if (!$host) {
				print STDERR "Failed to get local socket name : $!\n";
				close(SOCK);
				next;
				}
			$port = $sockets[$sn]->[1];

			# fork the subprocess
			local $handpid;
			if (!($handpid = fork())) {
				# setup signal handlers
				$SIG{'TERM'} = 'DEFAULT';
				$SIG{'PIPE'} = 'DEFAULT';
				#$SIG{'CHLD'} = 'IGNORE';
				$SIG{'HUP'} = 'IGNORE';

				# Initialize SSL for this connection
				if ($use_ssl) {
					$ssl_con = Net::SSLeay::new($ssl_ctx);
					Net::SSLeay::set_fd($ssl_con, fileno(SOCK));
					Net::SSLeay::accept($ssl_con) || exit;
					}

				# close useless pipes
				if ($config{'passdelay'} || $config{'session'}) {
					local $p;
					foreach $p (@passin) { close($p); }
					foreach $p (@passout) { close($p); }
					close($PASSINr); close($PASSOUTw);
					}
				&close_all_sockets();
				close(LISTEN);

				while(&handle_request($acptaddr, getsockname(SOCK))) { }
				shutdown(SOCK, 1);
				close(SOCK);
				close($PASSINw); close($PASSOUTw);
				exit;
				}
			push(@childpids, $handpid);
			if ($config{'passdelay'} || $config{'session'}) {
				close($PASSINw); close($PASSOUTr);
				push(@passin, $PASSINr); push(@passout, $PASSOUTw);
				}
			close(SOCK);
			}
		$sn++;
		}

	if ($config{'listen'} && vec($rmask, fileno(LISTEN), 1)) {
		# Got UDP packet from another webmin server
		local $rcvbuf;
		local $from = recv(LISTEN, $rcvbuf, 1024, 0);
		next if (!$from);
		local $fromip = inet_ntoa((unpack_sockaddr_in($from))[1]);
		local $toip = inet_ntoa((unpack_sockaddr_in(
					 getsockname(LISTEN)))[1]);
		if ((!@deny || !&ip_match($fromip, $toip, @deny)) &&
		    (!@allow || &ip_match($fromip, $toip, @allow))) {
			local $listenhost = &get_socket_name(LISTEN);
			send(LISTEN, "$listenhost:$config{'port'}:".
				     ($use_ssl || $config{'inetd_ssl'} ? 1 : 0),
				     0, $from)
				if ($listenhost);
			}
		}

	# check for password-timeout messages from subprocesses
	for($i=0; $i<@passin; $i++) {
		if (vec($rmask, fileno($passin[$i]), 1)) {
			# this sub-process is asking about a password
			local $infd = $passin[$i];
			local $outfd = $passout[$i];
			local $inline = <$infd>;
			if ($inline =~ /^delay\s+(\S+)\s+(\S+)\s+(\d+)/) {
				# Got a delay request from a subprocess.. for
				# valid logins, there is no delay (to prevent
				# denial of service attacks), but for invalid
				# logins the delay increases with each failed
				# attempt.
				if ($3) {
					# login OK.. no delay
					print $outfd "0 0\n";
					$hostfail{$2} = 0;
					}
				else {
					# login failed..
					$hostfail{$2}++;
					# add the host to the block list if necessary
 					if ($config{'blockhost_failures'} &&
					    $hostfail{$2} >= $config{'blockhost_failures'}) {
						push(@deny, $2);					
						$blockhosttime{$2} = $time_now;
						$blocked = 1;
						if ($use_syslog) {
							local $logtext = "Security alert: Host $2 ".
							  "blocked after $config{'blockhost_failures'} ".
							  "failed logins for user $1";
							syslog("crit", $logtext);
							}
						}
					else {
						$blocked = 0;
						}
					$dl = $userdlay{$1} -
					      int(($time_now - $userlast{$1})/50);
					$dl = $dl < 0 ? 0 : $dl+1;
					print $outfd "$dl $blocked\n";
					$userdlay{$1} = $dl;
					}
				$userlast{$1} = $time_now;
				}
			elsif ($inline =~ /^verify\s+(\S+)/) {
				# Verifying a session ID
				local $session_id = $1;
				if (!defined($sessiondb{$session_id})) {
					# Session doesn't exist
					print $outfd "0 0\n";
					}
				else {
					local ($user, $ltime) = split(/\s+/, $sessiondb{$session_id});
					if ($config{'logouttime'} &&
					    $time_now - $ltime > $config{'logouttime'}*60) {
						# Session has timed out
						print $outfd "1 ",$time_now - $ltime,"\n";
						#delete($sessiondb{$session_id});
						}
					else {
						# Session is OK
						print $outfd "2 $user\n";
						if ($config{'logouttime'} &&
						    $time_now - $ltime > ($config{'logouttime'}*60)/2) {
							$sessiondb{$session_id} = "$user $time_now";
							}
						}
					}
				}
			elsif ($inline =~ /^new\s+(\S+)\s+(\S+)/) {
				# Creating a new session
				$sessiondb{$1} = "$2 $time_now";
				}
			elsif ($inline =~ /^delete\s+(\S+)/) {
				# Logging out a session
				local $sid = $1;
				local @sdb = split(/\s+/, $sessiondb{$sid});
				print $outfd $sdb[0],"\n";
				delete($sessiondb{$sid});
				}
			else {
				# close pipe
				close($infd); close($outfd);
				$passin[$i] = $passout[$i] = undef;
				}
			}
		}
	@passin = grep { defined($_) } @passin;
	@passout = grep { defined($_) } @passout;
	}

# handle_request(remoteaddress, localaddress)
# Where the real work is done
sub handle_request
{
$acptip = inet_ntoa((unpack_sockaddr_in($_[0]))[1]);
$localip = $_[1] ? inet_ntoa((unpack_sockaddr_in($_[1]))[1]) : undef;
if ($config{'loghost'}) {
	$acpthost = gethostbyaddr(inet_aton($acptip), AF_INET);
	$acpthost = $acptip if (!$acpthost);
	}
else {
	$acpthost = $acptip;
	}
$datestr = &http_date(time());
$ok_code = 200;
$ok_message = "Document follows";
$logged_code = undef;
$reqline = $request_uri = $page = undef;

# Wait at most 60 secs for start of headers for initial requests, or
# 10 minutes for kept-alive connections
local $rmask;
vec($rmask, fileno(SOCK), 1) = 1;
local $sel = select($rmask, undef, undef, $checked_timeout ? 10*60 : 60);
if (!$sel) {
	if ($checked_timeout) { exit; }
	else { &http_error(400, "Timeout"); }
	}
$checked_timeout++;

# Read the HTTP request and headers
local $origreqline = &read_line();
($reqline = $origreqline) =~ s/\r|\n//g;
$method = $page = $request_uri = undef;
if (!$reqline && (!$use_ssl || $checked_timeout > 1)) {
	# An empty request .. just close the connection
	return 0;
	}
elsif ($reqline =~ /^(SEARCH|PUT)\s+/) {
	&http_error(400, "Bad Request");
	}
elsif ($reqline !~ /^(GET|POST|HEAD)\s+(.*)\s+HTTP\/1\..$/) {
	if ($use_ssl) {
		# This could be an http request when it should be https
		$use_ssl = 0;
		local $url = "https://$host:$port/";
		if ($config{'ssl_redirect'}) {
			# Just re-direct to the correct URL
			&write_data("HTTP/1.0 302 Moved Temporarily\r\n");
			&write_data("Date: $datestr\r\n");
			&write_data("Server: $config{'server'}\r\n");
			&write_data("Location: $url\r\n");
			&write_keep_alive(0);
			&write_data("\r\n");
			return 0;
			}
		else {
			# Tell user the correct URL
			&http_error(200, "Bad Request", "This web server is running in SSL mode. Try the URL <a href='$url'>$url</a> instead.<br>");
			}
		}
	elsif (ord(substr($reqline, 0, 1)) == 128 && !$use_ssl) {
		# This could be an https request when it should be http ..
		# need to fake a HTTP response
		eval <<'EOF';
			use Net::SSLeay;
			eval "Net::SSLeay::SSLeay_add_ssl_algorithms()";
			eval "Net::SSLeay::load_error_strings()";
			$ssl_ctx = Net::SSLeay::CTX_new();
			Net::SSLeay::CTX_use_RSAPrivateKey_file(
				$ssl_ctx, $config{'keyfile'},
				&Net::SSLeay::FILETYPE_PEM);
			Net::SSLeay::CTX_use_certificate_file(
				$ssl_ctx,
				$config{'certfile'} || $config{'keyfile'},
				&Net::SSLeay::FILETYPE_PEM);
			$ssl_con = Net::SSLeay::new($ssl_ctx);
			pipe(SSLr, SSLw);
			if (!fork()) {
				close(SSLr);
				select(SSLw); $| = 1; select(STDOUT);
				print SSLw $origreqline;
				local $buf;
				while(sysread(SOCK, $buf, 1) > 0) {
					print SSLw $buf;
					}
				close(SOCK);
				exit;
				}
			close(SSLw);
			Net::SSLeay::set_wfd($ssl_con, fileno(SOCK));
			Net::SSLeay::set_rfd($ssl_con, fileno(SSLr));
			Net::SSLeay::accept($ssl_con) || die "accept() failed";
			$use_ssl = 1;
			local $url = "http://$host:$port/";
			if ($config{'ssl_redirect'}) {
				# Just re-direct to the correct URL
				&write_data("HTTP/1.0 302 Moved Temporarily\r\n");
				&write_data("Date: $datestr\r\n");
				&write_data("Server: $config{'server'}\r\n");
				&write_data("Location: $url\r\n");
				&write_keep_alive(0);
				&write_data("\r\n");
				return 0;
				}
			else {
				# Tell user the correct URL
				&http_error(200, "Bad Request", "This web server is not running in SSL mode. Try the URL <a href='$url'>$url</a> instead.<br>");
				}
EOF
		if ($@) {
			&http_error(400, "Bad Request");
			}
		}
	else {
		&http_error(400, "Bad Request");
		}
	}
$method = $1;
$request_uri = $page = $2;
%header = ();
local $lastheader;
while(1) {
	($headline = &read_line()) =~ s/\r|\n//g;
	last if ($headline eq "");
	if ($headline =~ /^(\S+):\s*(.*)$/) {
		$header{$lastheader = lc($1)} = $2;
		}
	elsif ($headline =~ /^\s+(.*)$/) {
		$header{$lastheader} .= $headline;
		}
	else {
		&http_error(400, "Bad Header $headline");
		}
	}
if (defined($header{'host'})) {
	if ($header{'host'} =~ /^([^:]+):([0-9]+)$/) { $host = $1; $port = $2; }
	else { $host = $header{'host'}; }
	if ($config{'musthost'} && $host ne $config{'musthost'}) {
		# Disallowed hostname used
		&http_error(400, "Invalid HTTP hostname");
		}
	}
undef(%in);
if ($page =~ /^([^\?]+)\?(.*)$/) {
	# There is some query string information
	$page = $1;
	$querystring = $2;
	if ($querystring !~ /=/) {
		$queryargs = $querystring;
		$queryargs =~ s/\+/ /g;
    		$queryargs =~ s/%(..)/pack("c",hex($1))/ge;
		$querystring = "";
		}
	else {
		# Parse query-string parameters
		local @in = split(/\&/, $querystring);
		foreach $i (@in) {
			local ($k, $v) = split(/=/, $i, 2);
			$k =~ s/\+/ /g; $k =~ s/%(..)/pack("c",hex($1))/ge;
			$v =~ s/\+/ /g; $v =~ s/%(..)/pack("c",hex($1))/ge;
			$in{$k} = $v;
			}
		}
	}
$posted_data = undef;
if ($method eq 'POST' &&
    $header{'content-type'} eq 'application/x-www-form-urlencoded') {
	# Read in posted query string information, up the configured maximum
	# post request length
	$clen = $header{"content-length"};
	$clen_read = $clen > $config{'max_post'} ? $config{'max_post'} : $clen;
	while(length($posted_data) < $clen_read) {
		$buf = &read_data($clen_read - length($posted_data));
		if (!length($buf)) {
			&http_error(500, "Failed to read POST request");
			}
		chomp($posted_data);
		$posted_data =~ s/\015$//mg;
		$posted_data .= $buf;
		}
	if ($clen_read != $clen) {
		# If the client sent more data than we asked for, chop the
		# rest off
		$posted_data = substr($posted_data, 0, $clen)
			if (length($posted_data) > $clen);
		}
	#$posted_data =~ s/\r|\n//g;	# some browsers include an extra newline
	#				# in the data!
	local @in = split(/\&/, $posted_data);
	foreach $i (@in) {
		local ($k, $v) = split(/=/, $i, 2);
		$k =~ s/\+/ /g; $k =~ s/%(..)/pack("c",hex($1))/ge;
		$v =~ s/\+/ /g; $v =~ s/%(..)/pack("c",hex($1))/ge;
		$in{$k} = $v;
		}
	}

# replace %XX sequences in page
$page =~ s/%(..)/pack("c",hex($1))/ge;

# check address against access list
if (@deny && &ip_match($acptip, $localip, @deny) ||
    @allow && !&ip_match($acptip, $localip, @allow)) {
	&http_error(403, "Access denied for $acptip");
	return 0;
	}

if ($use_libwrap) {
	# Check address with TCP-wrappers
	if (!hosts_ctl($config{'pam'}, STRING_UNKNOWN, $acptip, STRING_UNKNOWN)) {
		&http_error(403, "Access denied for $acptip");
		return 0;
		}
	}

# check for the logout flag file, and if existant deny authentication
if ($config{'logout'} && -r $config{'logout'}.$in{'miniserv_logout_id'}) {
	$deny_authentication++;
	open(LOGOUT, $config{'logout'}.$in{'miniserv_logout_id'});
	chop($count = <LOGOUT>);
	close(LOGOUT);
	$count--;
	if ($count > 0) {
		open(LOGOUT, ">$config{'logout'}$in{'miniserv_logout_id'}");
		print LOGOUT "$count\n";
		close(LOGOUT);
		}
	else {
		unlink($config{'logout'}.$in{'miniserv_logout_id'});
		}
	}

# check for any redirect for the requested URL
$simple = &simplify_path($page, $bogus);
$rpath = $simple;
$rpath .= "&".$querystring if (defined($querystring));
$redir = $redirect{$rpath};
if (defined($redir)) {
	&write_data("HTTP/1.0 302 Moved Temporarily\r\n");
	&write_data("Date: $datestr\r\n");
	&write_data("Server: $config{'server'}\r\n");
	local $ssl = $use_ssl || $config{'inetd_ssl'};
	$portstr = $port == 80 && !$ssl ? "" :
		   $port == 443 && $ssl ? "" : ":$port";
	$prot = $ssl ? "https" : "http";
	&write_data("Location: $prot://$host$portstr$redir\r\n");
	&write_keep_alive(0);
	&write_data("\r\n");
	return 0;
	}

# Check for password if needed
if (%users) {
	$validated = 0;
	$blocked = 0;

	# Session authentication is never used for connections by
	# another webmin server
	if ($header{'user-agent'} =~ /webmin/i) {
		$config{'session'} = 0;
		}

	# check for SSL authentication
	if ($use_ssl && $verified_client) {
		$peername = Net::SSLeay::X509_NAME_oneline(
				Net::SSLeay::X509_get_subject_name(
					Net::SSLeay::get_peer_certificate(
						$ssl_con)));
		foreach $u (keys %certs) {
			if ($certs{$u} eq $peername) {
				$authuser = $u;
				$validated = 2;
				#syslog("info", "SSL login as $authuser from $acpthost") if ($use_syslog);
				last;
				}
			}
		if ($use_syslog && !$validated) {
			syslog("crit",
			       "Unknown SSL certificate $peername");
			}
		}

	if (!$validated && !$deny_authentication) {
		# check for IP-based authentication
		local $a;
		foreach $a (keys %ipaccess) {
			if ($acptip eq $a) {
				# It does! Auth as the user
				$validated = 3;
				$baseauthuser = $authuser =
					$ipaccess{$a};
				}
			}
		}

	# Check for normal HTTP authentication
	if (!$validated && !$deny_authentication && !$config{'session'} &&
	    $header{authorization} =~ /^basic\s+(\S+)$/i) {
		# authorization given..
		($authuser, $authpass) = split(/:/, &b64decode($1), 2);
		local ($vu, $expired, $nonexist) =
			&validate_user($authuser, $authpass);
		if ($vu && (!$expired || $config{'passwd_mode'} == 1)) {
			$authuser = $vu;
			$validated = 1;
			}
		else {
			$validated = 0;
			}
		if ($use_syslog && !$validated) {
			syslog("crit",
			       ($nonexist ? "Non-existent" :
				$expired ? "Expired" : "Invalid").
			       " login as $authuser from $acpthost");
			}
		if ($authuser =~ /\r|\n|\s/) {
			&http_error(500, "Invalid username",
				    "Username contains invalid characters");
			}
		if ($authpass =~ /\r|\n/) {
			&http_error(500, "Invalid password",
				    "Password contains invalid characters");
			}

		if ($config{'passdelay'} && !$config{'inetd'}) {
			# check with main process for delay
			print $PASSINw "delay $authuser $acptip $validated\n";
			<$PASSOUTr> =~ /(\d+) (\d+)/;
			$blocked = $2;
			sleep($1);
			}
		}

	# Check for a visit to the special session login page
	if ($config{'session'} && !$deny_authentication &&
	    $page eq $config{'session_login'}) {
		if ($in{'logout'} && $header{'cookie'} =~ /(^|\s)$sidname=([a-f0-9]+)/) {
			# Logout clicked .. remove the session
			local $sid = $2;
			print $PASSINw "delete $sid\n";
			local $louser = <$PASSOUTr>;
			chop($louser);
			$logout = 1;
			$already_session_id = undef;
			$authuser = $baseauthuser = undef;
			if ($louser) {
				if ($use_syslog) {
					syslog("info", "Logout by $louser from $acpthost");
					}
				&run_logout_script($louser, $sid,
						   $acptip, $localip);
				}
			}
		else {
			# Validate the user
			if ($in{'user'} =~ /\r|\n|\s/) {
				&http_error(500, "Invalid username",
				    "Username contains invalid characters");
				}
			if ($in{'pass'} =~ /\r|\n/) {
				&http_error(500, "Invalid password",
				    "Password contains invalid characters");
				}

			local ($vu, $expired, $nonexist) =
				&validate_user($in{'user'}, $in{'pass'});
			local $ok = $vu ? 1 : 0;
			$authuser = $vu if ($vu);
			local $loginuser = $authuser || $in{'user'};

			# check if the test cookie is set
			if ($header{'cookie'} !~ /testing=1/ && $loginuser &&
			    !$config{'no_testing_cookie'}) {
				&http_error(500, "No cookies",
				   "Your browser does not support cookies, ".
				   "which are required for this web server to ".
				   "work in session authentication mode");
				}

			# check with main process for delay
			if ($config{'passdelay'} && $loginuser) {
				print $PASSINw "delay $loginuser $acptip $ok\n";
				<$PASSOUTr> =~ /(\d+) (\d+)/;
				$blocked = $2;
				sleep($1);
				}

			if ($ok && (!$expired ||
				    $config{'passwd_mode'} == 1)) {
				# Logged in OK! Tell the main process about
				# the new SID
				local $sid;
				$SIG{ALRM} = "miniserv::urandom_timeout";
				alarm(5);
				if (open(RANDOM, "/dev/urandom")) {
					my $tmpsid;
					if (read(RANDOM, $tmpsid, 16) == 16) {
						$sid = lc(unpack('h*',$tmpsid));
						}
					close(RANDOM);
					}
				alarm(0);
				if (!$sid) {
					$sid = time();
					local $mul = 1;
					foreach $c (split(//, crypt($in{'pass'}, substr($$, -2)))) {
						$sid += ord($c) * $mul;
						$mul *= 3;
						}
					}

				print $PASSINw "new $sid $authuser\n";

				# Run the post-login script, if any
				&run_login_script($authuser, $sid,
						  $acptip, $localip);

				# Set cookie and redirect
				&write_data("HTTP/1.0 302 Moved Temporarily\r\n");
				&write_data("Date: $datestr\r\n");
				&write_data("Server: $config{'server'}\r\n");
				local $ssl = $use_ssl || $config{'inetd_ssl'};
				$portstr = $port == 80 && !$ssl ? "" :
					   $port == 443 && $ssl ? "" : ":$port";
				$prot = $ssl ? "https" : "http";
				local $sec = $ssl ? "; secure" : "";
				#$sec .= "; httpOnly";
				if ($in{'save'}) {
					&write_data("Set-Cookie: $sidname=$sid; path=/; expires=\"Fri, 1-Jan-2038 00:00:01\"$sec\r\n");
					}
				else {
					&write_data("Set-Cookie: $sidname=$sid; path=/$sec\r\n");
					}
				&write_data("Location: $prot://$host$portstr$in{'page'}\r\n");
				&write_keep_alive(0);
				&write_data("\r\n");
				&log_request($acpthost, $authuser, $reqline, 302, 0);
				syslog("info", "Successful login as $authuser from $acpthost") if ($use_syslog);
				return 0;
				}
			elsif ($ok && $expired &&
			       $config{'passwd_mode'} == 2) {
				# Login was ok, but password has expired. Need
				# to force display of password change form.
				$validated = 1;
				$authuser = undef;
				$querystring = "&user=".&urlize($vu).
					       "&pam=".$use_pam;
				$method = "GET";
				$queryargs = "";
				$page = $config{'password_form'};
				$logged_code = 401;
				$miniserv_internal = 2;
				syslog("crit",
					"Expired login as $in{'user'} ".
					"from $acpthost") if ($use_syslog);
				}
			else {
				# Login failed, or password has expired. Display
				# the form again.
				$failed_user = $in{'user'};
				$request_uri = $in{'page'};
				$already_session_id = undef;
				$method = "GET";
				$authuser = $baseauthuser = undef;
				syslog("crit",
					($nonexist ? "Non-existent" :
					 $expired ? "Expired" : "Invalid").
					" login as $in{'user'} from $acpthost")
					if ($use_syslog);
				}
			}
		}

	# Check for a visit to the special password change page
	if ($config{'session'} && !$deny_authentication &&
	    $page eq $config{'password_change'} && !$validated &&
	    $config{'passwd_mode'} == 2) {
		# Just let this slide ..
		$validated = 1;
		$miniserv_internal = 3;
		}

	# Check for an existing session
	if ($config{'session'} && !$validated) {
		if ($already_session_id) {
			$session_id = $already_session_id;
			$authuser = $already_authuser;
			$validated = 1;
			}
		elsif (!$deny_authentication &&
		       $header{'cookie'} =~ /(^|\s)$sidname=([a-f0-9]+)/) {
			$session_id = $2;
			print $PASSINw "verify $session_id\n";
			<$PASSOUTr> =~ /(\d+)\s+(\S+)/;
			if ($1 == 2) {
				# Valid session continuation
				$validated = 1;
				$authuser = $2;
				#$already_session_id = $session_id;
				$already_authuser = $authuser;
				}
			elsif ($1 == 1) {
				# Session timed out
				$timed_out = $2;
				}
			else {
				# Invalid session ID .. don't set verified
				}
			}
		}

	# Check for local authentication
	if ($localauth_user && !$header{'x-forwarded-for'} && !$header{'via'}) {
		if (defined($users{$localauth_user})) {
			# Local user exists in webmin users file
			$validated = 1;
			$authuser = $localauth_user;
			# syslog("info", "Local login as $authuser from $acpthost") if ($use_syslog);
			}
		elsif ($config{'unixauth'}) {
			# Local user must exist
			$validated = 2;
			$authuser = $localauth_user;
			# syslog("info", "Local login as $authuser from $acpthost") if ($use_syslog);
			}
		else {
			$localauth_user = undef;
			}
		}

	if (!$validated) {
		# Check if this path allows anonymous access
		local $a;
		foreach $a (keys %anonymous) {
			if (substr($simple, 0, length($a)) eq $a) {
				# It does! Auth as the user, if IP access
				# control allows him.
				if (&check_user_ip($anonymous{$a})) {
					$validated = 3;
					$baseauthuser = $authuser =
						$anonymous{$a};
					}
				}
			}
		}

	if (!$validated) {
		# Check if this path allows unauthenticated access
		local ($u, $unauth);
		foreach $u (@unauth) {
			$unauth++ if ($simple =~ /$u/);
			}
		if (!$bogus && $unauth) {
			# Unauthenticated directory or file request - approve it
			$validated = 3;
			$baseauthuser = $authuser = undef;
			}
		}

	if (!$validated) {
		if ($blocked == 0) {
			# No password given.. ask
			if ($config{'session'}) {
				# Force CGI for session login
				$validated = 1;
				if ($logout) {
					$querystring .= "&logout=1&page=/";
					}
				else {
					# Re-direct to current module only
					local $rpage = $request_uri;
					$rpage =~ s/[^\/]+$//
						if (!$config{'loginkeeppage'});
					$querystring = "page=".&urlize($rpage);
					}
				$method = "GET";
				$querystring .= "&failed=$failed_user" if ($failed_user);
				$querystring .= "&timed_out=$timed_out" if ($timed_out);
				$queryargs = "";
				$page = $config{'session_login'};
				$miniserv_internal = 1;
				$logged_code = 401;
				}
			else {
				# Ask for login with HTTP authentication
				&write_data("HTTP/1.0 401 Unauthorized\r\n");
				&write_data("Date: $datestr\r\n");
				&write_data("Server: $config{'server'}\r\n");
				&write_data("WWW-authenticate: Basic ".
					   "realm=\"$config{'realm'}\"\r\n");
				&write_keep_alive(0);
				&write_data("Content-type: text/html\r\n");
				&write_data("\r\n");
				&reset_byte_count();
				&write_data("<html>\n");
				&write_data("<head><title>Unauthorized</title></head>\n");
				&write_data("<body><h1>Unauthorized</h1>\n");
				&write_data("A password is required to access this\n");
				&write_data("web server. Please try again. <p>\n");
				&write_data("</body></html>\n");
				&log_request($acpthost, undef, $reqline, 401, &byte_count());
				return 0;
				}
			}
		else {
			# when the host has been blocked, give it an error message
			&http_error(403, "Access denied for $acptip. The host has been blocked "
				."because of too many authentication failures.");
			}
		}
	else {
		# If we are using unixauth, keep the 'real' username
		if ($config{'unixauth'} && !$users{$authuser}) {
			$baseauthuser = $config{'unixauth'};
			}
		else {
			$baseauthuser = $authuser;
			}

		if ($config{'remoteuser'} && !$< && $validated) {
			# Switch to the UID of the remote user (if he exists)
			local @u = getpwnam($authuser);
			if (@u && $< != $u[2]) {
				$( = $u[3]; $) = "$u[3] $u[3]";
				($>, $<) = ($u[2], $u[2]);
				}
			else {
				&http_error(500, "Unix user $authuser does not exist");
				return 0;
				}
			}
		}

	# Check per-user IP access control
	if (!&check_user_ip($baseauthuser)) {
		&http_error(403, "Access denied for $acptip");
		return 0;
		}
	}

# Figure out what kind of page was requested
rerun:
$simple = &simplify_path($page, $bogus);
$simple =~ s/[\000-\037]//g;
if ($bogus) {
	&http_error(400, "Invalid path");
	}
local ($full, @stfull);
local $preroot = $authuser && defined($config{'preroot_'.$authuser}) ?
			$config{'preroot_'.$authuser} :
		 $authuser && $baseauthuser && defined($config{'preroot_'.$baseauthuser}) ?
		 	$config{'preroot_'.$baseauthuser} :
			$config{'preroot'};
if ($preroot) {
	# Always under the current webmin root
	$preroot =~ s/^.*\///g;
	$preroot = $config{'root'}.'/'.$preroot;
	}
if ($preroot) {
	# Look in the template root directory first
	$is_directory = 1;
	$sofar = "";
	$full = $preroot.$sofar;
	$scriptname = $simple;
	foreach $b (split(/\//, $simple)) {
		if ($b ne "") { $sofar .= "/$b"; }
		$full = $preroot.$sofar;
		@stfull = stat($full);
		if (!@stfull) { undef($full); last; }

		# Check if this is a directory
		if (-d _) {
			# It is.. go on parsing
			$is_directory = 1;
			next;
			}
		else { $is_directory = 0; }

		# Check if this is a CGI program
		if (&get_type($full) eq "internal/cgi") {
			$pathinfo = substr($simple, length($sofar));
			$pathinfo .= "/" if ($page =~ /\/$/);
			$scriptname = $sofar;
			last;
			}
		}
	if ($full) {
		if ($sofar eq '') {
			$cgi_pwd = $config{'root'};
			}
		elsif ($is_directory) {
			$cgi_pwd = "$config{'root'}$sofar";
			}
		else {
			"$config{'root'}$sofar" =~ /^(.*\/)[^\/]+$/;
			$cgi_pwd = $1;
			}
		if ($is_directory) {
			# Check for index files in the directory
			local $foundidx;
			foreach $idx (split(/\s+/, $config{"index_docs"})) {
				$idxfull = "$full/$idx";
				local @stidxfull = stat($idxfull);
				if (-r _ && !-d _) {
					$full = $idxfull;
					@stfull = @stidxfull;
					$is_directory = 0;
					$scriptname .= "/"
						if ($scriptname ne "/");
					$foundidx++;
					last;
					}
				}
			@stfull = stat($full) if (!$foundidx);
			}
		}
	}
if (!$full || $is_directory) {
	$sofar = "";
	$full = $config{"root"} . $sofar;
	$scriptname = $simple;
	foreach $b (split(/\//, $simple)) {
		if ($b ne "") { $sofar .= "/$b"; }
		$full = $config{"root"} . $sofar;
		@stfull = stat($full);
		if (!@stfull) { &http_error(404, "File not found"); }

		# Check if this is a directory
		if (-d _) {
			# It is.. go on parsing
			next;
			}

		# Check if this is a CGI program
		if (&get_type($full) eq "internal/cgi") {
			$pathinfo = substr($simple, length($sofar));
			$pathinfo .= "/" if ($page =~ /\/$/);
			$scriptname = $sofar;
			last;
			}
		}
	$full =~ /^(.*\/)[^\/]+$/; $cgi_pwd = $1;
	}
@stfull = stat($full) if (!@stfull);

# check filename against denyfile regexp
local $denyfile = $config{'denyfile'};
if ($denyfile && $full =~ /$denyfile/) {
	&http_error(403, "Access denied to $page");
	return 0;
	}

# Reached the end of the path OK.. see what we've got
if (-d _) {
	# See if the URL ends with a / as it should
	if ($page !~ /\/$/) {
		# It doesn't.. redirect
		&write_data("HTTP/1.0 302 Moved Temporarily\r\n");
		$ssl = $use_ssl || $config{'inetd_ssl'};
		$portstr = $port == 80 && !$ssl ? "" :
			   $port == 443 && $ssl ? "" : ":$port";
		&write_data("Date: $datestr\r\n");
		&write_data("Server: $config{server}\r\n");
		$prot = $ssl ? "https" : "http";
		&write_data("Location: $prot://$host$portstr$page/\r\n");
		&write_keep_alive(0);
		&write_data("\r\n");
		&log_request($acpthost, $authuser, $reqline, 302, 0);
		return 0;
		}
	# A directory.. check for index files
	local $foundidx;
	foreach $idx (split(/\s+/, $config{"index_docs"})) {
		$idxfull = "$full/$idx";
		@stidxfull = stat($idxfull);
		if (-r _ && !-d _) {
			$cgi_pwd = $full;
			$full = $idxfull;
			@stfull = @stidxfull;
			$scriptname .= "/" if ($scriptname ne "/");
			$foundidx++;
			last;
			}
		}
	@stfull = stat($full) if (!$foundidx);
	}
if (-d _) {
	# This is definately a directory.. list it
	&write_data("HTTP/1.0 $ok_code $ok_message\r\n");
	&write_data("Date: $datestr\r\n");
	&write_data("Server: $config{server}\r\n");
	&write_data("Content-type: text/html\r\n");
	&write_keep_alive(0);
	&write_data("\r\n");
	&reset_byte_count();
	&write_data("<h1>Index of $simple</h1>\n");
	&write_data("<pre>\n");
	&write_data(sprintf "%-35.35s %-20.20s %-10.10s\n",
			"Name", "Last Modified", "Size");
	&write_data("<hr>\n");
	opendir(DIR, $full);
	while($df = readdir(DIR)) {
		if ($df =~ /^\./) { next; }
		(@stbuf = stat("$full/$df")) || next;
		if (-d _) { $df .= "/"; }
		@tm = localtime($stbuf[9]);
		$fdate = sprintf "%2.2d/%2.2d/%4.4d %2.2d:%2.2d:%2.2d",
				$tm[3],$tm[4]+1,$tm[5]+1900,
				$tm[0],$tm[1],$tm[2];
		$len = length($df); $rest = " "x(35-$len);
		&write_data(sprintf 
		 "<a href=\"%s\">%-${len}.${len}s</a>$rest %-20.20s %-10.10s\n",
		 $df, $df, $fdate, $stbuf[7]);
		}
	closedir(DIR);
	&log_request($acpthost, $authuser, $reqline, $ok_code, &byte_count());
	return 0;
	}

# CGI or normal file
local $rv;
if (&get_type($full) eq "internal/cgi") {
	# A CGI program to execute
	$envtz = $ENV{"TZ"};
	$envuser = $ENV{"USER"};
	$envpath = $ENV{"PATH"};
	$envlang = $ENV{"LANG"};
	foreach (keys %ENV) { delete($ENV{$_}); }
	$ENV{"PATH"} = $envpath if ($envpath);
	$ENV{"TZ"} = $envtz if ($envtz);
	$ENV{"USER"} = $envuser if ($envuser);
	$ENV{"OLD_LANG"} = $envlang if ($envlang);
	$ENV{"HOME"} = $user_homedir;
	$ENV{"SERVER_SOFTWARE"} = $config{"server"};
	$ENV{"SERVER_NAME"} = $host;
	$ENV{"SERVER_ADMIN"} = $config{"email"};
	$ENV{"SERVER_ROOT"} = $config{"root"};
	$ENV{"SERVER_PORT"} = $port;
	$ENV{"REMOTE_HOST"} = $acpthost;
	$ENV{"REMOTE_ADDR"} = $acptip;
	$ENV{"REMOTE_USER"} = $authuser if (defined($authuser));
	$ENV{"BASE_REMOTE_USER"} =$baseauthuser if ($authuser ne $baseauthuser);
	$ENV{"REMOTE_PASS"} = $authpass if (defined($authpass) &&
					    $config{'pass_password'});
	$ENV{"SSL_USER"} = $peername if ($validated == 2);
	$ENV{"ANONYMOUS_USER"} = "1" if ($validated == 3);
	$ENV{"DOCUMENT_ROOT"} = $config{"root"};
	$ENV{"GATEWAY_INTERFACE"} = "CGI/1.1";
	$ENV{"SERVER_PROTOCOL"} = "HTTP/1.0";
	$ENV{"REQUEST_METHOD"} = $method;
	$ENV{"SCRIPT_NAME"} = $scriptname;
	$ENV{"SCRIPT_FILENAME"} = $full;
	$ENV{"REQUEST_URI"} = $request_uri;
	$ENV{"PATH_INFO"} = $pathinfo;
	$ENV{"PATH_TRANSLATED"} = "$config{root}/$pathinfo";
	$ENV{"QUERY_STRING"} = $querystring;
	$ENV{"MINISERV_CONFIG"} = $conf;
	$ENV{"HTTPS"} = "ON" if ($use_ssl || $config{'inetd_ssl'});
	$ENV{"SESSION_ID"} = $session_id if ($session_id);
	$ENV{"LOCAL_USER"} = $localauth_user if ($localauth_user);
	$ENV{"MINISERV_INTERNAL"} = $miniserv_internal if ($miniserv_internal);
	if (defined($header{"content-length"})) {
		$ENV{"CONTENT_LENGTH"} = $header{"content-length"};
		}
	if (defined($header{"content-type"})) {
		$ENV{"CONTENT_TYPE"} = $header{"content-type"};
		}
	foreach $h (keys %header) {
		($hname = $h) =~ tr/a-z/A-Z/;
		$hname =~ s/\-/_/g;
		$ENV{"HTTP_$hname"} = $header{$h};
		}
	$ENV{"PWD"} = $cgi_pwd;
	foreach $k (keys %config) {
		if ($k =~ /^env_(\S+)$/) {
			$ENV{$1} = $config{$k};
			}
		}
	delete($ENV{'HTTP_AUTHORIZATION'});
	$ENV{'HTTP_COOKIE'} =~ s/;?\s*$sidname=([a-f0-9]+)//;

	# Check if the CGI can be handled internally
	open(CGI, $full);
	local $first = <CGI>;
	close(CGI);
	$first =~ s/[#!\r\n]//g;
	$nph_script = ($full =~ /\/nph-([^\/]+)$/);
	seek(STDERR, 0, 2);
	if (!$config{'forkcgis'} && $first eq $perl_path && $] >= 5.004) {
		# setup environment for eval
		chdir($ENV{"PWD"});
		@ARGV = split(/\s+/, $queryargs);
		$0 = $full;
		if ($posted_data) {
			# Already read the post input
			$postinput = $posted_data;
			}
		$clen = $header{"content-length"};
		if ($method eq "POST" && $clen_read < $clen) {
			# Still some more POST data to read
			while(length($postinput) < $clen) {
				$buf = &read_data($clen - length($postinput));
				if (!length($buf)) {
					&http_error(500, "Failed to read ".
							 "POST request");
					}
				$postinput .= $buf;
				}
			}
		$SIG{'CHLD'} = 'DEFAULT';
		eval {
			# Have SOCK closed if the perl exec's something
			use Fcntl;
			fcntl(SOCK, F_SETFD, FD_CLOEXEC);
			};
		shutdown(SOCK, 0);

		if ($config{'log'}) {
			open(MINISERVLOG, ">>$config{'logfile'}");
			if ($config{'logperms'}) {
				chmod(oct($config{'logperms'}),
				      $config{'logfile'});
				}
			else {
				chmod(0600, $config{'logfile'});
				}
			}
		$doing_eval = 1;
		$main_process_id = $$;
		eval {
			package main;
			tie(*STDOUT, 'miniserv');
			tie(*STDIN, 'miniserv');
			do $miniserv::full;
			die $@ if ($@);
			};
		$doing_eval = 0;
		if ($@) {
			# Error in perl!
			&http_error(500, "Perl execution failed", $@);
			}
		elsif (!$doneheaders && !$nph_script) {
			&http_error(500, "Missing Headers");
			}
		#close(SOCK);
		$rv = 0;
		}
	else {
		# fork the process that actually executes the CGI
		pipe(CGIINr, CGIINw);
		pipe(CGIOUTr, CGIOUTw);
		pipe(CGIERRr, CGIERRw);
		if (!($cgipid = fork())) {
			chdir($ENV{"PWD"});
			close(SOCK);
			open(STDIN, "<&CGIINr");
			open(STDOUT, ">&CGIOUTw");
			open(STDERR, ">&CGIERRw");
			close(CGIINw); close(CGIOUTr); close(CGIERRr);
			exec($full, split(/\s+/, $queryargs));
			print STDERR "Failed to exec $full : $!\n";
			exit;
			}
		close(CGIINr); close(CGIOUTw); close(CGIERRw);

		# send post data
		if ($posted_data) {
			# already read the posted data
			print CGIINw $posted_data;
			}
		$clen = $header{"content-length"};
		if ($method eq "POST" && $clen_read < $clen) {
			$got = $clen_read;
			while($got < $clen) {
				$buf = &read_data($clen-$got);
				if (!length($buf)) {
					kill('TERM', $cgipid);
					&http_error(500, "Failed to read ".
							 "POST request");
					}
				$got += length($buf);
				print CGIINw $buf;
				}
			}
		close(CGIINw);
		shutdown(SOCK, 0);

		if (!$nph_script) {
			# read back cgi headers
			select(CGIOUTr); $|=1; select(STDOUT);
			$got_blank = 0;
			while(1) {
				$line = <CGIOUTr>;
				$line =~ s/\r|\n//g;
				if ($line eq "") {
					if ($got_blank || %cgiheader) { last; }
					$got_blank++;
					next;
					}
				($line =~ /^(\S+):\s+(.*)$/) ||
					&http_error(500, "Bad Header",
						    &read_errors(CGIERRr));
				$cgiheader{lc($1)} = $2;
				push(@cgiheader, [ $1, $2 ]);
				}
			if ($cgiheader{"location"}) {
				&write_data("HTTP/1.0 302 Moved Temporarily\r\n");
				&write_data("Date: $datestr\r\n");
				&write_data("Server: $config{'server'}\r\n");
				&write_keep_alive(0);
				# ignore the rest of the output. This is a hack, but
				# is necessary for IE in some cases :(
				close(CGIOUTr); close(CGIERRr);
				}
			elsif ($cgiheader{"content-type"} eq "") {
				&http_error(500, "Missing Content-Type Header",
					    &read_errors(CGIERRr));
				}
			else {
				&write_data("HTTP/1.0 $ok_code $ok_message\r\n");
				&write_data("Date: $datestr\r\n");
				&write_data("Server: $config{'server'}\r\n");
				&write_keep_alive(0);
				}
			foreach $h (@cgiheader) {
				&write_data("$h->[0]: $h->[1]\r\n");
				}
			&write_data("\r\n");
			}
		&reset_byte_count();
		while($line = <CGIOUTr>) {
			&write_data($line);
			}
		close(CGIOUTr); close(CGIERRr);
		$rv = 0;
		}
	}
else {
	# A file to output
	open(FILE, $full) || &http_error(404, "Failed to open file");
	&write_data("HTTP/1.0 $ok_code $ok_message\r\n");
	&write_data("Date: $datestr\r\n");
	&write_data("Server: $config{server}\r\n");
	&write_data("Content-type: ".&get_type($full)."\r\n");
	&write_data("Content-length: $stfull[7]\r\n");
	&write_data("Last-Modified: ".&http_date($stfull[9])."\r\n");
	$rv = &write_keep_alive();
	&write_data("\r\n");
	&reset_byte_count();
	while(read(FILE, $buf, 1024) > 0) {
		&write_data($buf);
		}
	close(FILE);
	}

# log the request
&log_request($acpthost, $authuser, $reqline,
	     $logged_code ? $logged_code :
	     $cgiheader{"location"} ? "302" : $ok_code, &byte_count());
return $rv;
}

# http_error(code, message, body, [dontexit])
sub http_error
{
local $eh = $error_handler_recurse ? undef :
	    $config{"error_handler_$_[0]"} ? $config{"error_handler_$_[0]"} :
	    $config{'error_handler'} ? $config{'error_handler'} : undef;
if ($eh) {
	# Call a CGI program for the error
	$page = "/$eh";
	$querystring = "code=$_[0]&message=".&urlize($_[1]).
		       "&body=".&urlize($_[2]);
	$error_handler_recurse++;
	$ok_code = $_[0];
	$ok_message = $_[1];
	goto rerun;
	}
else {
	# Use the standard error message display
	&write_data("HTTP/1.0 $_[0] $_[1]\r\n");
	&write_data("Server: $config{server}\r\n");
	&write_data("Date: $datestr\r\n");
	&write_data("Content-type: text/html\r\n");
	&write_keep_alive(0);
	&write_data("\r\n");
	&reset_byte_count();
	&write_data("<h1>Error - $_[1]</h1>\n");
	if ($_[2]) {
		&write_data("<pre>$_[2]</pre>\n");
		}
	}
&log_request($acpthost, $authuser, $reqline, $_[0], &byte_count())
	if ($reqline);
&log_error($_[1], $_[2] ? " : $_[2]" : "");
shutdown(SOCK, 1);
exit if (!$_[3]);
}

sub get_type
{
if ($_[0] =~ /\.([A-z0-9]+)$/) {
	$t = $mime{$1};
	if ($t ne "") {
		return $t;
		}
	}
return "text/plain";
}

# simplify_path(path, bogus)
# Given a path, maybe containing stuff like ".." and "." convert it to a
# clean, absolute form.
sub simplify_path
{
local($dir, @bits, @fixedbits, $b);
$dir = $_[0];
$dir =~ s/^\/+//g;
$dir =~ s/\/+$//g;
@bits = split(/\/+/, $dir);
@fixedbits = ();
$_[1] = 0;
foreach $b (@bits) {
        if ($b eq ".") {
                # Do nothing..
                }
        elsif ($b eq "..") {
                # Remove last dir
                if (scalar(@fixedbits) == 0) {
                        $_[1] = 1;
                        return "/";
                        }
                pop(@fixedbits);
                }
        else {
                # Add dir to list
                push(@fixedbits, $b);
                }
        }
return "/" . join('/', @fixedbits);
}

# b64decode(string)
# Converts a string from base64 format to normal
sub b64decode
{
    local($str) = $_[0];
    local($res);
    $str =~ tr|A-Za-z0-9+=/||cd;
    $str =~ s/=+$//;
    $str =~ tr|A-Za-z0-9+/| -_|;
    while ($str =~ /(.{1,60})/gs) {
        my $len = chr(32 + length($1)*3/4);
        $res .= unpack("u", $len . $1 );
    }
    return $res;
}

# ip_match(remoteip, localip, [match]+)
# Checks an IP address against a list of IPs, networks and networks/masks
sub ip_match
{
local(@io, @mo, @ms, $i, $j, $hn, $needhn);
@io = split(/\./, $_[0]);
for($i=2; $i<@_; $i++) {
	$needhn++ if ($_[$i] =~ /^\*(\S+)$/);
	}
if ($needhn && !defined($hn = $ip_match_cache{$_[0]})) {
	$hn = gethostbyaddr(inet_aton($_[0]), AF_INET);
	$hn = "" if (&to_ipaddress($hn) ne $_[0]);
	$ip_match_cache{$_[0]} = $hn;
	}
for($i=2; $i<@_; $i++) {
	local $mismatch = 0;
	if ($_[$i] =~ /^(\S+)\/(\S+)$/) {
		# Compare with network/mask
		@mo = split(/\./, $1); @ms = split(/\./, $2);
		for($j=0; $j<4; $j++) {
			if ((int($io[$j]) & int($ms[$j])) != int($mo[$j])) {
				$mismatch = 1;
				}
			}
		}
	elsif ($_[$i] =~ /^\*(\S+)$/) {
		# Compare with hostname regexp
		$mismatch = 1 if ($hn !~ /$1$/);
		}
	elsif ($_[$i] eq 'LOCAL') {
		# Compare with local network
		local @lo = split(/\./, $_[1]);
		if ($lo[0] < 128) {
			$mismatch = 1 if ($lo[0] != $io[0]);
			}
		elsif ($lo[0] < 192) {
			$mismatch = 1 if ($lo[0] != $io[0] ||
					  $lo[1] != $io[1]);
			}
		else {
			$mismatch = 1 if ($lo[0] != $io[0] ||
					  $lo[1] != $io[1] ||
					  $lo[2] != $io[2]);
			}
		}
	elsif ($_[$i] !~ /^[0-9\.]+$/) {
		# Compare with hostname
		$mismatch = 1 if ($_[0] ne &to_ipaddress($_[$i]));
		}
	else {
		# Compare with IP or network
		@mo = split(/\./, $_[$i]);
		while(@mo && !$mo[$#mo]) { pop(@mo); }
		for($j=0; $j<@mo; $j++) {
			if ($mo[$j] != $io[$j]) {
				$mismatch = 1;
				}
			}
		}
	return 1 if (!$mismatch);
	}
return 0;
}

# users_match(&uinfo, user, ...)
# Returns 1 if a user is in a list of users and groups
sub users_match
{
local $uinfo = shift(@_);
local $u;
local @ginfo = getgrgid($uinfo->[3]);
foreach $u (@_) {
	if ($u =~ /^\@(\S+)$/) {
		local @ginfo = getgrnam($1);
		return 1 if ($ginfo[2] == $uinfo->[3]);
		local $m;
		foreach $m (split(/\s+/, $ginfo[3])) {
			return 1 if ($m eq $uinfo->[0]);
			}
		}
	elsif ($u =~ /^(\d*)-(\d*)$/ && ($1 || $2)) {
		return (!$1 || $uinfo[2] >= $1) &&
		       (!$2 || $uinfo[2] <= $2);
		}
	else {
		return 1 if ($u eq $uinfo->[0]);
		}
	}
return 0;
}

# restart_miniserv()
# Called when a SIGHUP is received to restart the web server. This is done
# by exec()ing perl with the same command line as was originally used
sub restart_miniserv
{
close(SOCK);
&close_all_sockets();
foreach $p (@passin) { close($p); }
foreach $p (@passout) { close($p); }
kill('KILL', $logclearer) if ($logclearer);
kill('KILL', $extauth) if ($extauth);
exec($perl_path, $miniserv_path, @miniserv_argv);
die "Failed to restart miniserv with $perl_path $miniserv_path";
}

sub trigger_restart
{
$need_restart = 1;
}

sub to_ipaddress
{
local (@rv, $i);
foreach $i (@_) {
	if ($i =~ /(\S+)\/(\S+)/ || $i =~ /^\*\S+$/ ||
	    $i eq 'LOCAL' || $i =~ /^[0-9\.]+$/) { push(@rv, $i); }
	else { push(@rv, join('.', unpack("CCCC", inet_aton($i)))); }
	}
return wantarray ? @rv : $rv[0];
}

# read_line()
# Reads one line from SOCK or SSL
sub read_line
{
local($idx, $more, $rv);
if (!$use_ssl) {
	# Read a character at a time
        while(1) {
                local $buf;
                local $ok = read(SOCK, $buf, 1);
                if ($ok <= 0) {
                        return $rv;
                        }
                $rv .= $buf;
                if ($buf eq "\n") {
                        return $rv;
                        }
                }
	}
while(($idx = index($read_buffer, "\n")) < 0) {
	if (length($read_buffer) > 10000) {
		&http_error(414, "Request too long",
			    "Received excessive line <pre>$read_buffer</pre>");
		}

	# need to read more..
	$more = Net::SSLeay::read($ssl_con);
	if ($more eq '') {
		# end of the data
		$rv = $read_buffer;
		undef($read_buffer);
		return $rv;
		}
	$read_buffer .= $more;
	}
$rv = substr($read_buffer, 0, $idx+1);
$read_buffer = substr($read_buffer, $idx+1);
return $rv;
}

# read_data(length)
# Reads up to some amount of data from SOCK or the SSL connection
sub read_data
{
local ($rv);
if (length($read_buffer)) {
	$rv = $read_buffer;
	undef($read_buffer);
	return $rv;
	}
elsif ($use_ssl) {
	return Net::SSLeay::read($ssl_con, $_[0]);
	}
else {
	local $buf;
	read(SOCK, $buf, $_[0]) || return undef;
	return $buf;
	}
}

# write_data(data)
# Writes a string to SOCK or the SSL connection
sub write_data
{
if ($use_ssl) {
	Net::SSLeay::write($ssl_con, $_[0]);
	}
else {
	syswrite(SOCK, $_[0], length($_[0]));
	}
$write_data_count += length($_[0]);
}

# reset_byte_count()
sub reset_byte_count { $write_data_count = 0; }

# byte_count()
sub byte_count { return $write_data_count; }

# log_request(hostname, user, request, code, bytes)
sub log_request
{
if ($config{'log'}) {
	local ($user, $ident, $headers);
	if ($config{'logident'}) {
		# add support for rfc1413 identity checking here
		}
	else { $ident = "-"; }
	$user = $_[1] ? $_[1] : "-";
	local $dstr = &make_datestr();
	if (fileno(MINISERVLOG)) {
		seek(MINISERVLOG, 0, 2);
		}
	else {
		open(MINISERVLOG, ">>$config{'logfile'}");
		chmod(0600, $config{'logfile'});
		}
	if (defined($config{'logheaders'})) {
		foreach $h (split(/\s+/, $config{'logheaders'})) {
			$headers .= " $h=\"$header{$h}\"";
			}
		}
	elsif ($config{'logclf'}) {
		$headers = " \"$header{'referer'}\" \"$header{'user-agent'}\"";
		}
	else {
		$headers = "";
		}
	print MINISERVLOG "$_[0] $ident $user [$dstr] \"$_[2]\" ",
			  "$_[3] $_[4]$headers\n";
	close(MINISERVLOG);
	}
}

# make_datestr()
sub make_datestr
{
local @tm = localtime(time());
return sprintf "%2.2d/%s/%4.4d:%2.2d:%2.2d:%2.2d %s",
		$tm[3], $make_date_marr[$tm[4]], $tm[5]+1900,
	        $tm[2], $tm[1], $tm[0], $timezone;
}

# log_error(message)
sub log_error
{
seek(STDERR, 0, 2);
print STDERR "[",&make_datestr(),"] ",
	$acpthost ? ( "[",$acpthost,"] " ) : ( ),
	$page ? ( $page," : " ) : ( ),
	@_,"\n";
}

# read_errors(handle)
# Read and return all input from some filehandle
sub read_errors
{
local($fh, $_, $rv);
$fh = $_[0];
while(<$fh>) { $rv .= $_; }
return $rv;
}

sub write_keep_alive
{
local $mode;
if ($config{'nokeepalive'}) {
	# Keep alives have been disabled in config
	$mode = 0;
	}
elsif (@childpids > $config{'maxconns'}*.8) {
	# Disable because nearing process limit
	$mode = 0;
	}
elsif (@_) {
	# Keep alive specified by caller
	$mode = $_[0];
	}
else {
	# Keep alive determined by browser
	$mode = $header{'connection'} =~ /keep-alive/i;
	}
&write_data("Connection: ".($mode ? "Keep-Alive" : "close")."\r\n");
return $mode;
}

sub term_handler
{
kill('TERM', @childpids) if (@childpids);
kill('KILL', $logclearer) if ($logclearer);
kill('KILL', $extauth) if ($extauth);
exit(1);
}

sub http_date
{
local @tm = gmtime($_[0]);
return sprintf "%s, %d %s %d %2.2d:%2.2d:%2.2d GMT",
		$weekday[$tm[6]], $tm[3], $month[$tm[4]], $tm[5]+1900,
		$tm[2], $tm[1], $tm[0];
}

sub TIEHANDLE
{
my $i; bless \$i, shift;
}
 
sub WRITE
{
$r = shift;
my($buf,$len,$offset) = @_;
&write_to_sock(substr($buf, $offset, $len));
}
 
sub PRINT
{
$r = shift;
$$r++;
&write_to_sock(@_);
}
 
sub PRINTF
{
shift;
my $fmt = shift;
&write_to_sock(sprintf $fmt, @_);
}
 
sub READ
{
$r = shift;
substr($_[0], $_[2], $_[1]) = substr($postinput, $postpos, $_[1]);
$postpos += $_[1];
}

sub OPEN
{
#print STDERR "open() called - should never happen!\n";
}
 
sub READLINE
{
if ($postpos >= length($postinput)) {
	return undef;
	}
local $idx = index($postinput, "\n", $postpos);
if ($idx < 0) {
	local $rv = substr($postinput, $postpos);
	$postpos = length($postinput);
	return $rv;
	}
else {
	local $rv = substr($postinput, $postpos, $idx-$postpos+1);
	$postpos = $idx+1;
	return $rv;
	}
}
 
sub GETC
{
return $postpos >= length($postinput) ? undef
				      : substr($postinput, $postpos++, 1);
}

sub FILENO
{
return fileno(SOCK);
}
 
sub CLOSE { }
 
sub DESTROY { }

# write_to_sock(data, ...)
sub write_to_sock
{
local $d;
foreach $d (@_) {
	if ($doneheaders || $miniserv::nph_script) {
		&write_data($d);
		}
	else {
		$headers .= $d;
		while(!$doneheaders && $headers =~ s/^([^\r\n]*)(\r)?\n//) {
			if ($1 =~ /^(\S+):\s+(.*)$/) {
				$cgiheader{lc($1)} = $2;
				push(@cgiheader, [ $1, $2 ]);
				}
			elsif ($1 !~ /\S/) {
				$doneheaders++;
				}
			else {
				&http_error(500, "Bad Header");
				}
			}
		if ($doneheaders) {
			if ($cgiheader{"location"}) {
				&write_data(
					"HTTP/1.0 302 Moved Temporarily\r\n");
				&write_data("Date: $datestr\r\n");
				&write_data("Server: $config{server}\r\n");
				&write_keep_alive(0);
				}
			elsif ($cgiheader{"content-type"} eq "") {
				&http_error(500, "Missing Content-Type Header");
				}
			else {
				&write_data("HTTP/1.0 $ok_code $ok_message\r\n");
				&write_data("Date: $datestr\r\n");
				&write_data("Server: $config{server}\r\n");
				&write_keep_alive(0);
				}
			foreach $h (@cgiheader) {
				&write_data("$h->[0]: $h->[1]\r\n");
				}
			&write_data("\r\n");
			&reset_byte_count();
			&write_data($headers);
			}
		}
	}
}

sub verify_client
{
local $cert = Net::SSLeay::X509_STORE_CTX_get_current_cert($_[1]);
if ($cert) {
	local $errnum = Net::SSLeay::X509_STORE_CTX_get_error($_[1]);
	$verified_client = 1 if (!$errnum);
	}
return 1;
}

sub END
{
if ($doing_eval && $$ == $main_process_id) {
	# A CGI program called exit! This is a horrible hack to 
	# finish up before really exiting
	shutdown(SOCK, 1);
	close(SOCK);
	close($PASSINw); close($PASSOUTw);
	&log_request($acpthost, $authuser, $reqline,
		     $cgiheader{"location"} ? "302" : $ok_code, &byte_count());
	}
}

# urlize
# Convert a string to a form ok for putting in a URL
sub urlize {
  local($tmp, $tmp2, $c);
  $tmp = $_[0];
  $tmp2 = "";
  while(($c = chop($tmp)) ne "") {
	if ($c !~ /[A-z0-9]/) {
		$c = sprintf("%%%2.2X", ord($c));
		}
	$tmp2 = $c . $tmp2;
	}
  return $tmp2;
}

# validate_user(username, password, [noappend])
sub validate_user
{
return ( ) if (!$_[0]);
if (!$users{$_[0]}) {
	# See if this user exists in Unix and can be validated by the same
	# method as the unixauth webmin user
	return ( undef, 0, 1 ) if (!$config{'unixauth'});
	local $up = $users{$config{'unixauth'}};
	return ( undef, 0, 1 ) if (!defined($up));
	local @uinfo = getpwnam($_[0]);

	# Work out our domain name from the hostname
	local $dom = $host;
	if ($dom =~ /^(www|ftp|mail)\.(\S+)$/i) {
		$dom = $2;
		}

	if ($config{'user_mapping'} && !defined(%user_mapping)) {
		# Read the user mapping file
		%user_mapping = ();
		open(MAPPING, $config{'user_mapping'});
		while(<MAPPING>) {
			s/\r|\n//g;
			s/#.*$//;
			if (/^(\S+)\s+(\S+)/) {
				$user_mapping{$2} = $1;
				}
			}
		close(MAPPING);
		}

	# Check the user mapping file to see if there is an entry for the
	# user login in which specifies a new effective user
	local $um = $user_mapping{"$_[0]\@$host"} ||
		    $user_mapping{"$_[0]\@$dom"} ||
		    $user_mapping{$_[0]};
	if (defined($um) && ($_[2]&4) == 0) {
		# A mapping exists - use it!
		local @vu = &validate_user($um, $_[1], $_[2]+4);
		return @vu;
		}

	# Check if a user with the entered login and the domain appended
	# or prepended exists, and if so take it to be the effective user
	if (!@uinfo && $config{'domainuser'}) {
		# Try again with name.domain and name.firstpart
		local $first;
		if ($dom =~ /^([^\.]+)/) {
			$first = $1;
			}
		if (($_[2]&1) == 0) {
			local ($a, $p);
			foreach $a ($first, $dom) {
				foreach $p ("$_[0].${a}", "$_[0]-${a}",
					    "${a}.$_[0]", "${a}-$_[0]",
					    "$_[0]_${a}", "${a}_$_[0]") {
					local @vu = &validate_user($p, $_[1],
								   $_[2] + 1);
					return @vu if (@vu);
					}
				}
			}
		}

	# Check if the user entered a domain at the end of his username when
	# he really shouldn't have, and if so try without it
	if (!@uinfo && $config{'domainstrip'} &&
	    $_[0] =~ /^(\S+)\@/ && ($_[2]&2) == 0) {
		local $stripped = $1;
		local @vu = &validate_user($stripped, $_[1], $_[2] + 2);
		return @vu if (@vu);
		}

	return ( undef, 0, 1 ) if (!@uinfo);

	if (defined(@allowusers)) {
		# Only allow people on the allow list
		return ( undef, 0, 0 ) if (!&users_match(\@uinfo, @allowusers));
		}
	elsif (defined(@denyusers)) {
		# Disallow people on the deny list
		return ( undef, 0, 0 ) if (&users_match(\@uinfo, @denyusers));
		}
	if ($config{'shells_deny'}) {
		local $found = 0;
		open(SHELLS, $config{'shells_deny'});
		while(<SHELLS>) {
			s/\r|\n//g;
			s/#.*$//;
			$found++ if ($_ eq $uinfo[8]);
			}
		close(SHELLS);
		return ( undef, 0, 0 ) if (!$found);
		}

	if ($up eq 'x') {
		local $val = &validate_unix_user($_[0], $_[1]);
		return $val == 2 ? ( $_[0], 1, 0 ) :
		       $val == 1 ? ( $_[0], 0, 0 ) : ( undef, 0, 0 );
		}
	elsif ($up eq 'e') {
		return &validate_external_user($_[0], $_[1]) ? ( $_[0] ) : ( );
		}
	else {
		return $up eq crypt($_[1], $up) ? ( $_[0] ) : ( );
		}
	}
elsif ($users{$_[0]} eq 'x') {
	# Call PAM to validate the user
	local $val = &validate_unix_user($_[0], $_[1]);
	return $val == 2 ? ( $_[0], 1, 0 ) :
	       $val == 1 ? ( $_[0], 0, 0 ) : ( undef, 0, 0 );
	}
elsif ($users{$_[0]} eq 'e') {
	# Pass to the external authentication program
	return &validate_external_user($_[0], $_[1]) ?
		( $_[0], 0, 0 ) : ( undef, 0, 0 );
	}
else {
	# Check against the webmin user list
	return $users{$_[0]} eq crypt($_[1], $users{$_[0]}) ?
		( $_[0], 0, 0 ) : ( undef, 0, 0 );
	}
}

# validate_unix_user(user, password)
# Returns 1 if a username and password are valid under unix, 0 if not.
# Checks PAM if available, and falls back to reading the system password
# file otherwise.
sub validate_unix_user
{
if ($use_pam) {
	# Check with PAM
	$pam_username = $_[0];
	$pam_password = $_[1];
	local $pamh = new Authen::PAM($config{'pam'}, $pam_username,
				      \&pam_conv_func);
	if (ref($pamh)) {
		local $pam_ret = $pamh->pam_authenticate();
		if ($pam_ret == PAM_SUCCESS()) {
			# Logged in OK .. make sure password hasn't expired
			local $acct_ret = $pamh->pam_acct_mgmt();
			if ($acct_ret == PAM_SUCCESS()) {
				return 1;
				}
			elsif ($acct_ret == PAM_NEW_AUTHTOK_REQD() ||
			       $acct_ret == PAM_ACCT_EXPIRED()) {
				return 2;
				}
			}
		return 0;
		}
	}
elsif ($config{'pam_only'}) {
	# Pam is not available, but configuration forces it's use!
	return 0;
	}
elsif ($config{'passwd_file'}) {
	local $rv = 0;
	open(FILE, $config{'passwd_file'});
	if ($config{'passwd_file'} eq '/etc/security/passwd') {
		# Assume in AIX format
		while(<FILE>) {
			s/\s*$//;
			if (/^\s*(\S+):/ && $1 eq $_[0]) {
				$_ = <FILE>;
				if (/^\s*password\s*=\s*(\S+)\s*$/) {
					$rv = $1 eq crypt($_[1], $1) ? 1 : 0;
					}
				last;
				}
			}
		}
	else {
		# Read the system password or shadow file
		while(<FILE>) {
			local @l = split(/:/, $_, -1);
			local $u = $l[$config{'passwd_uindex'}];
			local $p = $l[$config{'passwd_pindex'}];
			if ($u eq $_[0]) {
				$rv = $p eq crypt($_[1], $p) ? 1 : 0;
				if ($config{'passwd_cindex'} ne '' && $rv) {
					# Password may have expired!
					local $c = $l[$config{'passwd_cindex'}];
					local $m = $l[$config{'passwd_mindex'}];
					local $day = time()/(24*60*60);
					if ($c =~ /^\d+/ && $m =~ /^\d+/ &&
					    $day - $c > $m) {
						# Yep, it has ..
						$rv = 2;
						}
					}
				if ($p eq "" && $config{'passwd_blank'}) {
					# Force password change
					$rv = 2;
					}
				last;
				}
			}
		}
	close(FILE);
	return $rv if ($rv);
	}

# Fallback option - check password returned by getpw*
local @uinfo = getpwnam($_[0]);
if ($uinfo[1] ne '' && crypt($_[1], $uinfo[1]) eq $uinfo[1]) {
	return 1;
	}

return 0;	# Totally failed
}

# validate_external_user(user, pass)
# Validate a user by passing the username and password to an external
# squid-style authentication program
sub validate_external_user
{
return 0 if (!$config{'extauth'});
flock(EXTAUTH, 2);
local $str = "$_[0] $_[1]\n";
syswrite(EXTAUTH, $str, length($str));
local $resp = <EXTAUTH>;
flock(EXTAUTH, 8);
return $resp =~ /^OK/i ? 1 : 0;
}

# the PAM conversation function for interactive logins
sub pam_conv_func
{
$pam_conv_func_called++;
my @res;
while ( @_ ) {
	my $code = shift;
	my $msg = shift;
	my $ans = "";

	$ans = $pam_username if ($code == PAM_PROMPT_ECHO_ON() );
	$ans = $pam_password if ($code == PAM_PROMPT_ECHO_OFF() );

	push @res, PAM_SUCCESS();
	push @res, $ans;
	}
push @res, PAM_SUCCESS();
return @res;
}

sub urandom_timeout
{
close(RANDOM);
}

# get_socket_name(handle)
sub get_socket_name
{
return $config{'host'} if ($config{'host'});
local $sn = getsockname($_[0]);
return undef if (!$sn);
local ($myport, $myaddr) = unpack_sockaddr_in($sn);
if (!$get_socket_name_cache{$myaddr}) {
	local $myname = gethostbyaddr($myaddr, AF_INET);
	if ($myname eq "") {
		$myname = inet_ntoa($myaddr);
		}
	$get_socket_name_cache{$myaddr} = $myname;
	}
return $get_socket_name_cache{$myaddr};
}

# run_login_script(username, sid, remoteip, localip)
sub run_login_script
{
if ($config{'login_script'}) {
	system($config{'login_script'}.
	       " ".join(" ", map { quotemeta($_) } @_).
	       " >/dev/null 2>&1 </dev/null");
	}
}

# run_logout_script(username, sid, remoteip, localip)
sub run_logout_script
{
if ($config{'logout_script'}) {
	system($config{'logout_script'}.
	       " ".join(" ", map { quotemeta($_) } @_).
	       " >/dev/null 2>&1 </dev/null");
	}
}

# close_all_sockets()
# Closes all the main listening sockets
sub close_all_sockets
{
local $s;
foreach $s (@socketfhs) {
	close($s);
	}
}

sub check_user_ip
{
if ($deny{$_[0]} &&
    &ip_match($acptip, $localip, @{$deny{$_[0]}}) ||
    $allow{$_[0]} &&
    !&ip_match($acptip, $localip, @{$allow{$_[0]}})) {
	return 0;
	}
return 1;
}

