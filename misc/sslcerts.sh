#!/bin/sh
# ABILLS Certificat creator

SSL=/usr/local/openssl
export PATH=/usr/src/crypto/openssl/apps/:${SSL}/bin/:${SSL}/ssl/misc:${PATH}
export LD_LIBRARY_PATH=${SSL}/lib
CA_pl=CA.pl;

hostname=`hostname`;
password=whatever;
days=730;
DATE=`date`;
CERT_TYPE=$1;
CERT_USER="";
VERSION=0.2;

if [ w$1 = w ] ; then
  echo "Create SSL Certs and SSH keys ";
  echo "sslcerts.sh [apache|eap|postfix_tls|ssh] -D";
  echo " apache        - Create apache SSL cert"
  echo " eap           - Create Server and users SSL Certs"
  echo " postfix_tls   - Create postfix TLS Certs"
  echo " info [file]   - Get info from SSL cert"
  echo " ssh [USER]    - Create SSH DSA Keys"
  echo "                USER - SSH remote user"
  echo " -D [PATH]     - Path for ssl certs"
  echo " -U [username] - Cert owner (Default: apache=www, postfix=vmail)"

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
        esac
done


if [ ! -d ${CERT_PATH} ] ; then
  mkdir ${CERT_PATH};
fi





cd ${CERT_PATH};

#SSH certs
if [ w${CERT_TYPE} = wssh ]; then
  echo "*******************************************************************************"
  echo "Creating SSH authentication Key"
  echo " Make ssh-keygen with empty password."
  echo "*******************************************************************************"
  echo

  if [ w${CERT_TYPE} = w ]; then
    id_dsa_file=id_dsa;
  else
    id_dsa_file=id_dsa.$2;
  fi;
  
  USER=$2; 
   
  ssh-keygen -t dsa -C "ABillS remote machine manage key (${DATE})" -f "${CERT_PATH}${id_dsa_file}"

  echo -n "Upload file to remote host (y/n):"
  read UPLOAD
  if [ w${UPLOAD} = wy ]; then
    echo -n "Enter host: "
    read HOST
    
    echo "Make upload to: ${HOST} "
    ssh ${USER}@${HOST} "mkdir ~/.ssh"
    scp ${CERT_PATH}${id_dsa_file}.pub ${USER}@${HOST}:~/.ssh/authorized_keys
  fi;


  echo 
  echo "Copy ${CERT_PATH}${id_dsa_file}.pub to REMOTE_HOST User home dir (/home/${USER}/.ssh/authorized_keys) "
  echo 

#Apache Certs
else if [ w${CERT_TYPE} = wapache ]; then

  echo "*******************************************************************************"
  echo "Creating Apache server private key and certificate"
  echo "When prompted enter the server name in the Common Name field."
  echo "*******************************************************************************"
  echo
  if [ w${CERT_USER} = w ];  then
    APACHE_USER=www;
  else 
    APACHE_USER=${CERT_USER};
  fi;
  cd ${CERT_PATH};

  openssl genrsa -des3 -passout pass:${password} -out server.key 1024 
  
  openssl req -new -key server.key -out server.csr \
  -passin pass:${password} -passout pass:${password}
  
  openssl x509 -req -days ${days} -in server.csr -signkey server.key -out server.crt \
   -passin pass:${password}

  chmod u=r,go= ${CERT_PATH}/server.key
  chmod u=r,go= ${CERT_PATH}/server.crt
  chown ${APACHE_USER} server.crt server.csr

  cp server.key server.key.org

  openssl rsa -in server.key.org -out server.key \
   -passin pass:${password} -passout pass:${password}

  #Cert info
  openssl x509 -in server.crt -noout -subject

  chmod 400 server.key


else if [ w${CERT_TYPE} = weap ]; then
  echo "*******************************************************************************"
  echo "Make RADIUS EAP"
  echo "*******************************************************************************"

  CERT_EAP_PATH=${CERT_PATH}/eap
  if [ ! -f ${CERT_EAP_PATH} ] ; then
    mkdir ${CERT_EAP_PATH};
  fi

  cd ${CERT_EAP_PATH}


  if [ w$2 = wclient ]; then
  echo "*******************************************************************************"
  echo "Creating client private key and certificate"
  echo "When prompted enter the client name in the Common Name field. This is the same"
  echo " used as the Username in FreeRADIUS"
  echo "*******************************************************************************"
  echo

  # Request a new PKCS#10 certificate.
  # First, newreq.pem will be overwritten with the new certificate request
  openssl req -new -keyout newreq.pem -out newreq.pem -days ${days} \
   -passin pass:${password} -passout pass:${password}


  # Sign the certificate request. The policy is defined in the openssl.cnf file.
  # The request generated in the previous step is specified with the -infiles option and
  # the output is in newcert.pem
  # The -extensions option is necessary to add the OID for the extended key for client authentication
  openssl ca -policy policy_anything -out newcert.pem -passin pass:${password} \
    -key ${password} -extensions xpclient_ext -extfile xpextensions \
    -infiles newreq.pem

  # Create a PKCS#12 file from the new certificate and its private key found in newreq.pem
  # and place in file cert-clt.p12
  openssl pkcs12 -export -in newcert.pem -inkey newreq.pem -out cert-clt.p12 -clcerts \
    -passin pass:${password} -passout pass:${password}

  # parse the PKCS#12 file just created and produce a PEM format certificate and key in cert-clt.pem
  openssl pkcs12 -in cert-clt.p12 -out cert-clt.pem \
   -passin pass:${password} -passout pass:${password}

  # Convert certificate from PEM format to DER format
  openssl x509 -inform PEM -outform DER -in cert-clt.pem -out cert-clt.der

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
  openssl gendh > ${CERT_EAP_PATH}/dh
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
  openssl req -new -x509 -keyout newreq.pem -out newreq.pem -days ${days} \
   -passin pass:${password} -passout pass:${password}


  echo "*******************************************************************************"
  echo "Creating a new CA hierarchy (used later by the "ca" command) with the certificate"
  echo "and private key created in the last step"
  echo "*******************************************************************************"
  echo

  CA_pl=`which ${CA_pl}`;
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
  openssl pkcs12 -export -in demoCA/cacert.pem -inkey newreq.pem -out root.p12 -cacerts \
   -passin pass:${password} -passout pass:${password}

  # parse the PKCS#12 file just created and produce a PEM format certificate and key in root.pem
  openssl pkcs12 -in root.p12 -out root.pem \
    -passin pass:${password} -passout pass:${password}

  # Convert root certificate from PEM format to DER format
  openssl x509 -inform PEM -outform DER -in root.pem -out root.der

echo "*******************************************************************************"
echo "Creating server private key and certificate"
echo "When prompted enter the server name in the Common Name field."
echo "*******************************************************************************"
echo


# Request a new PKCS#10 certificate.
# First, newreq.pem will be overwritten with the new certificate request
openssl req -new -keyout newreq.pem -out newreq.pem -days ${days} \
-passin pass:${password} -passout pass:${password}


# Sign the certificate request. The policy is defined in the openssl.cnf file.
# The request generated in the previous step is specified with the -infiles option and
# the output is in newcert.pem
# The -extensions option is necessary to add the OID for the extended key for server authentication


openssl ca -policy policy_anything -out newcert.pem -passin pass:${password} -key ${password} \
-extensions xpserver_ext -extfile xpextensions -infiles newreq.pem


# Create a PKCS#12 file from the new certificate and its private key found in newreq.pem
# and place in file cert-srv.p12
openssl pkcs12 -export -in newcert.pem -inkey newreq.pem -out cert-srv.p12 -clcerts \
-passin pass:${password} -passout pass:${password}


# parse the PKCS#12 file just created and produce a PEM format certificate and key in cert-srv.pem
openssl pkcs12 -in cert-srv.p12 -out cert-srv.pem -passin pass:${password} -passout pass:${password}


# Convert certificate from PEM format to DER format
openssl x509 -inform PEM -outform DER -in cert-srv.pem -out cert-srv.der


#clean up
rm newcert.pem newreq.pem


else if [ w${CERT_TYPE} = wpostfix_tls ]; then
  echo "******************************************************************************"
  echo "Make POSTFIX TLS sertificats"
  echo "******************************************************************************"

  cd ${CERT_PATH};

  openssl req -new -x509 -nodes -out smtpd.pem -keyout smtpd.pem -days ${days} \
   -passin pass:${password} -passout pass:${password}

else if [ w${CERT_TYPE} = winfo ]; then

  echo "******************************************************************************"
  echo "Cert info $2"
  echo "******************************************************************************"
  FILENAME=$2; 
  if [ w$FILENAME = w ] ; then 
    echo "Select Cert file";
    exit;
  fi;

  openssl x509 -in ${FILENAME} -noout -subject
   


fi;
fi;
fi;
fi;
fi;

echo "${CERT_TYPE} Done...";

