#!/bin/sh
openssl genrsa -des3 -out ca.key 2048 # generate a private key for your CA remember passphrase
openssl req -x509 -new -nodes -key ca.key -sha256 -days 1825 -out ca.crt # generate a root certificate
openssl rsa -in ca.key -out ca.unencrypted.key -passin pass:rado
kubectl create secret tls ca-key-pair --cert=ca.crt --key=ca.unencrypted.key