#!/usr/bin/bash

usage() {
  /usr/bin/cat << EOF
USAGE: $0 -s SYMBIOTIC_ARGS ARGV
1) Build the source with gllvm and CFLAGS internally used by Symbiotic and
   LDFLAGS='-Wl,--dynamic-linker=/usr/bin/csexec-loader'.
2) CSEXEC_WRAP_CMD=$'--skip-ld-linux\acsexec-symbiotic\a-l\aLOG_DIR\a-s\a--prp=memsafety' make check
3) Wait for some time.
4) ...
5) Profit!
EOF
}

[[ $# -eq 0 ]] && usage && exit 1

while getopts "l:s:h" opt; do
  case "$opt" in
    l)
      LOGDIR="$OPTARG"
      ;;
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

if [ -z "$LOGDIR" ]; then
  echo "-l LOGDIR option is mandatory!"
  exit 1
fi

# Run and convert!
/usr/bin/get-bc -S -o "${ARGV[0]}-$$.bc" "${ARGV[0]}" > /dev/null || exit 1
/usr/bin/env -i /usr/bin/bash -lc 'exec "$@"' symbiotic \
  /usr/bin/symbiotic "${SYMBIOTIC[@]}" --argv="'${ARGV[*]:1}'" "${ARGV[0]}-$$.bc" \
  2> "$LOGDIR/pid-$$.err" | /usr/bin/tee "$LOGDIR/pid-$$.out" | \
  /usr/bin/symbiotic2cs > "$LOGDIR/pid-$$.out.conv"

# Continue
exec $(/usr/bin/csexec --print-ld-exec-cmd) "${ARGV[@]}"
