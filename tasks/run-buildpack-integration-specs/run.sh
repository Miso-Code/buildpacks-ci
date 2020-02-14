#!/bin/bash -l
set -o errexit
set -o nounset
set -o pipefail

"./cf-space/login"

 if [[ -d "uncached-buildpack" ]]; then
   UNCACHED_BUILDPACK_FILE="$(realpath "$(find ./uncached-buildpack -name "*.zip")")"
   export UNCACHED_BUILDPACK_FILE
 fi

if [[ -d "cached-buildpack" ]]; then
  CACHED_BUILDPACK_FILE="$(realpath "$(find ./cached-buildpack -name "*.zip")")"
  export CACHED_BUILDPACK_FILE
fi

cd buildpack

if [[ -z ${SKIP_DOCKER_START:-} ]]; then
  echo "Start Docker"
  #shellcheck source=../../scripts/start-docker
  source ../buildpacks-ci/scripts/start-docker
  util::docker::start
  trap util::docker::stop EXIT
fi

./scripts/integration.sh
