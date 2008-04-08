# Create by ABillS DATE: %DATETIME%
#
default-lease-time 86400;
max-lease-time 172800;
ddns-update-style none;
lease-file-name \"/var/db/dhcpd/dhcpd.leases\";


#Static route
option ms-classless-static-routes code 249 = array of integer 8;
option rfc3442-classless-static-routes code 121 = array of unsigned integer 8;
log-facility local7;


#Option 82 section
#Option 82 loging
if exists agent.circuit-id
{
	log ( info, concat( \"Lease for \", binary-to-ascii (10, 8, \".\", leased-address), \" is connected to interface \",
	binary-to-ascii (10, 8, \"/\", suffix ( option agent.circuit-id, 2)), \" (add 1 to port number!), VLAN \",
	binary-to-ascii (10, 16, \"\", substring( option agent.circuit-id, 2, 2)),  \" on switch \", 
	binary-to-ascii(16, 8, \":\", substring( option agent.remote-id, 2, 6))));
	
	log ( info, concat( \"Lease for \", binary-to-ascii (10, 8, \".\", leased-address), 
	\" raw option-82 info is CID: \", binary-to-ascii (10, 8, \".\", option agent.circuit-id), \" AID: \",
	binary-to-ascii(16, 8, \".\", option agent.remote-id)));

}

%OPTION82_CLASS%

shared-network NETWORK_NAME {
 #List of subnets
 %SUBNETS%
}

#List of hosts
%HOSTS%
