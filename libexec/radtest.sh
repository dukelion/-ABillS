#!/bin/sh

AUTH_LOG=/usr/abills/var/log/abills.log
ACCT_LOG=/usr/abills/var/log/acct.log


echo $1 

echo `pwd -P`;

if [ t$1 = 'tauth' ] ; then

  ./rauth.pl \
        SERVICE_TYPE=VPN \
        USER_NAME="test"\
        NAS_IP_ADDRESS=192.168.202.15 \
        CALLING_STATION_ID="00-0D-88-42-87-7E"\
         USER_PASSWORD="test"
#        CHAP_PASSWORD="0x5acd1cc26b6f8bf084fb616925769362af"

#        USER_PASSWORD="test12345"\
#        CISCO_AVPAIR="connect-progress=LAN Ses Up" \
#        CISCO_AVPAIR="client-mac-address=000f.ea3d.92ef"\
         CALLING_STATION_ID="00-0D-88-42-87-7E" 
#        NAS-Port-Type = Virtual \
#        CALLED_STATION_ID="00-09-E8-62-B3-4D" \
#        CALLING_STATION_ID="10.10.10.2"


#        USER_NAME="aa1" \
#        USER_PASSWORD="test123" \
#        CALLED_STATION_ID="00-09-E8-62-B3-4D" \
#        CALLING_STATION_ID="00-07-E9-19-72-1B" \
#        SERVICE_TYPE="Login-User"\
#        NAS_PORT_TYPE=Wireless-802.11 \
#        NAS_PORT=66\
#        NAS_IP_ADDRESS=192.168.101.17 \
#        NAS_IDENTIFIER="ap" \
#        ACCT_MULTI_SESSION_ID="" 

#     USER_NAME="aa1" \
#     NAS_IP_ADDRESS=192.168.101.17 \
#     SERVICE_TYPE=Framed-User \
#     CALLING_STATION_ID="192.168.101.4" \
#     MS_CHAP_CHALLENGE=0x36303131333831363438383235383730 \
#     MS_CHAP2_RESPONSE=0x010043e7c3db656fb14dc7546f9f0e4b9c810000000000000000ae86198b1adcfc9a092469d5073c7595de1b6e784c8b7bc7 \
#     USER_PASSWORD="4vYE2vKM" \


#     CALLING_STATION_ID="00:20:ed:9c:c3:43"\
#     CALLED_STATION_ID=pppoe\
#     CHAP_CHALLENGE=0x31323331333337363130353537333539 \
#     CHAP_PASSWORD=0x01456e3b61d9102cb9985bc4bf995120c2 \
#     USER_PASSWORD="qPTvEwAE" \

   echo "" 
   echo "Auth test end"


elif [ t$1 = 'tacct' ]; then
   echo "Accounting test";

  if [ t$2 = 'tStart' ]; then
   echo Start;
   ./racct.pl \
        USER_NAME="aa1" \
        SERVICE_TYPE=Framed-User \
        FRAMED_PROTOCOL=PPP \
        FRAMED_IP_ADDRESS=10.0.0.1 \
        FRAMED_IP_NETMASK=0.0.0.0 \
        CISCO_AVPAIR="connect-progress=LAN Ses Up"\
        CISCO_AVPAIR="client-mac-address=0001.29d2.2695"\
        NAS_IP_ADDRESS=192.168.202.15 \
        NAS_IDENTIFIER="media.intranet" \
        NAS_PORT_TYPE=Virtual \
        ACCT_STATUS_TYPE=Start \
        ACCT_SESSION_ID="83419_AA11118757979" \

#        CALLING_STATION_ID="192.168.101.4" \

   elif [ t$2 = 'tStop' ] ; then
      echo Stop;
      ./racct.pl \
        USER_NAME="aa1" \
        SERVICE_TYPE=Framed-User \
        FRAMED_PROTOCOL=PPP \
        FRAMED_IP_ADDRESS=10.0.0.1 \
        FRAMED_IP_NETMASK=0.0.0.0 \
        CALLING_STATION_ID="192.168.101.4" \
        NAS_IP_ADDRESS=192.168.202.15 \
        NAS_IDENTIFIER="media.intranet" \
        NAS_PORT_TYPE=Virtual \
        ACCT_STATUS_TYPE=Stop \
        ACCT_SESSION_ID="83419_AA11118757979" \
        ACCT_DELAY_TIME=0 \
        ACCT_INPUT_OCTETS=1000 \
        ACCT_INPUT_GIGAWORDS=0 \
        ACCT_INPUT_PACKETS=125 \
        ACCT_OUTPUT_OCTETS=1000 \
        EXPPP_ACCT_LOCALINPUT_OCTETS=12000000 \
        EXPPP_ACCT_LOCALOUTPUT_OCTETS=13000000 \
        ACCT_OUTPUT_GIGAWORDS=0 \
        ACCT_OUTPUT_PACKETS=0 \
        ACCT_SESSION_TIME=100 \



   fi


elif [ t$1 = 'tacctgt' ]; then

  echo "Account requirest GT: "
  cat $ACCT_LOG | grep GT | awk '{ print $11"  "$1" "$2" "$5" "$8" "$9 }' | sort -n


elif [ t$1 = 'tauthgt' ]; then

  cat $AUTH_LOG | grep GT | awk '{ print $10"  "$1" "$2" "$5" "$8 }' | sort -n


elif [ t$1 = 'tvoip' ] ; then 

 echo "Voip";
  if [ t$2 = 'tauth' ] ; then
   echo Auth;
   ./rauth.pl NAS_IP_ADDRESS="192.168.202.15" \
     NAS_PORT_TYPE="Virtual" \
     NAS_IDENTIFIER="ASMODEUSGK" \
     CLIENT_IP_ADDRESS="192.168.101.17" \
     CISCO_AVPAIR="h323-ivr-out=terminal-alias:100;" \
     SERVICE_TYPE="Login-User" \
     CHAP_CHALLENGE="0x43a28c01" \
     USER_NAME="200" \
     FRAMED_IP_ADDRESS="192.168.101.23" \
     HUNTGROUP_NAME="voips" 

#     CHAP_PASSWORD="0x06a8f3fb0ab5f4a8e90a590686c845c456" \
 

  elif [ t$2 = 'tcallstart' ] ; then
    echo "Start\n";

   ./rauth.pl NAS_IP_ADDRESS="192.168.101.17" \
       CHAP_PASSWORD="0x0338b5a0e6ade0557eb9e5d208fe0f5eee" \
       H323_CONF_ID="h323-conf-id=16000 647BEE1D 80F000A F453DBFD"\
       H323_GW_ID="h323-gw-id=ASMODEUSGK"\
       NAS_PORT_TYPE="Virtual"\
       CALLING_STATION_ID="101"\
       H323_CALL_ORIGIN="h323-call-origin=originate"\
       NAS_IDENTIFIER="ASMODEUSGK"\
       SERVICE_TYPE="Login-User"\
       CLIENT_IP_ADDRESS="192.168.101.17"\
       CHAP_CHALLENGE="0x43aea616"\
       FRAMED_IP_ADDRESS="192.168.101.23"\
       USER_NAME="101"\
       CALLED_STATION_ID="613"\
       H323_CALL_TYPE="h323-call-type=VoIP"\
       HUNTGROUP_NAME="voips"

# RadAliasAuth
#   ./rauth.pl NAS_IP_ADDRESS="192.168.101.17" \
#       USER_PASSWORD="101"\
#       H323_CONF_ID="h323-conf-id=16000 647BEE1D 80F000A F453DBFD"\
#       H323_GW_ID="h323-gw-id=ASMODEUSGK"\
#       NAS_PORT_TYPE="Virtual"\
#       CALLING_STATION_ID="101"\
#       H323_CALL_ORIGIN="h323-call-origin=originate"\
#       NAS_IDENTIFIER="ASMODEUSGK"\
#       SERVICE_TYPE="Login-User"\
#       CLIENT_IP_ADDRESS="192.168.101.17"\
#       FRAMED_IP_ADDRESS="192.168.101.23"\
#       USER_NAME="101"\
#       CALLED_STATION_ID="613"\
#       H323_CALL_TYPE="h323-call-type=VoIP"\
#       HUNTGROUP_NAME="voips"


   ./racct.pl ACCT_UNIQUE_SESSION_ID="7ae849dcfba1c03f"\
      H323_CONF_ID="h323-conf-id=16000 647BEE1D 80F000A F453DBFD"\
      NAS_PORT_TYPE="Virtual"\
      H323_CALL_ORIGIN="h323-call-origin=proxy"\
      NAS_IDENTIFIER="ASMODEUSGK"\
      CLIENT_IP_ADDRESS="192.168.101.17"\
      CISCO_AVPAIR="h323-ivr-out=h323-call-id:16000 660DB41B 209000A F453DBFD"\
      ACCT_STATUS_TYPE="Start"\
      SERVICE_TYPE="Login-User"\
      H323_SETUP_TIME="h323-setup-time=15:59:47.000 EET Sun Dec 25 2005"\
      USER_NAME="101"\
      NAS_IP_ADDRESS="192.168.101.17"\
      H323_GW_ID="h323-gw-id=ASMODEUSGK"\
      CALLING_STATION_ID="101"\
      H323_REMOTE_ADDRESS="h323-remote-address=192.168.101.4"\
      ACCT_SESSION_ID="43ad25ca0000000e"\
      FRAMED_IP_ADDRESS="192.168.101.23"\
      ACCT_DELAY_TIME="0"\
      H323_CALL_TYPE="h323-call-type=VoIP"\
      CALLED_STATION_ID="613"






   elif [ t$2 = 'tstop' ] ; then
    echo "Voip Stop"
   ./racct.pl  ACCT_UNIQUE_SESSION_ID="7ae849dcfba1c03f"\
   H323_CONF_ID="h323-conf-id=16000 647BEE1D 80F000A F453DBFD"\
   NAS_PORT_TYPE="Virtual"\
   H323_CALL_ORIGIN="h323-call-origin=proxy"\
   NAS_IDENTIFIER="ASMODEUSGK"\
   CLIENT_IP_ADDRESS="192.168.101.17"\
   CISCO_AVPAIR="h323-ivr-out=h323-call-id:16000 660DB41B 209000A F453DBFD"\
   H323_DISCONNECT_CAUSE="h323-disconnect-cause=10"\
   ACCT_STATUS_TYPE="Stop"\
   SERVICE_TYPE="Login-User"\
   H323_SETUP_TIME="h323-setup-time=15:59:47.000 EET Sun Dec 25 2005"\
   H323_DISCONNECT_TIME="h323-disconnect-time=16:01:54.000 EET Sun Dec 25 2005"\
   USER_NAME="101"\
   NAS_IP_ADDRESS="192.168.101.17"\
   ACCT_SESSION_TIME="99"\
   H323_GW_ID="h323-gw-id=ASMODEUSGK"\
   CALLING_STATION_ID="101"\
   H323_CONNECT_TIME="h323-connect-time=16:00:15.000 EET Sun Dec 25 2005"\
   H323_REMOTE_ADDRESS="h323-remote-address=192.168.101.4"\
   ACCT_SESSION_ID="43ad25ca0000000e"\
   FRAMED_IP_ADDRESS="192.168.101.23"\
   H323_CALL_TYPE="h323-call-type=VoIP"\
   CALLED_STATION_ID="613"\
   ACCT_DELAY_TIME="0"\















 fi

else 
 echo "Arguments (auth | acct | authgt | acctgt)"
 echo "       auth - test authentification
       acct - test accounting
       authgt - show authentification generation time
       acctgt - show account generation time
  "
fi

#   CHAP_PASSWORD=0x01f45d3646ef51e0b34dfca50f17f0d524 \
#   CHAP_CHALLENGE=0x36373035393933393135333537313734 \

