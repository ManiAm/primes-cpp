#!/usr/bin/env bash

set -euo pipefail
conan profile detect --force
conan install . --output-folder=build/conan --build=missing
