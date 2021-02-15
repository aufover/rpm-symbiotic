#!/usr/bin/bash

usage() {
  cat << EOF
USAGE: $0 -s SYMBIOTIC_ARGS ARGV
1) Build the source with gllvm and CFLAGS internally used by Symbiotic and
   LDFLAGS='-Wl,--dynamic-linker=/usr/bin/csexec-loader'.
2) CSEXEC_WRAP_CMD=$'--skip-ld-linux\acsexec-symbiotic\a-s\a--prp=memsafety' make check
3) Wait for some time.
4) ...
5) Profit!
EOF
}

[[ $# -eq 0 ]] && usage && exit 1

while getopts "s:h" opt; do
  case "$opt" in
    s)
      SYMBIOTIC=($OPTARG)
      ;;
    h)
      usage && exit 0
      ;;
    *)
      usage && exit 1
      ;;
  esac
done

shift $((OPTIND - 1))
ARGV=("$@")

# Run!
get-bc "${ARGV[0]}" 1> /dev/tty 2>&1
symbiotic "${SYMBIOTIC[@]}" --argv="'${ARGV[*]}'" "${ARGV[0]}.bc" 1> /dev/tty 2>&1

# Continue
exec $(csexec --print-ld-exec-cmd) "${ARGV[@]}"
