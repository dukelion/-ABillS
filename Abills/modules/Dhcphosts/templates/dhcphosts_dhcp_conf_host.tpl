# Login: %LOGIN%
host %HOSTNAME% {
  hardware ethernet %MAC%;
  fixed-address %IP%;
  option routers %ROUTERS%;
  %BOOT_FILE%
}
