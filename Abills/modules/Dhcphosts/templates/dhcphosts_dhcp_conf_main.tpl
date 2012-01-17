# Create %DATETIME%
#
#option domain-name %DOMAINNAME%;
#option domain-name-servers %DNS%;
default-lease-time 86400;
max-lease-time 172800;
ddns-update-style none;
lease-file-name \"/var/db/dhcpd/dhcpd.leases\";


option ms-classless-static-routes code 249 = array of integer 8;
option rfc3442-classless-static-routes code 121 = array of unsigned integer 8;
log-facility local7;

shared-network NETWORK_NAME {
 #List of subnets
 %SUBNETS%
}

#List of hosts
%HOSTS%
