# Testing a branch on a real Home Assistant

The Supervisor add-on store can install from a git branch, so a pull request can be
tried on a live instance before it is merged. This is undocumented upstream but it is
real: `RE_REPOSITORY` in `supervisor/validate.py` parses a `#branch` fragment, and
`store/git.py` passes it straight to `git clone --branch <branch> --depth 1`.

## Read this first: what it does and does not prove

Every add-on here sets `image: ghcr.io/maxwinterstein/...-{arch}` in its `config.yaml`.
Supervisor's `need_build` is `ATTR_IMAGE not in self.data`, so it **pulls the published
image and never builds the Dockerfile on your device**.

A branch install therefore exercises:

- `config.yaml`: the options schema, arch list, ports, ingress, mappings
- how `DOCS.md` and `README.md` render in the store
- `translations/`

and does **not** exercise:

- anything in the `Dockerfile`, `rootfs/` or application code

To test those, the branch has to bump `version:` **and** that tag has to already exist
on ghcr — which only happens after a merge to `main`. A branch that bumps the version
to something unpublished fails at `docker pull`, not at clone.

## Doing it

1. Add the repository, with the branch as a fragment:

   ```text
   https://github.com/MaxWinterstein/homeassistant-addons#my-branch
   ```

   Settings → Add-ons → Add-on Store → ⋮ → Repositories → Add.

2. A second store section appears with the same name. Add-ons from it are namespaced
   `sha1(url#branch)[:8]_<slug>`, so they are **separate add-ons** from the installed
   ones, with their own `/data` and their own saved options. Your production install
   cannot be shadowed, reconfigured or detached by this.

3. Push more commits and hit store reload to pick them up. Reload does a shallow fetch
   and `git reset --hard origin/<branch>` on the branch it cloned.

## Traps

**Slashes in branch names need Supervisor 2026.07.0 or newer.** The branch pattern was
`[\w\-.]+` through 2026.06.0 and only gained `/` in 2026.07.0. On anything older,
`#fix/some-thing` is rejected at validation with "No valid repository format!". Push a
slash-free alias branch (`git push origin HEAD:testme`) if you hit that.

**Remove the repository entry before the branch is deleted.** Once the branch is gone
upstream, the store's fetch fails and Supervisor raises a persistent
`CORRUPT_REPOSITORY` repair issue — and its own "reset" suggestion cannot fix it,
because the reset re-clones a branch that no longer exists. Order matters: uninstall the
test add-on, then remove the repository, then merge and delete the branch.

**Two copies of a bridge fight over the same MQTT topics.** The branch copy of
`toogoodtogo-ha-mqtt-bridge` publishes to the same `homeassistant/...` discovery topics
as the real one, so entities will duplicate or flap. Stop the production copy first. The
same applies to any add-on with `host_network: true` or fixed `ports` (cups,
angryipscanner) — the two cannot bind the same port.

**Never uninstall the production add-on to "roll back".** `App.unload()` runs
`rm -rf` on the add-on's `/data` unconditionally, and the UI's _"Also remove app data"_
toggle does not protect it — that flag guards `/addon_configs/<slug>`, which only exists
for add-ons that map `addon_config`. `toogoodtogo-ha-mqtt-bridge` does not, so the
toggle is a no-op there and uninstalling destroys `/data/tokens.json`. Recovering means
a fresh TooGoodToGo email login, which is rate-limited.

**Do not use the private `-dev` / `-test` repositories.** Supervisor has no git
credential support of any kind — no credential helper, no `GIT_ASKPASS`, no UI field.
The only way to clone a private repo is a token embedded in the URL, and that URL is
stored in plaintext in `/data/store.json`, written verbatim to the Supervisor log by
`store/git.py`, and returned as the `source` field from `GET /store/repositories` — so it
shows up in the store UI and in any diagnostics upload. The `#branch` route on the
public repo makes those repositories unnecessary.

## If you actually need to test a Dockerfile change on-device

The local add-ons folder is the only route that builds from source. It is a real
mutation of the Supervisor's data directory rather than a store entry, so treat it as a
separate decision — and note the directory was renamed from `addons/local` to
`apps/local` in the 2026 add-ons→apps rename.
