#!/usr/bin/env bash

# Usage: run_with_conan.sh "<command to run using Conan env>"
set -euo pipefail
if [[ ! -f build/conan/conanbuild.sh ]]; then
  echo "Conan env not found (build/conan/conanbuild.sh). Run conan_setup.sh first." >&2
  exit 1
fi
# shellcheck disable=SC1091
source build/conan/conanbuild.sh
eval "$@"
