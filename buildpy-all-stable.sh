#!/bin/bash
# Do stuff
set -eu
# "3.6.15"
VERSIONS=("3.8.17" "3.9.17" "3.10.12" "3.11.4" "3.7.17")
for V in ${VERSIONS[@]}; do
	./get-and-build.sh "$V"
done