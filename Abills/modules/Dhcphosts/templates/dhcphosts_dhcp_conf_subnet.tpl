 #Subnets %DESCRIBE%
 subnet %NETWORK% netmask %NETWORK_MASK% {
   %DNS%
   %DOMAINNAME%
   #IP Range
   %RANGE%
   # Old config params
   #deny unknown-clients;
   #authoritative;   
   %DENY_UNKNOWN_CLIENTS%
   %AUTHORITATIVE%   
   %ROUTERS%
   %NET_ROUTES%
   %NET_ROUTES_RFC3442%   
   %OPTION82_POOLS%
  }