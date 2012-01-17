# LOGIN: %LOGIN%
class \"%OPTION82_NAS_NAME%-%OPTION82_NAS_MAC%-port-%OPTION82_NAS_PORT%\" { match if binary-to-ascii(16, 8, \":\", substring(option agent.remote-id, 2, 6)) = \"%OPTION82_NAS_MAC%\" and binary-to-ascii(10, 8, \":\", substring(option agent.circuit-id, 5, 1)) = \"%OPTION82_NAS_PORT%\" and binary-to-ascii (10, 16, \"\", substring( option agent.circuit-id, 2, 2)) = \"%CLIENT_VLAN%\"  ;  
}
# For mac Auth
# binary-to-ascii (16, 8, \":\", substring(hardware, 1, 7))=\"%CLIENT_MAC%\"






