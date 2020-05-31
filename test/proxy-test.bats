#!/usr/bin/env bats

DOCKER_COMPOSE="${DOCKER_COMPOSE:-docker-compose}"
IMAGE="${IMAGE:-diogenes1oliveira/proxiable}"
CONTAINER_NAME="proxiable-$(uuidgen)"

REPLACEMENTS=(
  nginx.com/nginx.png
  www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png
)

function setup {
  export TMPDIR="$(mktemp -d)"
  export PROXIABLE_SITES_LOCATION="${TMPDIR}"
  setup-replacements
  startup
}

function teardown {
  rm -rf "${TMPDIR}"
  ${DOCKER_COMPOSE} kill
  ${DOCKER_COMPOSE} rm -f -v
}

function setup-replacements {
  for r in "${REPLACEMENTS[@]}"; do
    checksum="$( echo -n "${r}" | sha256sum | awk '{ print $1 }' )"
    mkdir -p "${TMPDIR}/$( dirname "${r}" )"
    echo -n "${checksum}" > "${TMPDIR}/${r}"
  done

  find "${TMPDIR}" -type f >&3
}

function startup {
  ${DOCKER_COMPOSE} up -d
  export http_proxy="http://localhost:8000/"
  export https_proxy="${http_proxy}"
  export HTTP_PROXY="${http_proxy}"
  export HTTPS_PROXY="${http_proxy}"

  i=0

  while ! curl -fSL 'https://www.google.com'; do
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
    if ! ( curl "http://${r}" | grep "${checksum}" ) ; then
      echo "failed getting ${r}" >&2
      curl -v "http://${r}" >&2
      return 1
    fi
  done
}
