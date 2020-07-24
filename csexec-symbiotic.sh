#!/bin/bash

# USAGE:
#
# 1) Build the source with gllvm and CFLAGS internally used by Symbiotic.
# 2) CSEXEC_WRAP_DONT_USE_LD=1 \
#    CSEXEC_WRAP_CMD=$'csexec-symbiotic.sh\a--prp=memsafety' make check
# 3) Wait for some time.
# 4) ...
# 5) Profit!

set -e

SYMBIOTIC_ARGS="$1"
BINARY="$2"
BINARY_ARGV="$3"

i=4
while [ $i -le $# ]; do
  BINARY_ARGV="$BINARY_ARGV,${!i}"
  ((i++))
done

get-bc "$BINARY" 1> /dev/tty 2>&1
echo "Executing $SYMBIOTIC_ARGS --argv='$BINARY_ARGV' $BINARY.bc" 1> /dev/tty 2>&1
symbiotic $SYMBIOTIC_ARGS --argv="'$BINARY_ARGV'" "$BINARY.bc" 1> /dev/tty 2>&1
