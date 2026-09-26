# The python walker plays the room

*2026-09-26. Palle: "We have a python program that can walk through the halls but can we
make that agent look at the artifact, use path finding and interact with the artifacts?"*

Yes. The walker that `tools/vr_link.py --walker=<Map>` sent into VR replayed a placement
trace as a polyline: it did not choose where it went, it could not see, and it touched
nothing. It now plans, looks and acts. The three abilities live where the knowledge
already was, and nothing was restated:

| ability | where it lives | what it uses |
|---|---|---|
| **path finding** | `tools/vr_agent.py` (PC) | `map_pathfinder.MapGraph` — the one step relation (heights, ramps, transport cubes, lifts, jump pads, wall segments, hazards). `bfs_path` gained a `start` so a leg begins where the last one ended. |
| **looking** | `commons/bridge/vr_link.gd` (game) | `scan` reports what stands in the room NOW with its affordances; `look` turns the ghost, casts a ray from its eye and says whether the work is in view, how far, behind what. The registry supplies what it *is*. |
| **interacting** | `commons/bridge/vr_link.gd` (game) | DesktopPlayer's ladder, one rung per verb: `interact()` → `activate()` → `activated` → a button's `trigger()` → a trigger volume entered → carried in the hand. The game picks the first rung the artifact actually has and says which. |

## Run it

```
# 1. the game, desktop, with the link armed
godot --path . --xr-mode off res://commons/scenes/desktop_map_tester.tscn -- --map=Point_One --vr-link
#    (headset: python tools/vr_link.py --arm once, restart the app)

# 2. the link server, playing the room as soon as the game attaches
python tools/vr_link.py --agent=Point_One          # or --agent alone: whatever map the game is in

# or, with the server already up (python tools/vr_link.py), from another terminal
python tools/vr_agent.py Point_One
python tools/vr_agent.py --live

# no game at all: the plan, and the map with the tour drawn on it
python tools/vr_agent.py Point_One --dry-run
```

The browser page at `localhost:8772` has two new buttons, **agent: play the room** and
**agent: plan only**; the tour is drawn on the top-down view and the walker's narration
streams into the log. Flags: `--no-interact` (look, do not touch), `--limit N`, `--speed`,
`--dwell`, and `--exit`, which is off by default because the teleporter moves the *person*
in the headset to the next map. The walker's `auto` verb never takes a teleporter.

The report lands in `ada_run/vr_agent_<Map>.md` (and `.json`): per work, how far it walked,
what it saw (distance, line of sight, extent, affordances), what the registry says it is,
what it did, and whether the grid's own `interactable_activated` confirmed it.

## What the tour is

Spawn → the nearest artifact's *approach cell* (a walkable 4-neighbour of the work that
no other work occupies) → the next nearest, by real path length → … → the teleporter.
Other works' cells are taken out of the walkable set for the length of a leg, so the
walker goes round a work, not through it. Floating text (`3t`) and `view_only` artifacts
are skipped and listed as skipped; a walled-off work is listed as unreachable, never
silently dropped. The plan is deterministic.

The game converts the cells it is sent with the grid that built the room
(`GridStructureComponent.grid_to_world`) and drops every waypoint onto the floor with a
ray, so the walker stands on the deck rather than at y=0 inside it — the `--calibrate`
doubt in `vr_link.py` is retired for cells, because the engine does the conversion.

## The walker has a body

`walker` with `body: true` builds the ghost as a `CharacterBody3D` on layer 20, the grid's
player layer, so an artifact's own trigger volume sees it walk in exactly as it sees a
player. It is **not** in the `player` / `player_body` groups and its name contains neither
"Player" nor "XR": DangerZone, QuitGameController, configurable_portal, jump_pad,
ResetPlayerController and subtitle_trigger all filter on exactly those, so the walker
crossing a fire zone costs the wearer nothing. Transport cubes and health crosses accept
`em_walker`, which it is. When the agent asks for a `touch` by name, the body is put in the
player groups for the length of one synchronous emit and taken out again.

## Protocol (newline-delimited JSON on 127.0.0.1:8771)

PC → game, by `cmd`: `ping`, `say{msg}`, `goto{pos}`, `walker_stop`,
`walker{path | cells, speed, loop, body, report, snap, cube, gutter, centre}`,
`scan{}`, `look{token | cell | index | pos, dwell}`,
`interact{token | cell | index | utility, verb}` with verb
`auto | interact | activate | signal | press | touch | grab | use | drop | teleport`,
`where{}`. A `tag` on any command rides back on its reply.

Game → PC, by `k`: `pose` (20 Hz), `log`, `pong`, `scene`, `seen`, `acted`, `ghost`,
`walker_done`, `activated` (the grid's `interactable_activated`, forwarded).

## What is proven, and where

- `python tools/test_vr_agent.py` — the plan against the real Point_One map (every leg a
  `MapGraph.neighbors` walk, every work once, legs round other works, the walled-off
  negative test), and the play against a **fake game** that answers the protocol: in
  process, then over `vr_link.py`'s real game socket and browser endpoints (`/agent`,
  `/events`, `/cmd`, `/state`), including the `activated` confirmations crossing the wire.
- `commons/testing/probe_vr_link_agent.gd` — the Godot side on a bench: four synthetic
  artifacts and a teleporter; `scan`, cells → world with the floor found by ray, `look`,
  every rung of `interact`, the transient player groups, grab/drop, and that `auto` never
  takes the teleporter. Run it with the headless line in its header. *It was written in a
  container without Godot and has not yet been run.*

## Known edges

- **The museum.** A hall has no `map_data.json` the engine will vouch for, so there is no
  graph. In the museum the agent falls back to what `scan` reports: straight legs to each
  live artifact in z order, floor found by the game's ray. It says so in the log.
- **XR Tools pointer targets** (sliders, knobs) are pressed through `XRToolsPointerEvent`,
  looked up by name at call time because the addon is gitignored; with the addon absent the
  verb reports that it could not.
- **Scan extent** counts `MeshInstance3D` only — the capture pipeline's caveat: a MultiMesh
  artifact reads as a point.
