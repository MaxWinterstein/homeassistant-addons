#!/usr/bin/env bash
#
# Upstream drift check for the planefence add-on.
#
# The add-on writes its options into docker-planefence's planefence.config,
# which starts as a copy of upstream's template. When upstream renames a key
# (FEEDER_LONG -> FEEDER_LON in latest-build-1249), the add-on keeps writing
# the old name, the template default wins and Planefence breaks on fresh
# installs only. This compares the keys the add-on writes with the template of
# the base image CI and publishing actually use (planefence/build.json), so a
# Renovate base-image bump that renames a key fails its PR.
#
# Needs a Docker daemon; the image is only created, never started.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

SCRIPT=planefence/rootfs/etc/cont-init.d/00-ha-planefence-config.sh
ALLOWED=tests/drift/planefence-allowed.txt
TEMPLATE_PATH=/usr/share/planefence/stage/persist/planefence.config.RENAME-and-EDIT-me

base="$(jq -r '.build_from.amd64' planefence/build.json)"
echo "base image: ${base}"

tmp="$(mktemp -d)"
cid=""
cleanup() {
    [ -n "${cid}" ] && docker rm -f "${cid}" >/dev/null 2>&1
    rm -rf "${tmp}"
}
trap cleanup EXIT

docker pull -q --platform linux/amd64 "${base}" >/dev/null
cid="$(docker create --platform linux/amd64 "${base}")"
docker cp -q "${cid}:${TEMPLATE_PATH}" "${tmp}/template"

# Keys defined in the template, commented-out examples included ("#KEY=").
grep -oE '^[[:space:]]*#?[[:space:]]*[A-Z][A-Z0-9_]*=' "${tmp}/template" |
    tr -d '# =' | sort -u >"${tmp}/template.keys"

# Keys the add-on writes: set_config / set_config_if "KEY".
grep -oE '^[[:space:]]*set_config(_if)?[[:space:]]+"[A-Z][A-Z0-9_]*"' "${SCRIPT}" |
    grep -oE '"[A-Z0-9_]+"' | tr -d '"' | sort -u >"${tmp}/written.keys"

{ grep -vE '^[[:space:]]*(#|$)' "${ALLOWED}" || true; } | awk '{print $1}' | sort -u >"${tmp}/allowed.keys"

missing="$(comm -23 "${tmp}/written.keys" "${tmp}/template.keys" | comm -23 - "${tmp}/allowed.keys")"
stale="$(comm -12 "${tmp}/allowed.keys" "${tmp}/template.keys")"

echo "template keys: $(wc -l <"${tmp}/template.keys"), written by the add-on: $(wc -l <"${tmp}/written.keys"), allowed exceptions: $(wc -l <"${tmp}/allowed.keys")"

if [ -n "${stale}" ]; then
    echo "note: allowed exceptions that are back in the template (consider removing them from ${ALLOWED}):"
    while read -r key; do echo "  ${key}"; done <<<"${stale}"
fi

# A renamed key may stay on the allow list only while the new name is
# written too ("KEY  =>NEWKEY  reason").
unpaired=""
while read -r key target _; do
    case "${target}" in
    "=>"*)
        grep -qx "${target#=>}" "${tmp}/written.keys" || unpaired="${unpaired}${key} (needs ${target#=>})"$'\n'
        ;;
    esac
done < <(grep -vE '^[[:space:]]*(#|$)' "${ALLOWED}" || true)
unpaired="${unpaired%$'\n'}"

if [ -n "${unpaired}" ]; then
    echo "FAIL: renamed keys are written only under their old name:"
    while read -r key; do echo "  ${key}"; done <<<"${unpaired}"
    echo "The template's default for the new name would win on fresh installs."
    exit 1
fi

if [ -n "${missing}" ]; then
    echo "FAIL: the add-on writes keys that ${base} no longer has in its template:"
    while read -r key; do echo "  ${key}"; done <<<"${missing}"
    echo "Upstream probably renamed or removed them. Write the new name in ${SCRIPT}"
    echo "(keep the old one if upstream still falls back to it), or, if the removal"
    echo "is fine, add the key with a reason to ${ALLOWED}."
    exit 1
fi
echo "ok: every key the add-on writes exists in the upstream template"
