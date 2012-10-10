#!/bin/bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$BASEDIR/config.sh"

function bf-ls-first {
    ls $@ | sort | head -1
    return $?
}

function bf-ls-last {
    ls $@ | sort | tail -1
    return $?
}

function bf-ls-count {
    ls $@ | wc -l
    return $?
}

function bf-date {
    if [ $# -ne 1 ]; then
        echo "USAGE: $0 PREFIX" >&2
        return 1
    fi

    echo "$1.$(date +%Y%m%d_%H%M%S)"
    return 0
}

function bf-rotate {
    if [ $# -ne 2 ]; then
        echo "USAGE: $0 COUNT PREFIX" >&2
        return 1
    fi

    max_count="$1"
    prefix="$2"

    count="$(bf-ls-count $prefix)"
    while [ $(($count + 1)) -gt $max_count ]; do
        rm -rf "$(bf-ls-first $prefix.)"
        count="$(bf-ls-count $prefix)"
    done

    dir="$(bf-date $prefix)"
    mkdir "$dir"

    return $?
}

function bf-archive {
    if [ -e snapshot ]; then
        prefix=incr
    else
        prefix=full
    fi
    filename="$(bf-date $prefix).tar"
    if [[ "$@" =~ "--gzip" ]]; then
        filename="$filename.gz"
    fi
    filename="$filename.enc"
    tar --create \
        --ignore-failed-read \
        --preserve-permissions \
        --recursion \
        --sparse \
        --totals \
        --listed-incremental=snapshot \
        $@ | \
    openssl \
        enc -e -$BF_CRYPT_ALGO \
        -salt \
        -kfile $BF_CRYPT_KEY_FILE \
        > $filename.part
    mv $filename.part $filename
}

function bf-archive-1level {
    if [ -e snapshot ]; then
        cp snapshot level1.snapshot
    fi
    bf-archive $@
    if [ -e level1.snapshot ]; then
        mv level1.snapshot snapshot
    fi
}

function bf-restore {
    for arc in $(ls $1/*.enc); do
        openssl enc -d -$BF_CRYPT_ALGO \
            -kfile $BF_CRYPT_KEY_FILE \
            -in $arc | \
        tar --extract \
            --totals \
            --ignore-failed-read \
            --preserve-permissions \
            --listed-incremental=/dev/null
    done
}

function bf-restore-1level {
    arc1="$(ls $1/full.*.enc)"
    arc2="$(bf-ls-last $1/incr.*.enc)"
    for arc in "$arc1" "$arc2"; do
        openssl enc -d -$BF_CRYPT_ALGO \
            -kfile $BF_CRYPT_KEY_FILE \
            -in $arc | \
        tar --extract \
            --totals \
            --ignore-failed-read \
            --preserve-permissions \
            --listed-incremental=/dev/null
    done
}

function bf-list-archive {
    openssl enc -d -$BF_CRYPT_ALGO \
        -kfile $BF_CRYPT_KEY_FILE \
        -in $1 | \
    tar --list \
        --listed-incremental=/dev/null
}
