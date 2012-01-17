<FORM>
<input type='hidden' name='index' value='$index'>

<TABLE width='100%' cellspacing='0' cellpadding='0' border='0'><TR><TD bgcolor='#E1E1E1'>
<TABLE width='100%' cellspacing='1' cellpadding='0' border='0'>
<TR bgcolor='$_COLORS[1]'><td>$_LOGIN:</td><td colspan='3'>%LOGIN%</td></tr>
<tr><th colspan='4' bgcolor='$_COLORS[0]'>Station Information and Status</th></tr>
<TR bgcolor='$_COLORS[1]'><td>MAC Address</td><td>%MAC%</td><td>$_NAME</td><td>%ClientName%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>IP Address:</td><td>%ClientIpAddress%</td><td>Class</td><td>%ClientIpAddressType%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Device:	</td><td>%ClientDevType%</td><td>Software Version</td><td>%ClientSoftwareVersion%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>CCX Version<td></td><td></td><td> </td></tr>

<TR bgcolor='$_COLORS[1]'><td>State:<td>%ClientAssociationState%</td><td>Parent:</td><td>%ClientParentAddress%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>SSID<td></td><td>VLAN</td><td> </td></tr>
<TR bgcolor='$_COLORS[1]'><td>Hops To Infrastructure<td></td><td>Communication Over Interface</td><td> </td></tr>
<TR bgcolor='$_COLORS[1]'><td>Clients Associated<td></td><td>Repeaters Associated</td><td> </td></tr>
<TR bgcolor='$_COLORS[1]'><td>Key Mgmt type<td></td><td>Encryption</td><td>%ClientWepEnabled%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Current Rate (Mb/sec)	<td>%ClientCurrentTxRate%</td><td>Capability</td><td> </td></tr>
<TR bgcolor='$_COLORS[1]'><td>Supported Rates(Mb/sec)</td><td colspan='3'>%ClientDataRateSet%</td></tr>

<tr bgcolor='$_COLORS[1]'><td>Voice Rates(Mb/sec):</td><td></td><td>Association Id</td><td>%ClientAid%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Signal Strength (dBm)<td>%ClientSignalStrength%</td><td>Connected For (sec)</td><td>%ClinetUptime%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Signal Quality (%)<td>%ClientSigQuality%</td><td>Activity TimeOut (sec)</td><td>%ClientAgingLeft%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Power-save<td>%ClientPowerSaveMode%</td><td>Last Activity (sec)</td><td> </td></tr>


<tr><th colspan='4' bgcolor='$_COLORS[0]'>Receive/Transmit Statistics</th></tr>
<TR bgcolor='$_COLORS[1]'><td>Total Packets Input:<td>%ClientPacketsReceived%</td><td>Total Packets Output</td><td>%ClientPacketsSent%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Total Bytes Input:<td>%ClientBytesReceived%</td><td>Total Bytes Output:</td><td>%ClientBytesSent%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Duplicates Received<td>%ClientDuplicates%</td><td>Maximum Data Retries</td><td>%ClientMsduRetries%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Decrypt Errors<td>%ClientWepErrors%</td><td>Maximum RTS Retries</td><td> </td></tr>
<TR bgcolor='$_COLORS[1]'><td>MIC Failed<td>%ClientMicErrors%</td><td></td><td> </td></tr>
<TR bgcolor='$_COLORS[1]'><td>MIC Missing<td>%ClientMicMissingFrames%</td><td></td><td> </td></tr>

</TABLE>
</TD></TR></TABLE>

</table>
</FORM>