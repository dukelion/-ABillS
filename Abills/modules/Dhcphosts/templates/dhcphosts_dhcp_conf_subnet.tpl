 #Subnets %DESCRIBE%
 subnet %NETWORK% netmask %NETWORK_MASK% {
   %DNS%
   %NTP%
   %DOMAINNAME%
   #IP Range
   %RANGE%
   %DENY_UNKNOWN_CLIENTS%
   %AUTHORITATIVE%   
   %ROUTERS%
   %NET_ROUTES%
   %NET_ROUTES_RFC3442%   
   %OPTION82_POOLS%
  }