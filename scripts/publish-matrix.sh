#!/usr/bin/env bash
#
# Prints the build matrix for onpush_build.yaml as compact JSON: one entry per
# add-on and architecture it supports, with everything the build step needs.
#
#   scripts/publish-matrix.sh '["cups","angryipscanner"]'
#
# Kept out of the workflow so it can be run and tested locally.
set -euo pipefail

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
                --arg image "${image_template//\{arch\}/${arch}}" \
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
