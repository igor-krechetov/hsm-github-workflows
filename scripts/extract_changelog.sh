#!/usr/bin/env bash
#
# Extract CHANGELOG sections for a release's notes.
#
# Prints every CHANGELOG version section strictly newer than the previous
# released version (exclusive) up to and including the current version
# (inclusive). CHANGELOG sections are ordered newest-first, so the output is
# the contiguous block of sections between the current version header and the
# previous version header.
#
# Usage:
#   extract_changelog.sh <changelog_file> <current_version> [previous_version]
#
# - <current_version>   version being released (e.g. "0.18.0"); a leading "v"
#                        is tolerated and stripped.
# - [previous_version]  last released version (e.g. "0.17.1"); a leading "v" is
#                        tolerated and stripped. When omitted or empty (first
#                        release / no previous tag), only the current version's
#                        section is emitted.
#
# NOTE (fail-open behavior): if the current version header is never matched,
# nothing is captured and the output is empty. If the previous version header
# is never matched (e.g. it was removed from the changelog), capturing simply
# continues to end-of-file — this fail-open-to-EOF behavior is intentional and
# preserved from the original implementation.
#
set -euo pipefail

CHANGELOG_FILE="${1:?changelog file required}"
CURRENT_VERSION="${2:?current version required}"
PREVIOUS_VERSION="${3:-}"

# Normalize versions: drop an optional leading "v" so "v0.18.0" matches the
# plain "0.18.0" used in CHANGELOG headers (## [X.Y.Z] - DATE).
CURRENT_VERSION="${CURRENT_VERSION#v}"
PREVIOUS_VERSION="${PREVIOUS_VERSION#v}"

awk -v current="$CURRENT_VERSION" -v previous="$PREVIOUS_VERSION" '
  # Match a version header line like: ## [0.18.0] - 2026-10-09 and pull out
  # the X.Y.Z inside the brackets (portable: no gawk-only match() captures).
  /^## \[[^]]+\]/ {
    ver = $0
    sub(/^## \[/, "", ver)
    sub(/\].*$/, "", ver)
    if (ver == current) {
      capturing = 1
    } else if (previous != "" && ver == previous) {
      # Reached the previous released version header: stop before it.
      capturing = 0
    } else if (capturing && previous == "") {
      # No previous version known: emit only the current section.
      capturing = 0
    }
  }
  capturing { print }
' "$CHANGELOG_FILE"
