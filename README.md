# weg

A tiny [autojump](https://github.com/wting/autojump) clone in Zig. It remembers
the directories you `cd` into and lets you jump back to them with a short
command.

## How it works

- A zsh `chpwd` hook records every directory change into a plain-text database
  (`~/.weg.db`).
- `w <query>` finds the most recently visited directory matching `<query>` and
  `cd`s into it.
- The database is just a list of paths, one per line — **line order is
  recency**. No timestamps, no scores, no frecency. Dead simple.
- The database self-compacts (deduplicates) once it grows past 100 KB.

## Install

### From a release

Grab the binary for your platform from
[Releases](https://github.com/tchaudhry91/weg/releases), rename it to `weg`,
and drop it on your `$PATH`:

```sh
# Linux x86_64 example
curl -L -o weg https://github.com/tchaudhry91/weg/releases/latest/download/weg-linux-x86_64
chmod +x weg
mv weg ~/.local/bin/weg
```

> **macOS note:** binaries are unsigned, so Gatekeeper may quarantine them. If
> you get a "cannot be opened" error, run `xattr -d com.apple.quarantine weg`.

### From source

```sh
git clone https://github.com/tchaudhry91/weg
cd weg
zig build -Doptimize=ReleaseSafe
ln -s "$PWD/zig-out/bin/weg" ~/.local/bin/weg
```

## Setup (zsh)

Add this to your `~/.zshrc`:

```zsh
# record every cd
chpwd() { weg push "$PWD" }

# jump
w() {
	local dir="$(weg pull "$1")"
	[[ -n "$dir" ]] && cd "$dir"
}
```

Then `source ~/.zshrc`.

## Usage

```sh
cd ~/some/deeply/nested/project
# ... later, from anywhere:
w proj     # → cd ~/some/deeply/nested/project
```

Matching is a case-insensitive substring over the full path. The most recently
visited match wins.

## Configuration

| Env var  | Purpose           | Default    |
| -------- | ----------------- | ---------- |
| `WEG_DB` | Database location | `~/.weg.db` |

## Development

```sh
zig build          # debug build
zig build test     # run tests
zig fmt --check    # check formatting
```
