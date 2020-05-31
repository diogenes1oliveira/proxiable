#!/usr/bin/env bash
set -euo pipefail

# execute the scripts in '/docker-entrypoint-init.d'
if [ -d '/docker-entrypoint-init.d' ]; then
  readarray -t init_scripts < <(
    find '/docker-entrypoint-init.d' -mindepth 1 -maxdepth 1 -name '*.sh' | sort
  )
  for s in "${init_scripts[@]}"; do
    source "${s}"
  done
fi

# there are arguments and the first argument is not a flag neither
# the default command
if [ "$#" -ge 1 ] && [ "${1#-}" = "$1" ] && [ "$1" != 'mitmweb' ]; then
  exec "$@"
fi

if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
  exec mitmweb --help
fi

# remove the 'mitmweb' from the beginning, I'll prepend some flags below
shift

cmd=(
  mitmweb
    --set block_global=false
    --no-web-open-browser
    --listen-host "${PROXIABLE_PROXY_HOST}"
    --listen-port "${PROXIABLE_PROXY_PORT}"
    --web-host "${PROXIABLE_WEBUI_HOST}"
    --web-port "${PROXIABLE_WEBUI_PORT}"
    --scripts '/app/proxiable.py'
)

# find the extra scripts in ${PROXIABLE_SCRIPTS_LOCATION}
if [ -d "${PROXIABLE_SCRIPTS_LOCATION}" ]; then
  readarray -t extra_scripts < <(
    find "${PROXIABLE_SCRIPTS_LOCATION}" -mindepth 1 -maxdepth 1 -name '*.py'
  )
  for s in "${extra_scripts[@]}"; do
    cmd+=( --scripts "${s}" )
  done
fi

if [ -f '/var/proxiable/ca.pem' ] && ! [ -e '/root/.mitmproxy/mitmproxy-ca.pem' ]; then
  ln -s '/var/proxiable/ca.pem' '/root/.mitmproxy/mitmproxy-ca.pem'
fi

cmd+=( "$@" )

exec "${cmd[@]}"
