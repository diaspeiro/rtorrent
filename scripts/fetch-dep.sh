#!/bin/sh
# Fetch, verify (sha256), and extract a dependency declared in
# .github/dependency-versions.json (bind-mounted at $DV_JSON, default /build/dv.json).
#
# Usage: fetch-dep <name> [dest-dir]   (dest-dir defaults to <name>)
set -eu

name=$1
dest=${2:-$1}
manifest=${DV_JSON:-/build/dv.json}

url=$(jq -er --arg n "$name" '.[$n].url' "$manifest")
sha=$(jq -er --arg n "$name" '.[$n].sha256' "$manifest")
ver=$(jq -r --arg n "$name" '.[$n].version' "$manifest")

echo "Fetching ${name} ${ver} from ${url}"
tarball="/tmp/${name}.tar.gz"
curl -fqsSL -o "${tarball}" "${url}"

if ! echo "${sha}  ${tarball}" | sha256sum -c -; then
  echo "::error::sha256 verification failed for ${name} (${url})" >&2
  exit 1
fi

mkdir -p "${dest}"
tar -xzf "${tarball}" -C "${dest}" --strip-components=1
rm -f "${tarball}"
