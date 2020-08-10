#!/usr/bin/bash

usage() {
  cat << EOF
USAGE:
1) Build the source with gllvm and CFLAGS internally used by Symbiotic and
   LDFLAGS='-Wl,--dynamic-linker=/usr/bin/csexec-loader'.
2) CSEXEC_WRAP_CMD=$'csexec-symbiotic.sh\a--prp=memsafety' make check
3) Wait for some time.
4) ...
5) Profit!
EOF
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

if [ ! -x /usr/bin/get-bc ]; then
  echo "gllvm is not installed!" > /dev/tty
  exit 42
fi

i=1
while [ ! -e ${!i} ]; do
  SYMBIOTIC_ARGS[$i - 1]="${!i}"
  ((i++))
done

# Skip LD_LINUX_SO
((i++))

# Skip --argv0
if [ ${!i} = "--argv0" ]; then
  ((i += 2))
fi

BINARY="${!i}"
((i++))

BINARY_ARGV="${!i}"
((i++))

while [ $i -le $# ]; do
  BINARY_ARGV="$BINARY_ARGV,${!i}"
  ((i++))
done

get-bc "$BINARY" 1> /dev/tty 2>&1
echo "Executing 'symbiotic${SYMBIOTIC_ARGS[*]} --argv='$BINARY_ARGV' $BINARY.bc'" 1> /dev/tty 2>&1
symbiotic "${SYMBIOTIC_ARGS[@]}" --argv="'$BINARY_ARGV'" "$BINARY.bc" 1> /dev/tty 2>&1

i=1
while [[ ! "${!i}" =~ "ld-linux" ]]; do
    ((i++))
done

ARGS=( "$@" )
exec "${ARGS[@]:i-1}"
