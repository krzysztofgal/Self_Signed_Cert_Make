#!/bin/sh

if [ "$1" != "" ]; then
    sudo cp $1 /etc/ca-certificates/trust-source/anchors/ &&
    sudo trust extract-compat
else
    echo "Root CA certificate file name is required"
fi