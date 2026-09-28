# Handoff: the python walker plays the room, the hall reads itself — from a CLOUD session to one on Palle's PC

*2026-09-28. Written by the cloud session on branch `palm-scanner-door-entry` (tip `4ed1bd5a1` plus
this note). A cloud session can edit and test the repo but cannot touch Palle's PC, the Quest, adb,
Godot's editor state or the speakers. Everything below that says "on the PC" is yours to do.*

## What Palle asked for, in order

1. "We have a python program that can walk through the halls but can we make that agent look at
   the artifact, use path finding and interact with the artifacts?" — **built.** `doc/VR_AGENT.md`.
2. "Can we trigger the text of the final.md as text to speech or mp3 audio file with adb on the
   desktop when we move around in VR. Best to sync every new hall, but point_one has two
   chapters." — **built.** `doc/VR_NARRATOR.md`.
3. Test both on the Oculus (USB, adb, the link already in use). — **not done: needs the PC.**
4. A Godot parser error, `Class "SciFiLoFiSoundscape" hides a global script class`, on export
   and in the editor. — **diagnosed and tooled, not yet cleared on the PC.**
5. "Now I am in VR can you turn on the audio" — **cannot be done from the cloud.** It is one
   command on the PC (below).

## What exists now (all committed and pushed on `palm-scanner-door-entry`)

| piece | file | what it does |
|---|---|---|
| bridge | `commons/bridge/vr_link.gd` (autoload `VRLink`, armed by `--vr-link` or `user://vr_link.on`) | poses at 20 Hz over the adb-reverse socket 127.0.0.1:8771; new commands `scan`, `look`, `interact`, `where`; `walker` takes `cells`, converts them with the live grid, drops each waypoint onto the floor by a ray from head height, answers `walker_done`, can carry a `CharacterBody3D` on layer 20 (`em_walker`, never `player`/`player_body`); forwards the grid's `interactable_activated`; replies carry the command's `tag` |
| agent | `tools/vr_agent.py` | plans a tour over `map_pathfinder.MapGraph` (spawn → each work's approach cell → teleporter, round other works; `bfs_path` gained `start=`), drives the ghost leg by leg: walk, look, interact; report in `ada_run/vr_agent_<Map>.md`; `--dry-run` draws the tour; museum fallback walks the scan in z order |
| link server | `tools/vr_link.py` | `--agent[=MAP]`, `--narrate` (+ `--mute`, `--preview N`, `--voice`, `--rate`, `--no-notes`, `--repeat`, `--voice-dir`), `POST /agent`, `GET/POST /narrate`, `--headset` doctor now says whether the installed build carries the pose stream only (narrator ok) or scan/look/interact too (agent ok) |
| narrator | `tools/vr_narrator.py` | `final.md` cleaned for a voice, TWO chapters (essay, then the footnotes as "Notes for <title>"); pre-rendered `ada_run/voice/<Map>/*.mp3|wav` wins, else Windows SAPI / macOS say / espeak; a hall change cuts the reading mid-word; settle 1.2 s; vestibules keep the reading; `--text`, `--say`, `--render`, `--voices`, `--listen` |
| page | `tools/vr_link_view.html` | buttons "agent: play the room", "agent: plan only", toggle "narrate halls" |
| checker | `tools/check_global_classes.py` | duplicate `class_name`s, stray scripts under `doc/` (`--fix` writes a `.gdignore` beside them), stale/mis-cased class-cache rows (`--purge-cache`), `res://` paths spelled unlike the disk |
| tests | `tools/test_vr_agent.py` (151 checks, fake game in process and over the real sockets), `tools/test_vr_narrator.py` | both green on the merged tree |
| probe | `commons/testing/probe_vr_link_agent.gd` | the game side on a bench — **written without an engine at hand, never run** |

Fixed in passing: two genuine duplicate class names from the 2026-09-18 sweep commit
(`CartridgeFibonacci` in bar_array → `CartridgeFibonacciBars`; the commons port of
`WavetableSynth` → `WavetableSynthNode`), and three `res://algorithms/MachineLearning/…` paths
in `test_scene_loading.gd` spelled unlike the disk (fatal on the Quest, silent on Windows).

## The open problem: the SciFiLoFiSoundscape error on Palle's PC

The repo declares that class exactly once. Real Godot 4.6, run headless in the cloud on the tree
at `4ed1bd5a1`, builds a class cache with the live path only, zero "hides a global script class",
the three audio scripts compile (`check_compile.gd`: 3 checked, 0 failed), and the desktop map
tester boots Point_One clean. So the second declaration lives only on the PC. Palle's Output
named it:

    res://doc/reports/interfaces-2026-09-21/radio-console/before/commons__audio__systems__SciFiLoFiSoundscape.gd

— an untracked review snapshot inside the project, no `.gdignore`, so Godot scans it. After
`--fix` (writes the `.gdignore`) the editor still showed the error: the class cache kept the
snapshot's row. `--purge-cache` was added for that. Palle reports it is *still* red. Things a
PC session can settle in minutes, in this order:

1. Godot closed. `python tools/check_global_classes.py --name SciFiLoFiSoundscape` — paste what
   it prints: every path declaring the class on disk, and the cache row.
2. `dir /s /b *SciFiLoFi*` from the project root, and check WHICH project root Godot has open
   (a worktree under `.claude\worktrees\` is a different checkout with none of the fixes).
3. Blunt: delete `doc\reports\interfaces-2026-09-21` (nothing loads it) and the whole `.godot`
   folder, reopen. If it is still red after that, the second declaration is somewhere the
   checker did not walk — say where.
4. `doc/` as a whole cannot take a `.gdignore`: `ProjectDashboardOverlay.gd` reads
   `res://doc/reports/*.json` and an ignored folder leaves the export. Per-snapshot markers only.

## What to run on the PC once that is clear

```
python tools/vr_link.py --headset               # attached? armed? which link features has the build?
python tools/vr_link.py --arm                   # once per install; restart the app on the headset
python tools/vr_link.py --narrate --mute        # 1. the trigger: the log at localhost:8772 names each hall
python tools/vr_link.py --narrate --preview 40  # 2. the voice, forty words per chapter
python tools/vr_link.py --narrate               # 3. the essay and its notes; PC speakers, not the headset
```

The narrator needs only the pose, which every build since 2026-08-31 sends once armed. The agent
(`python tools/vr_link.py --agent`, no map name = whatever the headset stands in) needs a build
made after 2026-09-26: export preset `adaresearchonexy`, `adb install -r`, `--arm`, restart.

If `vr_link.py` is already running, do not start a second (port 8771): click "narrate halls" on
the page, or run `python tools/vr_narrator.py --listen` beside it.

## Never verified anywhere yet

- The Windows voice: `python tools/vr_narrator.py --say Point_One --preview 40` is the first
  real check that SAPI speaks and that a hall change cuts it.
- The Godot probe `commons/testing/probe_vr_link_agent.gd` (headless line in its header).
- The bridge on a real headset: `scan` in a museum hall, `look`'s line-of-sight ray, `interact`
  on a real artifact, `walker_done` over the USB tunnel.
- XR Tools pointer targets are pressed through `XRToolsPointerEvent` looked up by name at call
  time (the addon is gitignored); untested.

## Side finding, not acted on

On a fresh clone two autoloads fail: `project.godot` names them by `uid://` and `*.uid` files are
gitignored, so a new checkout cannot resolve them. Palle's machine has the files. Worth a look
before anyone else clones.
