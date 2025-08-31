#!/usr/bin/env bash

set -euo pipefail

export DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-noninteractive}

apt_install() {
  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y "$@"
  else
    apt-get update -y
    apt-get install -y "$@"
  fi
}

apt_install pkg-config clang-format cppcheck gcovr python3 python3-pip python3-venv git

python3 -m pip install --upgrade --user pip
python3 -m pip install --user conan

# Print versions for traceability
conan --version
pkg-config --version
gcovr --version || true
cppcheck --version || true
clang-format --version || true
