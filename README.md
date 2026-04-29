# ra2-claude

Red Alert 2 sound effects for [Claude Code](https://www.anthropic.com/claude-code) — an improved edition of [op7418/RedAlert2-Claude](https://github.com/op7418/RedAlert2-Claude).

Hear the GI shouting **"Yes, Sir!"** when a session starts, the Prism Tank announcing **"Calculating Reflection Arcs!"** on every prompt, and **"Kirov reporting!"** the moment Claude needs your approval.

## Credits

This project is heavily inspired by [op7418/RedAlert2-Claude](https://github.com/op7418/RedAlert2-Claude). The audio files in `sounds/` come from that repository (originally extracted from Westwood/EA's *Red Alert 2*). All credit for the idea and the audio sourcing goes to the original author.

## What's improved

| | Original | This fork |
| --- | --- | --- |
| Background process | `fswatch` daemon + 5 child watchers | **None** — hooks invoke the script directly |
| `approval` sound | Documented as "needs manual trigger" | Wired to Claude Code's `Notification` hook |
| Platform | macOS only (`afplay`) | macOS / Linux (`afplay` → `paplay` → `aplay` → `ffplay`) |
| Anti-spam | None | `done` and `prompt` events throttled (3 s / 2 s) |
| `settings.json` install | Either skipped or overwritten | `jq`-based merge, idempotent, with backup |
| Control surface | 6 zsh functions + 1 alias | Single CLI: `ra2 enable | disable | toggle | status | test` |
| Shell integration | `source ~/.zshrc` required | None — hooks call the script directly |

## Events

| Event | Hook | Sound | When it fires |
| --- | --- | --- | --- |
| `start` | `SessionStart` (`startup` / `clear`) | `session-start.wav` | New session or `/clear` |
| `prompt` | `UserPromptSubmit` | `vpriata.wav` | Each prompt you submit |
| `done` | `Stop` | `task-complete.wav` | Each Claude response ends |
| `compact` | `PreCompact` | `context-compact.wav` | Before context compaction |
| `approval` | `Notification` | `approval-needed.wav` | Permission / approval prompts |

## Requirements

- macOS or Linux
- An audio backend on `PATH`: one of `afplay` (macOS built-in), `paplay`, `aplay`, `ffplay`
- [`jq`](https://jqlang.org/) — only required by `install.sh` to merge into `settings.json`
- [Claude Code](https://www.anthropic.com/claude-code)

## Install

```bash
git clone https://github.com/moyaying/ra2-claude.git
cd ra2-claude
brew install jq           # macOS; or apt/dnf install jq on Linux
./install.sh
```

The installer:

1. Copies `ra2` to `~/.claude/ra2/ra2` and the `.wav` files into per-event sub-directories.
2. Backs up your existing `~/.claude/settings.json` to `settings.json.bak.<timestamp>`.
3. Merges five hook entries into `settings.json`. **Existing hooks are preserved** — entries are appended only if no entry with the same command exists, so re-running is safe.

If you don't have `jq`, the installer copies the files but skips the merge step and prints a hint to merge `hooks.json` into `~/.claude/settings.json` manually.

### Verify

```bash
~/.claude/ra2/ra2 status
~/.claude/ra2/ra2 test done       # play a random sound from sounds/done
```

You may need to **start a new Claude Code session** for the `SessionStart` hook to fire. The other hooks may pick up live, depending on the version.

### Optional: shorten the path

```bash
ln -sf ~/.claude/ra2/ra2 /usr/local/bin/ra2
```

Then you can use `ra2 status` directly.

## Usage

```text
ra2 play <event>     # called by Claude hooks (you usually don't run this)
ra2 enable           # turn sounds back on
ra2 disable          # silence everything (hooks remain configured)
ra2 toggle           # flip enable/disable
ra2 status           # current state, paths, file counts per event
ra2 test <event>     # play a random sound from sounds/<event>
ra2 events           # list known events
```

## Configuration

All knobs are environment variables; export them before launching Claude Code (e.g. in `~/.zshrc`):

| Variable | Default | Meaning |
| --- | --- | --- |
| `RA2_HOME` | `~/.claude/ra2` | Project home |
| `RA2_SOUNDS_DIR` | `$RA2_HOME/sounds` | Root of per-event sound directories |
| `RA2_VOLUME` | `0.3` | 0.0–1.0 multiplier (`afplay -v` semantics) |

### Adjusting anti-spam thresholds

Edit `MIN_GAP` near the top of `ra2`:

```bash
declare -A MIN_GAP=(
  [done]=3       # min seconds between "task complete" plays
  [prompt]=2     # min seconds between "prism tank" plays
  [start]=0
  [compact]=0
  [approval]=0
)
```

### Adding more sounds

Drop additional `.wav` / `.mp3` / `.m4a` / `.aiff` files into any per-event directory. The script picks one at random per play.

```bash
cp my-sound.wav ~/.claude/ra2/sounds/done/
```

### Disabling a single hook

If `prompt` or `done` is too chatty for you, edit `~/.claude/settings.json` and remove the corresponding entry — or simply delete the directory:

```bash
rm -rf ~/.claude/ra2/sounds/prompt    # prompt sound silently skipped
```

## Uninstall

```bash
# Restore your previous settings.json
cp ~/.claude/settings.json.bak.<timestamp> ~/.claude/settings.json
# Remove project files
rm -rf ~/.claude/ra2
# (Optional) remove the symlink if you created one
rm -f /usr/local/bin/ra2
```

## License

MIT for the code (see [LICENSE](LICENSE)).

The `.wav` files in `sounds/` are **not** covered by the MIT license — they originate from Westwood Studios / Electronic Arts' *Red Alert 2* and are included for personal, non-commercial use only. If you redistribute or fork this project, the same caveats that apply to the upstream repository apply to you.
