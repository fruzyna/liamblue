#!/bin/bash
set -ouex pipefail

mkdir -p /tmp/scripts/helpers
install -Dm0755 /ctx/utils/ghcurl /tmp/scripts/helpers/ghcurl
export PATH="/tmp/scripts/helpers:$PATH"

/ctx/00-metadata.sh

/ctx/01-akmods.sh

/ctx/02-packages.sh
