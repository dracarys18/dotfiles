#!/usr/bin/env bash
set -euo pipefail

src=/var/lib/stacks/tangled/src
git=/etc/profiles/per-user/karthihegde/bin/git
podman=/run/current-system/sw/bin/podman

if [ ! -d "$src/.git" ]; then
  "$git" clone --depth 1 https://tangled.org/tangled.org/core "$src"
else
  "$git" -C "$src" fetch --depth 1 origin master
  "$git" -C "$src" reset --hard origin/master
fi

containerfile="$src/knot2/Containerfile"
sed -i '/^COPY knot2\/lexicons/d' "$containerfile"
grep -q 'mold git' "$containerfile" || sed -i 's/ mold / mold git /' "$containerfile"
grep -q 'CARGO_NET_GIT_FETCH_WITH_CLI' "$containerfile" ||
  sed -i '/^RUN cargo build/i ENV CARGO_HTTP_MULTIPLEXING=false CARGO_NET_RETRY=10 CARGO_HTTP_TIMEOUT=120 CARGO_NET_GIT_FETCH_WITH_CLI=true' "$containerfile"

mkdir -p /var/lib/stacks/tangled/cargo/registry /var/lib/stacks/tangled/cargo/git
"$podman" build \
  -v /var/lib/stacks/tangled/cargo/registry:/usr/local/cargo/registry \
  -v /var/lib/stacks/tangled/cargo/git:/usr/local/cargo/git \
  -f "$containerfile" -t knot2:latest "$src"

systemctl restart podman-tangled-knot.service
