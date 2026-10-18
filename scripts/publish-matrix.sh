#!/usr/bin/env bash
#
# Prints the build matrix for onpush_build.yaml as compact JSON: one entry per
# add-on and architecture it supports, with everything the build step needs.
#
#   scripts/publish-matrix.sh '["cups","angryipscanner"]'
#   scripts/publish-matrix.sh --manifests '["cups","angryipscanner"]'
#
# Two image styles (config.yaml `image:`):
#   per-arch  ghcr.io/owner/name-{arch}   each architecture is its own image
#   generic   ghcr.io/owner/name          one multi-arch manifest; the
#             per-arch images are pushed as ghcr.io/owner/<arch>-name, the
#             naming home-assistant/builder's publish-multi-arch-manifest
#             expects. --manifests lists these add-ons for the manifest job.
#
# Kept out of the workflow so it can be run and tested locally.
set -euo pipefail

MODE=builds
if [ "${1:-}" = "--manifests" ]; then
    MODE=manifests
    shift
fi
ADDONS_JSON="${1:-[]}"

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Runner per architecture: the composable build action builds natively on the
# runner it gets (no QEMU), so aarch64 needs an ARM runner.
runner_for() {
    case "$1" in
    aarch64) echo "ubuntu-24.04-arm" ;;
    amd64) echo "ubuntu-latest" ;;
    *) return 1 ;;
    esac
}

entries=()
for addon in $(jq -r '.[]' <<<"${ADDONS_JSON}"); do
    config="${addon}/config.yaml"
    [ -f "${config}" ] || {
        echo "${addon}: no config.yaml" >&2
        exit 1
    }

    image_template="$(yq -r '.image // ""' "${config}")"
    [ -n "${image_template}" ] || {
        echo "${addon}: no image: in config.yaml, nothing to publish" >&2
        continue
    }

    if [[ "${image_template}" == *"{arch}"* ]]; then
        generic=0
    else
        generic=1
    fi
    if [ "${MODE}" = manifests ]; then
        if [ "${generic}" = 1 ]; then
            entries+=("$(
                jq -n -c \
                    --arg addon "${addon}" \
                    --arg prefix "${image_template%/*}" \
                    --arg name "${image_template##*/}" \
                    --arg version "$(yq -r '.version' "${config}")" \
                    --argjson archs "$(yq -o=json -I=0 '[.arch[] | select(. == "aarch64" or . == "amd64")]' "${config}")" \
                    '{addon: $addon, registry_prefix: $prefix, image_name: $name, version: $version,
                      architectures: ($archs | tojson)}'
            )")
        fi
        continue
    fi

    build_file=""
    for candidate in "${addon}/build.yaml" "${addon}/build.json"; do
        [ -f "${candidate}" ] && build_file="${candidate}" && break
    done

    for arch in $(yq -r '.arch[]' "${config}"); do
        os="$(runner_for "${arch}")" || {
            echo "${addon}: skipping unsupported architecture ${arch}" >&2
            continue
        }
        base=""
        [ -n "${build_file}" ] && base="$(yq -r ".build_from.${arch} // \"\"" "${build_file}")"

        entries+=("$(
            jq -n -c \
                --arg addon "${addon}" \
                --arg arch "${arch}" \
                --arg os "${os}" \
                --arg image "$(if [ "${generic}" = 1 ]; then echo "${image_template%/*}/${arch}-${image_template##*/}"; else echo "${image_template//\{arch\}/${arch}}"; fi)" \
                --arg version "$(yq -r '.version' "${config}")" \
                --arg base "${base}" \
                --arg name "$(yq -r '.name' "${config}")" \
                --arg description "$(yq -r '.description // ""' "${config}")" \
                --arg url "$(yq -r '.url // ""' "${config}")" \
                '{addon: $addon, arch: $arch, os: $os, image: $image, version: $version,
                  build_args: (if $base == "" then "" else "BUILD_FROM=\($base)" end),
                  labels: ([
                    "io.hass.type=addon",
                    "io.hass.name=\($name)",
                    "io.hass.description=\($description)",
                    "io.hass.url=\($url)"
                  ] | join("\n"))}'
        )")
    done
done

printf '%s\n' "${entries[@]}" | jq -s -c '{include: map(select(. != null))}'
