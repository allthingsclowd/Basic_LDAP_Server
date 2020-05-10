#!/bin/bash

installnoninteractive(){
  bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -q -y $*"
}

addhost() {
    HOSTNAME=$1
    HOSTS_LINE="$IP\t$HOSTNAME"
    if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
        then
            echo "$HOSTNAME already exists : $(grep $HOSTNAME $ETC_HOSTS)"
        else
            echo "Adding $HOSTNAME to your $ETC_HOSTS";
            "echo '$HOSTS_LINE' >> /etc/hosts";

            if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
                then
                    echo "$HOSTNAME was added succesfully \n $(grep $HOSTNAME /etc/hosts)";
                else
                    echo "Failed to Add $HOSTNAME, Try again!";
            fi
    fi
}

reset_crc_file_stamp() {
    # Tidy CRCs after manual editing
    grep -v '^#' $1 > /tmp/cleaned.ldif
    NEWCRC=`crc32 /tmp/cleaned.ldif`
    sed -i '/# CRC32/c\# CRC32 '${NEWCRC} $1

}

install_and_configure_openldap () {

    echo "Starting OpenLDAP installation"
    apt-get update
    # Idempotent hack
    ldapsearch -x -LLL -h localhost -D cn=admin,dc=eu -w ${LDAPPASSWORD} -b "ou=groups,dc=simpsons,dc=eu"
    LDAP_CONFIGURED=$?
    if [[ ${LDAP_CONFIGURED} -ne 0 ]]; then
        echo "Installing base packages"
        installnoninteractive slapd ldap-utils libarchive-zip-perl

        # Reset passwords to enable DIT configuration following silent installation
        echo "Setting up default passwords"
        HASHEDPASSWORD=`sudo slappasswd -s ${LDAPPASSWORD}`
        sed -i '/olcRootPW/c\olcRootPW: '${HASHEDPASSWORD}  /etc/ldap/slapd.d/cn\=config/olcDatabase={1}mdb.ldif
        echo 'olcRootDN: cn=admin,cn=config' >> /etc/ldap/slapd.d/cn\=config/olcDatabase={0}config.ldif
        echo 'olcRootPW: '${HASHEDPASSWORD} >> /etc/ldap/slapd.d/cn\=config/olcDatabase={0}config.ldif

        # Reset CRC Timestamp
        reset_crc_file_stamp /etc/ldap/slapd.d/cn\=config/olcDatabase={1}mdb.ldif
        reset_crc_file_stamp /etc/ldap/slapd.d/cn\=config/olcDatabase={0}config.ldif

        # Restart LDAP Server Service
        systemctl restart slapd.service

        # Enbale LDAP logging
        ldapmodify -w ${LDAPPASSWORD} -D cn=admin,cn=config -f /usr/local/bootstrap/conf/ldap/enableLDAPlogs.ldif

        # Enable memberOf overlay - easily and efficiently do queries that enables you to see which users are part of which groups 
        echo "Enabling LDAP memberOf Overlay"
        ldapadd -w ${LDAPPASSWORD} -D cn=admin,cn=config -f /usr/local/bootstrap/conf/ldap/memberOfmodule.ldif
        ldapadd -w ${LDAPPASSWORD} -D cn=admin,cn=config -f /usr/local/bootstrap/conf/ldap/memberOfconfig.ldif
        ldapmodify -w ${LDAPPASSWORD} -D cn=admin,cn=config -f /usr/local/bootstrap/conf/ldap/refintmodule.ldif
        ldapadd -w ${LDAPPASSWORD} -D cn=admin,cn=config -f /usr/local/bootstrap/conf/ldap/refintconfig.ldif

        # Configure LDAP users and groups
        echo "Loading new details into LDAP server - users & groups"
        ldapadd -x -D cn=admin,dc=eu -w ${LDAPPASSWORD} -f /usr/local/bootstrap/conf/ldap/slapd.ldif

    else

        echo "Nothing to do OpenLDAP already installed and configured!"

    fi

    # Check LDAP server is listening on port 389
    nc localhost 389 -v -z

    # Review the LDIF
    echo "Dumping the DIT to screen"
    slapcat

    # Verify Access
    echo "Sample Queries"
    ldapwhoami -vvv -h localhost -p 389 -D "cn=Marge Simpson,ou=people,dc=simpsons,dc=eu" -x -w marge
    ldapsearch -x -LLL -h localhost -D "cn=Marge Simpson,ou=people,dc=simpsons,dc=eu" -w marge -b "cn=Marge Simpson,ou=people,dc=simpsons,dc=eu" -s sub "(objectClass=inetOrgPerson)" carlicense
    ldapsearch -x -LLL -h localhost -D "cn=Moe Szyslak,ou=people,dc=simpsons,dc=eu" -w moe -b "cn=Moe Szyslak,ou=people,dc=simpsons,dc=eu" -s sub "(objectClass=inetOrgPerson)" carlicense
    ldapsearch -x -LLL -h localhost -D "cn=Moe Szyslak,ou=people,dc=simpsons,dc=eu" -w moe -b "ou=people,dc=simpsons,dc=eu" -s sub "(objectClass=inetOrgPerson)"
    ldapsearch -x -LLL -h localhost -D "cn=Moe Szyslak,ou=people,dc=simpsons,dc=eu" -w moe -b "ou=people,dc=simpsons,dc=eu" -s sub "(&(objectClass=inetOrgPerson)(uid=*))"
    ldapsearch -x -LLL -h localhost -D "cn=Moe Szyslak,ou=people,dc=simpsons,dc=eu" -w moe -b "ou=people,dc=simpsons,dc=eu" -s sub "(&(objectClass=inetOrgPerson)(uid=*))" memberOf
    ldapsearch -x -LLL -h localhost -D "cn=Moe Szyslak,ou=people,dc=simpsons,dc=eu" -w moe -b "ou=people,dc=simpsons,dc=eu" -s sub "(&(objectClass=inetOrgPerson)(uid=homer))" memberOf

}

setup_environment() {
    
    set -x
    ETC_HOSTS=/etc/hosts

    # Default IP for hostname
    IP="192.168.15.11"

    # Hostname to add/remove.
    HOSTNAME="allthingscloud.eu"

    addhost $HOSTNAME

    export LDAPPASSWORD=bananas

}

setup_environment
install_and_configure_openldap

