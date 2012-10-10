#!/bin/bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BF_CRYPT_ALGO=aes-256-cbc
BF_CRYPT_KEY_FILE="$BASEDIR/keyfile"
