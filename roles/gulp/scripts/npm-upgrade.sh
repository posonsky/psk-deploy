#!/bin/sh
set -e
set -x

for package in $(npm -g outdated --parseable | cut -d: -f2)
do
    npm -g install "$package"
done
