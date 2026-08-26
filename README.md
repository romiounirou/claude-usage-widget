# Claude Usage — menu bar widget

A native macOS menu bar widget (SwiftUI + AppKit), styled after the Stats
app's RAM panel, that shows Claude Code token usage read from your local
session logs at `~/.claude/projects/**/*.jsonl`. No API key needed — it only
reads files already on disk.

What it shows:
- A gauge + ring for how full the active session's context window is
  (tokens sent in the most recent request ÷ the model's context limit).
- A 14-day bar chart of total tokens used per day.
- Today's breakdown: input, output, cache read, cache write, and an
  **estimated** cost (hardcoded approximate per-model $/MTok rates — not a
  billing source of truth).

Data refreshes every 30s; each file is only re-read from where it left off,
so polling stays cheap even with a large `~/.claude` history.

## Build & run

```bash
./build_app.sh          # release build -> "Claude Usage.app"
open "Claude Usage.app"
```

Use `./build_app.sh debug` for a faster, unoptimized build while iterating.

You can also open the folder directly in Xcode (`File > Open` on
`Package.swift`) since it's a plain Swift Package — no `.xcodeproj` needed.

## Run at login

System Settings → General → Login Items & Extensions → add
`Claude Usage.app`.

## Note on verification

I built and ran this in the sandboxed shell this session, confirmed it
compiles cleanly, launches without crashing, and (via `log show`) registers
a real status item with the system. I could **not** conclusively confirm the
menu bar icon renders visually from here — screenshots taken from this tool
didn't show it, but I stopped short of clicking around your live desktop to
chase it further since that risks interacting with your actual open apps
(it already accidentally focused Chrome once). Please launch it yourself and
tell me what you see — if the icon doesn't show up, the likely culprits are
the menu bar being crowded (you have quite a few status items already) or a
menu-bar organizer hiding new items; I can debug from there with your
feedback.
