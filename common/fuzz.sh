#!/bin/sh

if [ -z "$1" ]; then
    echo "Usage: $0 <file>" > /dev/stderr
    exit 1
fi

if [ ! -s "$1" ]; then
    echo "$1: File is empty or doesn't exist" > /dev/stderr
    exit 1
fi

MAX=1000
I=0

while [ $I -le $MAX ]; do
    echo "Run: cat $1 | zzuf -s $I -r 0.0001 | ./parse -f - 1>/dev/null"
    cat $1 | zzuf -s $I -r 0.0001 | ./parse -f - 1>/dev/null
    [ $? -ne 0 ] && exit 1
    I=$((I+1))
done
