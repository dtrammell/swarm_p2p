#!/bin/bash

openssl genrsa -out priv.pem 4096
openssl req -new -x509 -key priv.pem -out cert.pem
