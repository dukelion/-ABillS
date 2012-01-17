#!/bin/sh
# make deamon accounts
# Make vmail user account
#Make clamav user account

if [ w$1 = w ]; then 
  echo "Make accounts";
  echo ""
  echo "# mk_account.sh TYPE OS"
  echo "TYPE - Account type"
  echo "  Clamav"
  echo "  ADD_VMAIL_USER"
  echo "OS   - FREEBSD (default), LINUX"
  echo "DEBUG"
  echo ""

fi;

#Add Clamav user
if [ wClamav = w$1 ]; then
  if [ wLINUX = w$2 ]; then
    GROUP=clamav;
    USER=clamav;
    if /bin/id "${GROUP}" 2>/dev/null; then
      echo "Group Exist";
    else
      /usr/sbin/groupadd -g ${GID} clamav
    fi
    /usr/sbin/useradd -c "Clam Antivirus" -d /nonexistent -s /sbin/nologin -u ${USER} -g ${GID} ${USER}
  fi
  exit;
fi

if [ -x /usr/sbin/nologin ]; then
        NOLOGIN=/usr/sbin/nologin
else
        NOLOGIN=/sbin/nologin
fi

#Add Vmail user to passwd file
if [ x"$1" = xADD_VMAIL_USER ]; then
   USER=vmail
   USER_ID=1005
   GROUP=vmail
   GID=1005
#Linux 

  if [ x"$2" = xLINUX ]; then
    if /bin/id "${GROUP}" 2>/dev/null; then
       echo "Group Exist";
    else
      /usr/sbin/groupadd maildrop
      /usr/sbin/groupadd -g ${GID} ${GROUP}
    fi;

    /usr/sbin/useradd -c "VMAIL" -d /nonexistent -s /sbin/nologin -u ${USER_ID} -g ${GID} ${USER}

  else  

#FreeBSD Section
        if /usr/sbin/pw groupshow "${GROUP}" 2>/dev/null; then
                echo "You already have a group \"${GROUP}\", so I will use it."
        else
                if /usr/sbin/pw groupadd ${GROUP} -g ${GID}; then
                        echo "Added group \"${GROUP}\"."
                else
                        echo "Adding group \"${GROUP}\" failed..."
                        echo "Please create it, and try again."
                        exit 1
                fi
        fi


        if /usr/sbin/pw user show "${USER}" 2>/dev/null; then
                echo "You already have a user \"${USER}\", so I will use it."
        else
                if /usr/sbin/pw useradd ${USER} -u ${USER_ID} -g ${GROUP} -h - -d /var/spool/virtual/ -s ${NOLOGIN} -c "vMail System"; then
                        echo "Added user \"${USER}\"."
                else
                        echo "Adding user \"${USER}\" failed..."
                        echo "Please create it, and try again."
                        exit 1
                fi
        fi
   fi;

fi;


