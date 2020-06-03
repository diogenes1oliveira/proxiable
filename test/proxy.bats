#!/usr/bin/env bats

DOCKER_COMPOSE="${DOCKER_COMPOSE:-docker-compose}"
IMAGE="${IMAGE:-diogenes1oliveira/proxiable}"
CONTAINER_NAME="proxiable-$(uuidgen)"

REPLACEMENTS=(
  nginx.org/nginx.png
  www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png
)

function setup {
  export TMPDIR="$(mktemp -d)"
  export PROXIABLE_SITES_LOCATION="${TMPDIR}"
  export CACERT="${TMPDIR}/ca.pem"
  setup-replacements
  startup
}

function teardown {
  rm -rf "${TMPDIR}"
  ${DOCKER_COMPOSE} kill 2> /dev/null > /dev/null
  ${DOCKER_COMPOSE} rm -f -v 2> /dev/null > /dev/null
}

function setup-replacements {
  for r in "${REPLACEMENTS[@]}"; do
    checksum="$( echo -n "${r}" | sha256sum | awk '{ print $1 }' )"
    mkdir -p "${TMPDIR}/$( dirname "${r}" )"
    echo -n "${checksum}" > "${TMPDIR}/${r}"
  done
}

function startup {
  ${DOCKER_COMPOSE} up -d 2> /dev/null > /dev/null
  export http_proxy="http://localhost:8000/"
  export https_proxy="${http_proxy}"
  export HTTP_PROXY="${http_proxy}"
  export HTTPS_PROXY="${http_proxy}"

  i=0

  while ! curl --cacert "${CACERT}" -fSL 'https://www.google.com' > /dev/null; do
    i="$((i+1))"
    if [ "${i}" -gt 5 ]; then
      echo "Failed getting Google through the proxy" >&2
      return 1
    fi
    sleep 1
  done
}

@test 'HTTP requests are being replaced' {
  for r in "${REPLACEMENTS[@]}"; do
    checksum="$( echo -n "${r}" | sha256sum | awk '{ print $1 }' )"
    if ! ( curl --cacert "${CACERT}" -qvL "https://${r}" | grep -s "${checksum}" ) ; then
      echo "failed getting ${r}" >&2
      curl -v "http://${r}" >&2
      return 1
    fi
  done
}
