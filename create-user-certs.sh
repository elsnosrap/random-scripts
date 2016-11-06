#!/bin/bash

#
# INPUT VALIDATION
#

# Verify user supplied a user name
if [[ -z "$1" ]]; then
	echo "Please supply a user name"
	exit;
fi



#
# VARIABLES
#

# The password used for keystore
KEYSTORE_PASSWORD="passw0rd"

# The Keystore file name
KEYSTORE_FILE="server.jks"

# Distinguished name of certificate
DN="OU=Lotus,O=IBM,L=Littleton,S=Massachusettes,C=US"

# Server's Common Name
SERVER_COMMON_NAME="TPMobile"


#
# GENERATE KEYSTORE AND USER CERT
#

# Only create server keystore if it doesn't already exist
if [[ ! -e $KEYSTORE_FILE ]]; then
	echo "--- Generating keypair for server certificate"
	keytool -genkeypair -alias servercert -keyalg RSA -dname "CN=$SERVER_COMMON_NAME,$DN" -keypass $KEYSTORE_PASSWORD -keystore $KEYSTORE_FILE -storepass $KEYSTORE_PASSWORD
fi

echo "--- Generating keypair for user '$1'"
keytool -genkeypair -alias "$1" -keystore "$1.p12" -storetype pkcs12 -keyalg RSA -dname "CN=$1,$DN" -keypass $KEYSTORE_PASSWORD -storepass $KEYSTORE_PASSWORD

echo "--- Exporting certificate for user '$1'"
keytool -exportcert -alias "$1" -file "$1.cer" -keystore "$1.p12" -storetype pkcs12 -storepass $KEYSTORE_PASSWORD

echo "--- Importing certificate into keystore"
keytool -importcert -keystore $KEYSTORE_FILE -alias "$1" -file "$1.cer" -v -trustcacerts -noprompt -storepass $KEYSTORE_PASSWORD

echo "--- Listing keystore"
keytool -list -v -keystore server.jks -storepass $KEYSTORE_PASSWORD
