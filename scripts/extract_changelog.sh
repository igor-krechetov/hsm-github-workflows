#!/usr/bin/env bash
#
# Extract CHANGELOG sections for a release's notes.
#
# Prints the current version's section only: everything from the current
# version header (inclusive) up to the NEXT version header (exclusive).
# CHANGELOG sections are ordered newest-first, so this is the contiguous block
# belonging to the current version.
#
# Usage:
#   extract_changelog.sh <changelog_file> <current_version> [previous_version]
#
# - <current_version>   version being released (e.g. "0.18.0"); a leading "v"
#                        is tolerated and stripped.
# - [previous_version]  OPTIONAL and no longer used for the stop decision. It
#                        is accepted for backward-compatible call sites but the
#                        section boundary is determined solely by the next
#                        version header, so a leading "v" is still stripped for
#                        compatibility. This avoids a prior failure mode where a
#                        previous git tag with no matching changelog header
#                        caused capture to run to end-of-file and dump the whole
#                        changelog (git tags and changelog sections can drift).
#
# NOTE (fail-open behavior): if the current version header is never matched,
# nothing is captured and the output is empty. If the current version is the
# newest/only section, capture naturally continues to end-of-file.
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
      # Found the current version header: start capturing this section.
      capturing = 1
    } else if (capturing) {
      # Any OTHER version header reached while capturing marks the end of the
      # current section. Stop here regardless of which version it is.
      #
      # This intentionally does NOT depend on the previous version header being
      # present in the changelog. Git tags and changelog sections can drift out
      # of sync (e.g. a tag 1.0.5 with no "## [1.0.5]" section), and keying the
      # stop condition on the previous tag used to fall through to end-of-file,
      # dumping the entire changelog. "Stop at the next header" is the correct,
      # self-correcting definition of "this version section".
      capturing = 0
    }
  }
  capturing { print }
' "$CHANGELOG_FILE"
