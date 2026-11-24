#!/usr/bin/env bash
set -euo pipefail

input=${1:?Expected input file}
output=${2:?Expected received file}

hash_file() {
  if command -v sha256sum >/dev/null; then
    sha256sum < "$1"
  else
    shasum -a 256 < "$1"
  fi
}

original_hash=$(hash_file "$input")
received_hash=$(hash_file "$output")
printf 'source   %s\nreceived %s\n' "${original_hash%% *}" "${received_hash%% *}"
if [ "$original_hash" != "$received_hash" ]; then
  echo 'FAIL: SHA-256 mismatch' >&2
  exit 1
fi
echo 'OK: SHA-256 matches'
