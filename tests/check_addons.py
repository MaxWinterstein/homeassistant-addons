#!/usr/bin/env python3
"""Repo-wide consistency checks for the Home Assistant add-ons.

These are the checks that need to look across a whole add-on directory rather
than at one shell script, so they live here instead of in the bats suites.
They need no Docker and no Home Assistant, and they mechanically enforce the
repository rules that are otherwise only written down in CLAUDE.md — notably
that the version in the add-on config matches the top of its CHANGELOG.

Usage:
    python3 tests/check_addons.py            # errors fail, warnings reported
    python3 tests/check_addons.py --strict   # warnings fail too
    python3 tests/check_addons.py planefence # limit to one add-on

Note on slugs: they deliberately do *not* always match the directory name
(fr24-sharing-key-generator -> fr24sharingkeygenerator), because changing a
slug would break existing installations. So there is no such check here.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover - the sandbox image ships pyyaml
    sys.exit("pyyaml is required: it is provided by .vibepod/overlay/claude/Dockerfile")

# Overridable so the checker's own tests can point it at fixture directories
# instead of the real add-ons.
REPO_ROOT = Path(
    os.environ.get("ADDONS_ROOT", Path(__file__).resolve().parent.parent)
).resolve()

CONFIG_NAMES = ("config.yaml", "config.yml", "config.json")

# https://developers.home-assistant.io/docs/add-ons/configuration/
VALID_ARCH = {"aarch64", "amd64", "armhf", "armv7", "i386"}

REQUIRED_FIELDS = ("name", "version", "slug", "description", "arch")

# A towncrier/keep-a-changelog style heading: ## [1.2.3] - 2026-01-01
CHANGELOG_VERSION_RE = re.compile(r"^##\s*\[([^\]]+)\]", re.MULTILINE)


class Findings:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def error(self, addon: str, msg: str) -> None:
        self.errors.append(f"{addon}: {msg}")

    def warn(self, addon: str, msg: str) -> None:
        self.warnings.append(f"{addon}: {msg}")


def load_config(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    if path.suffix == ".json":
        return json.loads(text)
    return yaml.safe_load(text)


def find_addons(only: list[str]) -> list[Path]:
    addons = []
    for entry in sorted(REPO_ROOT.iterdir()):
        if not entry.is_dir() or entry.name.startswith("."):
            continue
        if any((entry / name).is_file() for name in CONFIG_NAMES):
            if not only or entry.name in only:
                addons.append(entry)
    return addons


def config_path(addon: Path) -> Path | None:
    for name in CONFIG_NAMES:
        candidate = addon / name
        if candidate.is_file():
            return candidate
    return None


def check_required_fields(addon: str, config: dict, f: Findings) -> None:
    for field in REQUIRED_FIELDS:
        if field not in config or config[field] in (None, "", []):
            f.error(addon, f"config is missing required field '{field}'")


def check_arch(addon: str, config: dict, f: Findings) -> None:
    arches = config.get("arch") or []
    if not isinstance(arches, list):
        f.error(addon, "'arch' must be a list")
        return
    for arch in arches:
        if arch not in VALID_ARCH:
            f.error(addon, f"unknown architecture '{arch}' (valid: {sorted(VALID_ARCH)})")


def check_options_schema(addon: str, config: dict, f: Findings) -> None:
    """Every option needs a schema entry and vice versa.

    Home Assistant validates user input against 'schema'. An option with no
    schema entry is rejected by the Supervisor; a schema entry with no default
    in 'options' is legal but usually an oversight, so that is a warning.
    """
    options = config.get("options")
    schema = config.get("schema")
    if options is None and schema is None:
        return
    # A schema with only optional entries and no options block is legal — see
    # portainer — so normalise rather than demanding both keys exist.
    options = {} if options is None else options
    schema = {} if schema is None else schema
    if not isinstance(options, dict) or not isinstance(schema, dict):
        f.error(addon, "'options' and 'schema' must both be mappings")
        return

    for key in sorted(set(options) - set(schema)):
        f.error(addon, f"option '{key}' has no matching schema entry")
    for key in sorted(set(schema) - set(options)):
        # Optional schema entries are marked with a trailing '?'.
        value = schema[key]
        optional = isinstance(value, str) and value.endswith("?")
        if not optional:
            f.warn(addon, f"schema '{key}' has no default in options")


def check_changelog(addon_dir: Path, addon: str, config: dict, f: Findings) -> None:
    changelog = addon_dir / "CHANGELOG.md"
    if not changelog.is_file():
        f.warn(addon, "has no CHANGELOG.md")
        return

    version = str(config.get("version", "")).strip()
    if not version:
        return

    match = CHANGELOG_VERSION_RE.search(changelog.read_text(encoding="utf-8"))
    if not match:
        f.warn(addon, "CHANGELOG.md has no '## [version]' heading")
        return

    latest = match.group(1).strip()
    if latest != version:
        f.error(
            addon,
            f"version mismatch: config says '{version}', "
            f"newest CHANGELOG entry is '{latest}'",
        )


def check_dockerfile(addon_dir: Path, addon: str, f: Findings) -> None:
    if not (addon_dir / "Dockerfile").is_file():
        f.error(addon, "has no Dockerfile")


def check_translations(addon_dir: Path, addon: str, f: Findings) -> None:
    translations = addon_dir / "translations"
    if not translations.is_dir():
        return
    for path in sorted(translations.glob("*.json")):
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            f.error(addon, f"translations/{path.name} is not valid JSON: {exc}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("addons", nargs="*", help="limit to these add-on directories")
    parser.add_argument(
        "--strict", action="store_true", help="treat warnings as failures"
    )
    args = parser.parse_args()

    f = Findings()
    addons = find_addons(args.addons)
    if not addons:
        print("no add-ons found", file=sys.stderr)
        return 1

    checked = 0
    for addon_dir in addons:
        addon = addon_dir.name
        path = config_path(addon_dir)
        assert path is not None
        try:
            config = load_config(path)
        except (yaml.YAMLError, json.JSONDecodeError) as exc:
            f.error(addon, f"{path.name} does not parse: {exc}")
            continue
        if not isinstance(config, dict):
            f.error(addon, f"{path.name} is not a mapping")
            continue

        checked += 1
        deprecated = str(config.get("stage", "")).lower() == "deprecated"

        check_required_fields(addon, config, f)
        check_arch(addon, config, f)
        check_options_schema(addon, config, f)
        check_dockerfile(addon_dir, addon, f)
        check_translations(addon_dir, addon, f)
        if not deprecated:
            check_changelog(addon_dir, addon, config, f)

    for warning in f.warnings:
        print(f"WARN  {warning}")
    for error in f.errors:
        print(f"ERROR {error}")

    print(
        f"\nchecked {checked} add-on(s): "
        f"{len(f.errors)} error(s), {len(f.warnings)} warning(s)"
    )

    if f.errors:
        return 1
    if args.strict and f.warnings:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
