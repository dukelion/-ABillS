<FORM>
<input type='hidden' name='index' value='$index'>

<TABLE width='100%' cellspacing='0' cellpadding='0' border='0'><TR><TD bgcolor='#E1E1E1'>
<TABLE width='100%' cellspacing='1' cellpadding='0' border='0'>
<TR bgcolor='$_COLORS[1]'><td>$_LOGIN:</td><td colspan='3'>%LOGIN%</td></tr>
<tr><th colspan='4' bgcolor='$_COLORS[0]'>Station Information and Status</th></tr>
<TR bgcolor='$_COLORS[1]'><td>MAC Address</td><td>%MAC%</td><td>$_NAME</td><td>%cDot11ClientName%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>IP Address:</td><td>%cDot11ClientIpAddress%</td><td>Class</td><td>%cDot11ClientIpAddressType%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Device:	</td><td>%cDot11ClientDevType%</td><td>Software Version</td><td>%cDot11ClientSoftwareVersion%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>CCX Version<td></td><td></td><td> </td></tr>

<TR bgcolor='$_COLORS[1]'><td>State:<td>%cDot11ClientAssociationState%</td><td>Parent:</td><td>%cDot11ClientParentAddress%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>SSID<td></td><td>VLAN</td><td>%cDot11ClientVlanId%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Hops To Infrastructure<td></td><td>Communication Over Interface</td><td> </td></tr>
<TR bgcolor='$_COLORS[1]'><td>cDot11Clients Associated<td></td><td>Repeaters Associated</td><td> </td></tr>
<TR bgcolor='$_COLORS[1]'><td>Key Mgmt type<td></td><td>Encryption</td><td>%cDot11ClientWepEnabled%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Current Rate (Mb/sec)	<td>%cDot11ClientCurrentTxRateSet%</td><td>Capability</td><td> </td></tr>
<TR bgcolor='$_COLORS[1]'><td>Supported Rates(Mb/sec)</td><td colspan='3'>%cDot11ClientDataRateSet%</td></tr>

<tr bgcolor='$_COLORS[1]'><td>Voice Rates(Mb/sec):</td><td></td><td>Association Id</td><td>%cDot11ClientAid%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Signal Strength (dBm)<td>%cDot11ClientSignalStrength%</td><td>Connected For (sec)</td><td>%cDot11ClientUpTime%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Signal Quality (%)<td>%cDot11ClientSigQuality%</td><td>Activity TimeOut (sec)</td><td>%cDot11ClientAgingLeft%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Power-save<td>%cDot11ClientPowerSaveMode%</td><td>Last Activity (sec)</td><td> </td></tr>


<tr><th colspan='4' bgcolor='$_COLORS[0]'>Receive/Transmit Statistics</th></tr>
<TR bgcolor='$_COLORS[1]'><td>Total Packets Input:<td>%cDot11ClientPacketsReceived%</td><td>Total Packets Output</td><td>%cDot11ClientPacketsSent%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Total Bytes Input:<td>%cDot11ClientBytesReceived%</td><td>Total Bytes Output:</td><td>%cDot11ClientBytesSent%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Duplicates Received<td>%cDot11ClientDuplicates%</td><td>Maximum Data Retries</td><td>%cDot11ClientMsduRetries%</td></tr>
<TR bgcolor='$_COLORS[1]'><td>Decrypt Errors<td>%cDot11ClientWepErrors%</td><td>Maximum RTS Retries</td><td> </td></tr>
<TR bgcolor='$_COLORS[1]'><td>MIC Failed<td>%cDot11ClientMicErrors%</td><td></td><td> </td></tr>
<TR bgcolor='$_COLORS[1]'><td>MIC Missing<td>%cDot11ClientMicMissingFrames%</td><td></td><td> </td></tr>

</TABLE>
</TD></TR></TABLE>

</table>
</FORM>
