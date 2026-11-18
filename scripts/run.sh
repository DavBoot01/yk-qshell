#!/usr/bin/env bash
# Runs yk-qshell by hand: takes the application's Plugins where they are not built, runs the application on
# a local Core, grants each Plugin what its Manifest declares, and starts the shell beside it, attached to
# the channel `shell`, as the compositor will start it. An interrupt, or the shell ending, stops everything.
#
# Usage: run.sh <QML import path>
#   the directory holding Yoke/Interface, where yoke-sdk-cpp was installed with its QML binding
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app="$root/app"
imports="${1:?usage: run.sh <QML import path>}"

# A Plugin taken from a repository is built from its tag; what was built is not committed.
while read -r id tag; do
  unit="$(awk -v id="$id" '$1 == "-" && $3 == id {on=1} on && $1 == "unit:" {print $2; exit}' "$app/plugins.yaml")"
  [[ -x "$app/components/plugins/$unit" ]] || yoke-compose update plugin "$id" --to "$tag" --yes --dir "$app" > /dev/null
done < <(awk '$1 == "-" && $2 == "id:" {id=$3} $1 == "tag:" {print id, $2}' "$app/plugins.yaml")

log="$(mktemp)"
yoke app run --from "$app" > "$log" 2>&1 &
run=$!
trap 'kill -INT "$run" 2> /dev/null; wait "$run" 2> /dev/null; rm -f "$log"' EXIT
until grep -q 'is observable' "$log"; do
  kill -0 "$run" 2> /dev/null || { cat "$log" >&2; exit 1; }
  sleep 0.3
done
instance="$(sed -n '1s/ runs .*//p' "$log")"
export YOKE_INSTANCE="$instance"

# A run's instance starts with nothing granted; a grant reaches the unit at its next admission.
for manifest in "$app"/manifests/*.yaml; do
  plugin="$(sed -n 's/^id: //p' "$manifest")"
  for capability in $(sed -n 's/^  - name: //p' "$manifest"); do
    yoke plugin grant "$plugin" "$capability" --instance "$instance" > /dev/null
  done
done
for unit in $(awk '$1 == "unit:" {print $2}' "$app/plugins.yaml"); do
  yoke unit restart "$unit" --instance "$instance" > /dev/null
done

echo "run.sh: $instance runs; the shell attaches to its channel shell" >&2
QML_IMPORT_PATH="$imports${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}" qs -p "$root/shell"
