#!/bin/sh
# ABILLS Certificat creator



SSL=/usr/local/${OPENSSL}
export PATH=/usr/src/crypto/${OPENSSL}/apps/:${SSL}/bin/:${SSL}/ssl/misc:${PATH}
export LD_LIBRARY_PATH=${SSL}/lib
CA_pl='/usr/src/crypto/openssl/apps/CA.pl';


hostname=`hostname`;
password=whatever;
VERSION=1.84;
DAYS=730;
DATE=`date`;
CERT_TYPE=$1;
CERT_USER="";
OPENSSL=`which openssl`
CERT_LENGTH=2048;


if [ w$1 = whelp ]; then
  shift ;
fi;


if [ w$1 = w ] ; then
  echo "Create SSL Certs and SSH keys. Version: ${VERSION} ";
  echo "certs_create.sh [apache|eap|postfix_tls|ssh|express_oplata] -D";
  echo " apache         - Create apache SSL cert"
  echo " eap            - Create Server and users SSL Certs"
  echo " postfix_tls    - Create postfix TLS Certs"
  echo " express_oplata - Express oplata payment system"
  echo " easysoft [public_key] - Easysoft payment system"
  echo " info [file]    - Get info from SSL cert"
  echo " ssh [USER]     - Create SSH DSA Keys"
  echo "                USER - SSH remote user"
  echo " -D [PATH]      - Path for ssl certs"
  echo " -U [username]  - Cert owner (Default: apache=www, postfix=vmail)"
  echo " -LENGTH        - Cert length (Default: ${CERT_LENGTH})"
  echo " -DAYS          - Cert period in days (Default: ${DAYS})"
  echo " -PASSSWORD     - Password for Certs (Default: whatever)"
  echo " -HOSTNAME      - Hostname for Certs (default: system hostname)"
  echo " -UPLOAD        - Upload ssh certs to host via ssh (default: )"
  

  exit;
fi

CERT_PATH=/usr/abills/Certs/

# Proccess command-line options
#
for _switch ; do
        case $_switch in
        -D)
                CERT_PATH="$3"
                shift; shift
                ;;
        -U)
                CERT_USER="$3"
                shift; shift
                ;;
        -LENGTH) CERT_LENGTH=$3
                shift; shift
                ;;
        -DAYS) DAYS=$3
                shift; shift
                ;;
        -PASSWORD) password=$3
                shift; shift
                ;;
        -HOSTNAME) hostname=$3
                shift; shift
                ;;
        -UPLOAD) UPLOAD=y; HOST=$4
                #shift; shift;
                ;;
        esac
done


if [ ! -d ${CERT_PATH} ] ; then
  mkdir ${CERT_PATH};
fi
cd ${CERT_PATH};

#Default Cert user
if [ x${CERT_USER} = x ];  then
  if [ x`uname` = xLinux ]; then
     APACHE_USER="www-data";
  else 
    APACHE_USER=www;
  fi;
else 
  APACHE_USER=${CERT_USER};
fi;


#**********************************************************
# easysoft payments system
# http://easysoft.com.ua/
# kabanets@easysoft.com.ua
#**********************************************************
easysoft_cert () {
  echo "#******************************************************************************"
  echo "#Creating EasySoft certs"
  echo "#"
  echo "#******************************************************************************"
  echo

  if [ w$1 = w  ]; then
    echo "Enter path to EasySoft public key: ";
    read EASYSOFT_PUBLIC_KEY
  else
    EASYSOFT_PUBLIC_KEY=$1;
  fi;

  if [ w${EASYSOFT_PUBLIC_KEY} = w ]; then
    echo "Enter easysoft public key";
    exit;
  fi;
 
  if [ w${EASYSOFT_PUBLIC_KEY} != w ]; then
    cp ${EASYSOFT_PUBLIC_KEY} ${CERT_PATH}/easysoft_server_public.pem
    chown ${APACHE_USER} ${CERT_PATH}/easysoft_server_public.pem
    echo "Easy soft public key copy to ${CERT_PATH}/easysoft_server_public.pem"
  fi;

  ${OPENSSL} x509 -inform pem -in ${EASYSOFT_PUBLIC_KEY} -pubkey -out ${CERT_PATH}/easysoft_public_key.pem > ${CERT_PATH}/easysoft_server_public.pem


  CERT_LENGTH=1024;
  # Private key
  ${OPENSSL} genrsa -out easysoft_private.ppk ${CERT_LENGTH} 
  ${OPENSSL} req -new -key easysoft_private.ppk -out easysoft.req 
  #${OPENSSL} ca -in easysoft.req -out easysoft.cer 
  ${OPENSSL} x509 -req -days ${DAYS} -in easysoft.req -signkey easysoft_private.ppk -out easysoft.cer
  ${OPENSSL} rsa -in  ${CERT_PATH}/easysoft_private.ppk -out ${CERT_PATH}/easysoft_public.pem -pubout

  chmod u=r,go= ${CERT_PATH}/easysoft.cer
  chown ${APACHE_USER} ${CERT_PATH}/easysoft.cer ${CERT_PATH}/easysoft_private.ppk ${CERT_PATH}/easysoft_public.pem

  echo "Sert created: ";
  echo "Send this file to EasyPay (kabanets@easysoft.com.ua): ${CERT_PATH}/easysoft.cer";

}

#**********************************************************
#Apache Certs
#**********************************************************
apache_cert () {
  echo "*******************************************************************************"
  echo "Creating Apache server private key and certificate"
  echo "When prompted enter the server name in the Common Name field."
  echo "*******************************************************************************"
  echo

  ${OPENSSL} genrsa -des3 -passout pass:${password} -out server.key ${CERT_LENGTH}

  ${OPENSSL} req -new -key server.key -out server.csr \
  -passin pass:${password} -passout pass:${password}

  ${OPENSSL} x509 -req -days ${DAYS} -in server.csr -signkey server.key -out server.crt \
   -passin pass:${password}

  chmod u=r,go= ${CERT_PATH}/server.key
  chmod u=r,go= ${CERT_PATH}/server.crt
  chown ${APACHE_USER} server.crt server.csr

  cp ${CERT_PATH}/server.key ${CERT_PATH}/server.key.org

  ${OPENSSL} rsa -in server.key.org -out server.key \
   -passin pass:${password} -passout pass:${password}

  #Cert info
  #${OPENSSL} x509 -in server.crt -noout -subject
  cert_info server.crt

  chmod 400 server.key

  echo "Please restart apache";
}


#**********************************************************
# Create SSH certs
#**********************************************************
ssh_key () {
  echo "**************************************************************************"
  echo "Creating SSH authentication Key"
  echo " Make ssh-keygen with empty password."
  echo "**************************************************************************"
  echo

  USER=$1;

  if [ w${CERT_TYPE} = w ]; then
    id_dsa_file=id_dsa;
  else
    id_dsa_file=id_dsa.$1;
  fi;

  # If exist only upload
  
  if [ -f ${CERT_PATH}${id_dsa_file} ]; then
     echo "Cert exists: ${CERT_PATH}${id_dsa_file}";
     if [ x${UPLOAD} = x ]; then
       echo "Upload to remote host[Y/n]: "
       read UPLOAD
     fi;
  fi;

 
  if [ ! -f ${CERT_PATH}${id_dsa_file} ]; then
    ssh-keygen -t dsa -C "ABillS remote machine manage key (${DATE})" -f "${CERT_PATH}${id_dsa_file}"

    chown ${APACHE_USER} ${CERT_PATH}${id_dsa_file}
    chmod u=r,go= ${CERT_PATH}/${id_dsa_file}.pub
    echo "Set Cert user: ${CERT_USER}";

    echo -n "Upload file to remote host (y/n): "
    read UPLOAD
  fi;

  if [ x${UPLOAD} = xy ]; then
    if [ x${HOST} = x ]; then
      echo -n "Enter host: "
      read HOST
    fi;

    echo "Make upload to: ${USER}@${HOST} "
    ssh ${USER}@${HOST} "mkdir ~/.ssh"
    scp ${CERT_PATH}${id_dsa_file}.pub ${USER}@${HOST}:~/.ssh/authorized_keys
    
    echo -n "Connect to remote host: ${HOST}  (y/n): "
    read CONNECT
    if [ w${CONNECT} = wy ]; then
      ssh -o StrictHostKeyChecking=no -i ${CERT_PATH}${id_dsa_file}  ${USER}@${HOST}
      exit;
    fi;
  else 
    echo 
    echo "Copy ${CERT_PATH}${id_dsa_file}.pub to REMOTE_HOST User home dir (/home/${USER}/.ssh/authorized_keys) "
    echo 
  fi;
 }

#**********************************************************
# create Express Oplata Certs
# www.express-oplata.ru/
#**********************************************************
express_oplata () {
  echo "#*******************************************************************************"
  echo "#Creating Express Oplata"
  echo "#"
  echo "#*******************************************************************************"
  echo

  CERT_LENGTH=1024;
  password="whatever"
  # Private key
  echo ${OPENSSL};
  ${OPENSSL} genrsa  -passout pass:${password} -out express_oplata_private.pem ${CERT_LENGTH} 
      

  # Publick key
  ${OPENSSL} rsa -in express_oplata_private.pem -out express_oplata_public.pem -pubout \
    -passin pass:${password} 

  chmod u=r,go= ${CERT_PATH}/express_oplata_private.pem
  chmod u=r,go= ${CERT_PATH}/express_oplata_public.pem
  chown ${APACHE_USER} ${CERT_PATH}/express_oplata_private.pem ${CERT_PATH}/express_oplata_public.pem
  
  echo -n "Send public key '${CERT_PATH}/express_oplata_public.pem' to Express Oplata? (y/n): ";

  read _SEND_MAIL
  if [ w${_SEND_MAIL} = wy ]; then
    EO_EMAIL="onwave@express-oplata.ru";
  
    echo -n "Enter comments: "
    read COMMENTS

    echo -n "BCC: "
    read BCC_EMAIL

    if [ w${BCC_EMAIL} != w ]; then
      BCC_EMAIL="-b ${BCC_EMAIL}"
    fi; 

    ( echo "${COMMENTS}"; uuencode /usr/abills/Certs/express_oplata_public.pem express_oplata_public.pem ) | mail -s "Public Cert" ${BCC_EMAIL} $EO_EMAIL
    
    echo "Cert sended to Expres-Oplata"
  fi;

}

#**********************************************************
# Information about Certs
#**********************************************************
cert_info () {
  echo "******************************************************************************"
  echo "Cert info $2"
  echo "******************************************************************************"

  FILENAME=$1;
  if [ w$FILENAME = w ] ; then 
    echo "Select Cert file";
    exit;
  else 
    echo "Cert file: $FILENAME";
  fi;

  ${OPENSSL} x509 -in ${FILENAME} -noout -subject  -startdate -enddate
}

#**********************************************************
# postfix
#**********************************************************
postfix_cert () {
  echo "******************************************************************************"
  echo "Make POSTFIX TLS sertificats"
  echo "******************************************************************************"

  ${OPENSSL} req -new -x509 -nodes -out smtpd.pem -keyout smtpd.pem -days ${DAYS} \
    -passin pass:${password} -passout pass:${password}
}

#**********************************************************
# eap for radius
#**********************************************************
eap_cert () {
  echo "*******************************************************************************"
  echo "Make RADIUS EAP"
  echo "*******************************************************************************"

  CERT_EAP_PATH=${CERT_PATH}/eap
  if [ ! -d ${CERT_EAP_PATH} ] ; then
    mkdir ${CERT_EAP_PATH};
  fi

  cd ${CERT_EAP_PATH}
  echo 
  pwd

if [ w$2 = wclient ]; then
  echo "*******************************************************************************"
  echo "Creating client private key and certificate"
  echo "When prompted enter the client name in the Common Name field. This is the same"
  echo " used as the Username in FreeRADIUS"
  echo "*******************************************************************************"
  echo

  # Request a new PKCS#10 certificate.
  # First, newreq.pem will be overwritten with the new certificate request
  ${OPENSSL} req -new -keyout newreq.pem -out newreq.pem -days ${DAYS} \
   -passin pass:${password} -passout pass:${password}


  # Sign the certificate request. The policy is defined in the ${OPENSSL}.cnf file.
  # The request generated in the previous step is specified with the -infiles option and
  # the output is in newcert.pem
  # The -extensions option is necessary to add the OID for the extended key for client authentication
  ${OPENSSL} ca -policy policy_anything -out newcert.pem -passin pass:${password} \
    -key ${password} -extensions xpclient_ext -extfile xpextensions \
    -infiles newreq.pem

  # Create a PKCS#12 file from the new certificate and its private key found in newreq.pem
  # and place in file cert-clt.p12
  ${OPENSSL} pkcs12 -export -in newcert.pem -inkey newreq.pem -out cert-clt.p12 -clcerts \
    -passin pass:${password} -passout pass:${password}

  # parse the PKCS#12 file just created and produce a PEM format certificate and key in cert-clt.pem
  ${OPENSSL} pkcs12 -in cert-clt.p12 -out cert-clt.pem \
   -passin pass:${password} -passout pass:${password}

  # Convert certificate from PEM format to DER format
  ${OPENSSL} x509 -inform PEM -outform DER -in cert-clt.pem -out cert-clt.der
  exit;
fi;


  echo "
[ xpclient_ext]
extendedKeyUsage = 1.3.6.1.5.5.7.3.2
[ xpserver_ext ]
extendedKeyUsage = 1.3.6.1.5.5.7.3.1
   " > xpextensions;

  #
  # Generate DH stuff...
  #
  ${OPENSSL} gendh > ${CERT_EAP_PATH}/dh
  date > ${CERT_EAP_PATH}/random

  # needed if you need to start from scratch otherwise the CA.pl -newca command doesn't copy the new
  # private key into the CA directories

  rm -rf demoCA

  echo "*******************************************************************************"
  echo "Creating self-signed private key and certificate"
  echo "When prompted override the default value for the Common Name field"
  echo "*******************************************************************************"
  echo

  # Generate a new self-signed certificate.
  # After invocation, newreq.pem will contain a private key and certificate
  # newreq.pem will be used in the next step
  ${OPENSSL} req -new -x509 -keyout newreq.pem -out newreq.pem -days ${DAYS} \
   -passin pass:${password} -passout pass:${password}


  echo "*******************************************************************************"
  echo "Creating a new CA hierarchy (used later by the "ca" command) with the certificate"
  echo "and private key created in the last step"
  echo "*******************************************************************************"
  echo

  #CA_pl=`which ${CA_pl}`;
  if [ -f ${CA_pl} ] ; then
    echo "newreq.pem" | ${CA_pl} -newca > /dev/null
  else 
    echo "Can't find CA.pl";
    exit;
  fi;

  echo "*******************************************************************************"
  echo "Creating ROOT CA"
  echo "*******************************************************************************"
  echo

  # Create a PKCS#12 file, using the previously created CA certificate/key
  # The certificate in demoCA/cacert.pem is the same as in newreq.pem. Instead of
  # using "-in demoCA/cacert.pem" we could have used "-in newreq.pem" and then omitted
  # the "-inkey newreq.pem" because newreq.pem contains both the private key and certificate
  ${OPENSSL} pkcs12 -export -in demoCA/cacert.pem -inkey newreq.pem -out root.p12 -cacerts \
   -passin pass:${password} -passout pass:${password}

  # parse the PKCS#12 file just created and produce a PEM format certificate and key in root.pem
  ${OPENSSL} pkcs12 -in root.p12 -out root.pem \
    -passin pass:${password} -passout pass:${password}

  # Convert root certificate from PEM format to DER format
  ${OPENSSL} x509 -inform PEM -outform DER -in root.pem -out root.der

echo "*******************************************************************************"
echo "Creating server private key and certificate"
echo "When prompted enter the server name in the Common Name field."
echo "*******************************************************************************"
echo

# Request a new PKCS#10 certificate.
# First, newreq.pem will be overwritten with the new certificate request
${OPENSSL} req -new -keyout newreq.pem -out newreq.pem -days ${DAYS} \
-passin pass:${password} -passout pass:${password}

# Sign the certificate request. The policy is defined in the ${OPENSSL}.cnf file.
# The request generated in the previous step is specified with the -infiles option and
# the output is in newcert.pem
# The -extensions option is necessary to add the OID for the extended key for server authentication

${OPENSSL} ca -policy policy_anything -out newcert.pem -passin pass:${password} -key ${password} \
-extensions xpserver_ext -extfile xpextensions -infiles newreq.pem

# Create a PKCS#12 file from the new certificate and its private key found in newreq.pem
# and place in file cert-srv.p12
${OPENSSL} pkcs12 -export -in newcert.pem -inkey newreq.pem -out cert-srv.p12 -clcerts \
-passin pass:${password} -passout pass:${password}

# parse the PKCS#12 file just created and produce a PEM format certificate and key in cert-srv.pem
${OPENSSL} pkcs12 -in cert-srv.p12 -out cert-srv.pem -passin pass:${password} -passout pass:${password}

# Convert certificate from PEM format to DER format
${OPENSSL} x509 -inform PEM -outform DER -in cert-srv.pem -out cert-srv.der

#clean up
rm newcert.pem newreq.pem

}



#Cert functions
case ${CERT_TYPE} in
        ssh) 
              ssh_key $2;
                ;;
        apache)
              apache_cert;
                ;;
        wexpress_oplata)
              wexpress_oplata;
                ;;
        info)
              cert_info $2;
                ;;
        postfix)
              postfix_cert;
                ;;
        easysoft)
              easysoft_cert $2;
                ;;
        eap)
              eap_cert; 
                ;;
esac;



echo "${CERT_TYPE} Done...";

