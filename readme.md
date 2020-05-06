# Simple LDAP Server

This vagrant image builds the following LDAP Config....

## Use case configuration

Setup 4 teams TeamA - TeamD in LDAP and add a user in each team as follows:

- Team A: Mary Poppins - uid: mpoppins, password: passworda
- Team B: Ronan Keating - uid: rkeating, password: passwordb
- Team C: Dylan Thomas - uid: dthomas, password: passwordc
- Team D: Dawn French - uid: dfrench, password: passwordd

Requirements

- Users from TeamA will have admin access to the facebook Namespace
- Users from TeamB will have admin access to the twitter Namespace
- Users from TeamA and TeamB will have operator access to the shared Namespace
- Users from TeamC will have admin access to the shared Namespace
- Users from TeamD will have FULL VAULT ADMIN ACCESS
- LDAP is to be configured to attach to the root namespace and identities and policies used to map access to the various users

## Installation of this setup

- Prerequisites: Vagrant and Virtualbox should be installed on the host system
- Clone the repository to the host system
- Source the var.env file
- Vagrant up
- Now LDAP should be available and integrated on the vagrant box - 192.168.15.11

``` bash
mkdir LDAP_DEMO
cd LDAP_DEMO
git clone repo.git .
source var.env
vagrant up
vagrant ssh
```

[Useful LDAP Explorer for the MacOS](https://directory.apache.org/studio/download/download-macosx.html)
![image](https://user-images.githubusercontent.com/9472095/56169273-8b39bb00-5fd5-11e9-8fa5-e7a0e93cb081.png)

Lightweight Directory Access Protocol (LDAP) Directory Information Tree (DIT) can be seen in the slapd.ldif file.
![Vault LDAP Demo LDIF (1)](https://user-images.githubusercontent.com/9472095/56167790-0ba9ed00-5fd1-11e9-9669-b455c0ba44d0.png)

Check LDAP setup by running the following command on the vagrant box:

``` bash
ldapsearch -x -LLL -h localhost -D "cn=vaultuser,ou=people,dc=allthingscloud,dc=eu" -w vaultuser -b "ou=people,dc=allthingscloud,dc=eu" -s sub "(&(objectClass=inetOrgPerson)(uid=*))" memberOf
```
Output:
``` bash
dn: cn=Mary Poppins,ou=people,dc=allthingscloud,dc=eu
memberOf: cn=TeamA,ou=groups,dc=allthingscloud,dc=eu

dn: cn=Ronan Keating,ou=people,dc=allthingscloud,dc=eu
memberOf: cn=TeamB,ou=groups,dc=allthingscloud,dc=eu

dn: cn=Dylan Thomas,ou=people,dc=allthingscloud,dc=eu
memberOf: cn=TeamC,ou=groups,dc=allthingscloud,dc=eu

dn: cn=Dawn French,ou=people,dc=allthingscloud,dc=eu
memberOf: cn=TeamD,ou=groups,dc=allthingscloud,dc=eu

dn: cn=vaultuser,ou=people,dc=allthingscloud,dc=eu
memberOf: cn=vault,ou=groups,dc=allthingscloud,dc=eu

dn: cn=oktauser,ou=people,dc=allthingscloud,dc=eu
```
If the LDAP query does not return memberOf that contains the correct groups then verify that the filter is configured correctly - e.g. `(&(objectClass=inetOrgPerson)(uid=*))`

