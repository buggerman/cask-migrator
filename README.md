# cask-migrator

A shell script that migrates manually installed macOS applications to [Homebrew Cask](https://formulae.brew.sh/cask/) management.

Forked from [kethomassen/cask-migrator](https://github.com/kethomassen/cask-migrator) and updated for modern Homebrew.

---

## Why?

If you installed macOS apps by hand (dragging to `/Applications`, running a `.pkg`, etc.), Homebrew has no record of them. This script bridges that gap: it finds your existing apps, checks if a cask exists for each one, and brings them under Homebrew management.

Once migrated, you can:

- Update all your GUI apps with `brew upgrade --cask`
- Track them in a `Brewfile` for reproducible setups (e.g. in your dotfiles)
- Uninstall cleanly with `brew uninstall --cask` including leftover files via `--zap`

## Requirements

- macOS
- [Homebrew](https://brew.sh/) installed

## Usage

Run directly without downloading:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/buggerman/cask-migrator/master/cask-migrator.sh)
```

Or download and run:

```bash
./cask-migrator.sh
```

By default the script scans `/Applications`, and for each `.app` it finds:

1. Skips it if it is already managed by a cask
2. Checks whether a cask with a matching name exists in the Homebrew registry
3. Prompts you for confirmation before doing anything
4. Attempts to adopt the existing app in-place (`--adopt`) — no files are moved or deleted
5. If adoption fails (e.g. version mismatch), moves the app to Trash and does a fresh install
6. On any install failure, automatically restores the app from Trash

## Options

| Flag | Description |
|------|-------------|
| `-d [dir]` | Directory to scan for `.app` files. Default: `/Applications` |
| `-i [dir]` | Directory to install casks into. Default: `/Applications` |
| `-f` | Skip confirmation prompts (force mode — use with caution) |
| `-r` | Permanently delete old apps instead of moving to Trash. **No recovery if install fails.** |
| `-h` | Print help and exit |

## How it works

The script derives a candidate cask name from each `.app` filename by lowercasing it and replacing spaces with hyphens — for example, `Google Chrome.app` becomes `google-chrome`. It then queries `brew info --cask` to verify the cask exists before touching anything.

This heuristic covers the majority of common apps but is not perfect. If an app's filename doesn't closely match its cask token, the script will simply skip it silently — nothing is modified.

### Install flow

```
For each .app in search directory:
  ├── Already managed by cask?  → skip
  ├── No cask found?            → skip
  ├── User declines prompt?     → skip
  └── Proceed:
        ├── brew install --cask --adopt  (in-place, non-destructive)
        │     └── success               → done
        └── adopt failed (version mismatch):
              ├── move to Trash (or rm -rf with -r)
              └── brew install --cask
                    ├── success         → done
                    └── failure         → restore from Trash (unless -r)
```

## Caveats

- **Name matching is a heuristic.** Apps whose filenames don't map cleanly to their cask token will be skipped. You can install those manually with `brew install --cask <token>`.
- **Using `-r` is irreversible.** If the install fails after permanent deletion, the app is gone. Only use it when you're confident.
- **Cask adoption requires a matching version.** If your manually installed version differs from what Homebrew would install, the script falls back to a fresh install.
- Apps installed outside of `/Applications` (e.g. `~/Applications`) won't be scanned unless you specify `-d`.

## License

MIT
