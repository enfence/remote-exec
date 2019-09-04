#!/bin/bash
if ! /usr/local/bin/is-local-ssh; then
    exit 0
else
    exit 1
fi
