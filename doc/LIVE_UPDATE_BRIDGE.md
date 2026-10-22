# Live JSON updates: web editor → desktop Godot → Quest

*2026-10-22. Brief: "Implement Live JSON Streaming from the Web Editor to Desktop and
Quest VR". Phase 1 is the audit below; the protocol, the adapter and the test
follow it in this file.*

## 1. Audit — what exists, measured on the working tree

### 1.1 The editor's save path (ada_encyclopedia)

| surface | writes | notifies Godot? |
|---|---|---|
| `/editor` (Three.js 3-layer editor, `src/app/editor/page.tsx`, `saveMap`) | `POST /api/voxel-editor {mapName, data}` → `commons/maps/<Map>/map_data.json` (compact rows) | no |
| `POST /api/map-studio` | same file, same format | no |
| `POST /api/map-edit {map, deltas}` | same file, cell deltas, `.bak` once | no |
| `/halls`, `/lines` (`/api/trunk` op `plan_apply`) | `tools/em_plan_write.py` → `commons/data/museum/em_plan.json` | indirectly (see 1.2) |
| `/editor/void` (`/api/void-layout`) | `commons/void/rooms.json`; carries a `revision` = content hash, checked on save | no (the Void has no watcher) |

A "move" in the Three.js editor is a **cell edit**: the interactables layer holds
`"<lookup>:<rotation>:<y_offset>[#key:value…]"` per cell, so moving an object is
clear cell A + write cell B. There is no object id in the canonical JSON. Identity
is `(map, layer, cell)`; the runtime carries it as node meta
`artifact_lookup_name` + `grid_cell` (grid maps) or `artifact_lookup_name` inside a
segment with meta `em_map` (museum). Values pass through
`GridInteractablesComponent._parse_interactable_token` and
`_apply_artifact_config` (typed coercion, `apply_grid_config`), never through code.

### 1.2 How desktop Godot detects a change today

**Grid map scene** (`desktop_map_tester.tscn`, or staging → `GridSystem`): nothing
watches `map_data.json`. `GridSystem.reload_map_setter(true)` clears every component
and re-reads the file from disk (`_reload_current_map`), but it is only triggered by
the Inspector tick-box or by `vrStaging._poll_quest_reload`, which polls
`user://reload_signal.txt` (nobody writes that on desktop). **Saving in the editor
does not update a loaded grid map.**

**Endless museum** (`endless_museum.gd`): `_edit_watch` polls at 1 Hz the mtime of
`em_overrides.json`, the open book page, and the `map_data.json` of the hall the eye
is in; a change → `_follow_reload()` → writes `ada_run/em_control.json`
(`resume_eye`, chapter, hall) and reloads the whole scene, resuming at the eye.
`_follow_check` does the same for `em_plan.json` (2 s poll, 2.5 s settle). So the
museum "updates" by a full scene rebuild, 2–10 s, and only on desktop:
`FileAccess.get_modified_time` on `res://` returns 0 inside a `.pck`, and
`_follow_check` is guarded on `res://ada_run/`.

**The plan trap (standing, memory `museum-stamps-from-plan-not-map`):** a
map-authored hall stamps its artifacts from the plan row (`entry.get("artifacts")`,
positions frozen by `tools/em_map_halls.py --apply`), not from `map_data.json`. A map
save is seen by `_edit_watch`, the hall rebuilds, and the rebuild re-reads the plan:
the edit is acknowledged and undone. The map→museum lane is
`em_map_halls.py --apply` + `em_bake.py`, not the save.

### 1.3 How the Quest bridge sends JSON today

`commons/bridge/vr_link.gd` (autoload `VRLink`, armed by `--vr-link` or
`user://vr_link.on`) dials `127.0.0.1:8771` with a non-blocking `StreamPeerTCP`;
`adb reverse tcp:8771 tcp:8771` makes that the PC over USB. Wire = newline-delimited
JSON both ways. Uplink: `pose` at 20 Hz, `log`, replies. Downlink commands are
dispatched in `_command()` from `_process` — **main thread, once per frame**, which
is already the safe apply boundary. Unknown `cmd` → `{"k":"log"}`; a `tag` rides back
on the reply. `tools/vr_link.py` is the PC end: game socket on 8771, HTTP on 8772
(`POST /cmd` queues a command, `GET /state`, SSE `/events`), `adb reverse` kept alive
every 10 s, ledger in memory only. Commands sit in ONE queue (`Link.out`) drained by
whichever game client polls first — with desktop and Quest both attached, a command
goes to one of them, not both.

Headset doctor (today): app installed 2026-10-20 13:51, build newer than
`vr_link.gd` (2026-09-28), armed, device attached. The installed APK can take
new commands only if the handler is in it: **the `update` command needs one APK
export; JSON-only changes after that need none.**

A second Quest lane exists and is file-based: `tools/push_map_to_quest.ps1`
copies a map into `files/override_map/<Map>/map_data.json` with `run-as`, and
`GridDataComponent._map_override_path` prefers it on Android; `-Live` writes
`reload_signal.txt` and `vrStaging._live_reload` calls `reload_map_setter`. Grid
maps only (`find_child("GridSystem")`); the museum has none.

### 1.4 What is missing

1. No notification from any save endpoint to a running Godot (desktop or Quest).
2. No in-place object update: desktop grid = manual full reload; museum = full scene
   reload from the plan; Quest = adb file push + full grid reload.
3. No broadcast: `vr_link.py` serves one game at a time for commands.
4. No revision envelope, no acknowledgement, no ledger of requested / transmitted /
   applied, no duplicate or obsolete rejection, no reconnect replay.
5. The Quest cannot read PC files, so a reload there needs the map carried over the
   wire (or the run-as push).

### 1.5 What is reusable (and is reused below)

- Transport: `vr_link.gd` ↔ `vr_link.py` (NDJSON, adb reverse, reconnect, `tag`).
- Apply boundary: `_command()` in `_process`.
- Placement: `GridInteractablesComponent._place_artifact` / `_parse_interactable_token`
  / `_apply_artifact_config` / `interactable_objects[Vector3i(x,y,z)]`,
  `GridStructureComponent.find_highest_y_at`, `GridSystem.reload_map_setter`.
- Quest persistence without adb: `user://override_map/<Map>/map_data.json`, read
  first by `GridDataComponent` on Android.
- Persist: the existing save endpoints (the canonical JSON stays the source of truth).
- Museum: `_edit_watch_own_write(path)` (lets a known write not trigger a rebuild).

### 1.6 Verified system diagram

```
/editor saveMap ──POST /api/voxel-editor──▶ map_data.json  (persist, canonical)
                                             │
                                             ├─ desktop museum: _edit_watch (1 Hz mtime) → _follow_reload → whole scene, from the PLAN
                                             ├─ desktop grid map: nothing
                                             └─ Quest: nothing (pck is read-only; user://override_map only via adb run-as)

vr_link.py :8771 ◀──TCP NDJSON──▶ VRLink autoload (desktop, loopback)
            :8771 ◀──adb reverse──▶ VRLink autoload (Quest)        pose 20 Hz up, cmd down, one queue
            :8772 HTTP  POST /cmd · GET /state · /events
```

## 2. The protocol — one envelope, one ack

Built on the audit: the transport is `vr_link.gd` ↔ `vr_link.py` unchanged in kind
(NDJSON, `adb reverse`, reconnect, `tag`), with one new downlink command and one new
uplink kind. Serialization lives in `ada_encyclopedia/src/lib/live-update.ts`,
application in `commons/bridge/live_update.gd`; `vr_link.gd` only routes.

```
cmd "update"                                       k "update_ack"
  revision_id   rev-<utc>-<sha8>  (editor)           revision_id, map_id, seq
  project_id    "ada"                                status   applied | rejected | conflict | requires_reload
  map_id        the map folder                       reason   duplicate | obsolete | already_current | not_loaded |
  base_revision sha256 of the file the editor                 invalid | busy | object_missing | museum_plan |
                started from ("" = unknown)                   resolved_by_reload | reload_unavailable | partial
  revision      sha256 of the file as saved          mode     in_place | reload
  seq           per map, monotonic (vr_link.py)      scene    grid | museum | none
  timestamp, source                                  ops      [{op, object_id, ok, detail}]
  operations    [{op:"set_cell", layer, at:[x,z],    device   OS.get_name() — Windows / Android
                  before, after, kind, object_id}    replay   true when the bridge re-sent it
                 {op:"move", layer:"interactables",
                  from, to, token, kind:"move"}]
  map_text      the saved file verbatim (optional)
```

- **Identity.** The canonical JSON has no object ids, so `object_id` is derived:
  `<map>/<layer>/<x>,<z>`. In the scene it resolves through the grid's own tags
  (meta `grid_cell` + group `vr_editable_artifact`). Cells are **map-local**; the world
  position is the grid rule (`x * (cube + gutter)`, seat on the cube top); the museum's
  segment-local frame is not touched (boundary C).
- **Move / rotate / scale / parameter / material.** All are cell-string edits in the
  token grammar `<lookup>:<rot>:<y>:<scale>#key:value`; the differ labels them
  (`move`, `parameter`, `replace`, `add`, `remove`) and the runtime parses them with
  `GridInteractablesComponent._parse_interactable_token` / `_apply_artifact_config`
  (typed coercion). **No code travels.**
- **Ordering.** `seq` is assigned by the bridge per map and restored from the ledger on
  restart; `seq <= last` is rejected `obsolete`; a `revision_id` seen before is
  `duplicate`. `base_revision != what the scene holds` is `conflict`, and the scene
  **resolves it by a full reload** from the file it can read (desktop: the working
  tree; Android: `map_text` written to `user://override_map/<Map>/`), then continues
  the lineage from that file's hash. A replay whose `revision` the scene already holds
  is `already_current`.
- **Reconnect.** The bridge re-sends a map's latest envelope whenever a game's pose
  **enters** that map (relaunch, or a headset that was in the menu when the edit was
  published). Never from the stale command queue — from the ledger, marked `replay`.
- **Threading.** Applied in `VRLink._process` between frames; a grid still generating
  defers the envelope (`pending`) and it is retried each frame, rejected `busy` after
  10 s. The player and XR origin are never touched by an in-place op.
- **Ledger.** `ada_run/live_updates.jsonl`: `{"k":"request", env (without map_text),
  "transmitted": n}` then one `update_ack` row per device, PC time in `t`, the game's
  clock in `game_t`. `GET :8772/revisions?id=<rev>` returns them; the encyclopedia proxies
  it at `GET /api/live-update?id=<rev>`, and `/editor` polls it after a save and prints
  `Windows: applied · Android: applied` in the save status.

## 3. The update boundary

| | what | how | where it holds |
|---|---|---|---|
| **A** in place | interactables cell edits on a loaded grid map | remove the node(s) tagged with that cell (and the dress plinth), place the new token through the grid's single-cell placer | desktop and Quest, no rebuild, player untouched |
| **B** reload | structure / utilities edits; token families the single-cell path does not build (`mc:`, `gridagent:`, `cluster:`, `criticalinfo:`); any `conflict` | `GridSystem.reload_map_setter(true)` — the lane `push_map_to_quest.ps1 -Live` already uses; on Android `map_text` is written to the override first | desktop and Quest; the grid rebuilds, the spawn component may reseat the player |
| **C** reported | an endless-museum hall | `requires_reload (museum_plan)`: a map-authored hall stamps from `em_plan.json`; the lane is `tools/em_map_halls.py --apply` + `tools/em_bake.py`, then the museum's own follow/rebuild on desktop (never on the Quest — the plan is in the pck) | not applied; the museum is not edited by this work |

A **pre-existing defect** found by the probe and fixed inside lane B only:
`GridSystem._reload_current_map` clears `interactable_objects`, which
`_place_artifact` never fills, so artifacts placed by a map load survive a reload
and **stack** under the fresh ones. `live_update.gd._remove_all_placed` frees them
before asking for the reload. The `-Live` push lane still has the fault.

## 4. Test — 2026-10-22, desktop (Windows), report `ada_run/live_update_test_20261022-092756.md`

Bench: `commons/maps/Live_Update_Bench/` (a copy of Point_One; the editor's own
save route `POST /api/voxel-editor`; vr_link.py started by the test; the game
`desktop_map_tester.tscn --map=Live_Update_Bench --vr-link`, windowed).

| step | revision | ack (Windows) |
|---|---|---|
| 1. move `point_corridor_door` (8,0) → (7,0) | `rev-20261022T072810Z-1c99abac` | **applied**, in_place: moved 1 node(s) [8,0] → [7,0] |
| 2. second update, (7,0) → (8,0) | `rev-20261022T072812Z-e3f3b69a` | **applied**, in_place |
| 3. invalid: `operations: "nope"` / `op: "teleport"` | HTTP 400 at the bridge / `rev-badop-…` | **rejected (invalid)**: unknown op teleport |
| 4. revision 2 posted again | same id, new seq | **rejected (duplicate)** |
| 5. game killed and relaunched; bridge replays rev 2 on map entry | `…e3f3b69a` replay | **rejected (already_current)** — never applied twice |

Bench probe (no socket, real GridSystem, Point_One): `godot --headless --path . --xr-mode off --script res://commons/testing/probe_live_update.gd` — 11 checks: move in place, old cell empty, position = cell world position, duplicate, obsolete, not_loaded, invalid, conflict → resolved_by_reload with the map standing as the file says (6 of 6 artifacts, no stacking), structure edit → reload. Compile check of both bridge scripts clean. `tools/test_vr_agent.py` has 5 pre-existing planning failures (dated before this work, unrelated to the link).

**Quest:** see section 8 for the headset leg.

## 5. Change inventory

| file | change |
|---|---|
| `commons/bridge/live_update.gd` | NEW — validation, lineage, apply (A/B/C), ack |
| `commons/bridge/vr_link.gd` | `update` command routed to the adapter; pending-retry drain in `_process`; grids hashed when hooked (first frame) and on `map_loaded` |
| `tools/vr_link.py` | `POST /update`, `GET /revisions`, `games` in `/state`; broadcast to every game client; ledger `ada_run/live_updates.jsonl` (seq restored on restart); replay on map entry; `update_ack` recorded |
| `ada_encyclopedia/src/lib/live-update.ts` | NEW — cell diff, envelope, `publishRevision`, `bridgeQuery` (server only) |
| `ada_encyclopedia/src/app/api/voxel-editor/route.ts`, `api/map-studio/route.ts` | after the write: diff old/new, publish, return `live` |
| `ada_encyclopedia/src/app/api/live-update/route.ts` | NEW — read-only proxy to the bridge's ledger/state |
| `ada_encyclopedia/src/app/editor/page.tsx` | save status shows the revision and each device's ack |
| `commons/testing/probe_live_update.gd` | NEW — bench probe |
| `tools/live_update_test.py` | NEW — end-to-end driver with a report |
| `doc/LIVE_UPDATE_BRIDGE.md` | this file |

Not touched: `endless_museum.gd`, `GridSystem.gd`, `GridInteractablesComponent.gd`,
`vrStaging.gd`, `push_map_to_quest.ps1`, `/api/map-edit` (its cell deltas could call
`publishRevision` the same way — one line, left for the next milestone so this one stays
small). Unarmed games (no `--vr-link`, no `user://vr_link.on`) are byte-for-byte
unaffected: `VRLink._ready` still disables processing.

## 6. Next milestone

1. **Quest leg as routine:** the `vr_link.py --headset` doctor should also say whether the
   installed build knows `update` (it dates the build against `vr_link.gd`; add
   `live_update.gd`).
2. **`/api/map-edit` and the research loop** publish through the same call.
3. **Museum lane (boundary C → A):** the hall's plan row and bake are derived from the
   map; a `requires_reload (museum_plan)` ack could trigger `em_map_halls.py --apply`
   for that map on the PC and let the desktop's existing follow do the rest. Not an
   in-place museum edit — the museum is not to be edited from here.
4. **Many games, named:** acks carry `device`; a `hello{role:"game", name}` from the
   game would let the ledger name two desktops apart.
5. **The AI loop the brief defers:** an agent proposing a revision uses exactly
   `publishRevision` — nothing else is needed on the wire.

## 7. The Void — the editor Palle uses (`/lab-editor?mode=void&floor=N`)

Palle (2026-10-22): "this is the editor I can to use". That editor is not the grid
editor: it saves **`commons/void/rooms.json`**, one document for the whole tower
(18 floors), each floor a record with `artifacts` and `props` keyed by `id` and placed
by free transforms — `position [x,z]`, `height`, `facing`, `scale`, plus `config.parts`.
So the brief's op list (move, rotate, scale, parameter, add, remove) is literal here.

**Audit of that path (verified):**
- `src/components/lab-editor/VoidEditor.tsx` autosaves through `LayoutSaveQueue` →
  `POST /api/void-layout {rooms, revision}`; the route validates with
  `tools/validate_void_rooms.py`, and `src/lib/void-layout-store.ts::saveLayout` refuses
  the save (409) unless `revision` equals the sha256 of the file on disk, backs the old
  file up to `ada_run/void-editor-backups/`, writes atomically, mirrors to Desktop/Ada Void.
  **The Void already had a revision and a conflict rule; the envelope reuses that hash.**
- The game (`commons/void/floor_content.gd`) reads rooms.json once (`room_source.gd`,
  `--void-draft=<path>` for a draft), keeps it in memory as `data`, builds a floor's mounts
  named by record id (`<id>` for artifacts, `Prop_<id>` for props; `exhibits["%d/%s"]`),
  streams floors around the player (`floor_stream.gd`), and has its own per-floor rebuild:
  `reset_floor(i)` + `load_floor(i)` (the checkpoint lane in `game.gd`). No watcher; the
  editor's own message says "Restart The Void to load the latest arrangement."
- Desktop: `void.tscn` runs standalone (`-- --void-start-floor=N --vr-link`). Quest: the
  main menu's **The Void** entry (`MainMenu3D.gd`) loads the same scene.

**What was added (same transport, same adapter file, a Void branch):**

| where | change |
|---|---|
| `src/lib/live-update.ts` | `diffVoidFloors` (per floor, by id; `transform` when only position/height/facing — props: position/facing/scale — changed; else `parameter` / `replace` / `add` / `remove`; other floor keys → `void_floor`), `publishVoidRevisions` — one envelope per changed floor: `project_id:"void"`, `map_id` = trial or `void`, `floor_id`, `floor_map`, `floor_record` (the floor as saved), `base_revision`/`revision` = the layout hashes |
| `src/app/api/void-layout/route.ts` | reads the file before `saveLayout`, publishes after it, returns `live[]` |
| `VoidEditor.tsx` | after a save, polls `/api/live-update?id=` and writes `Live rev-… → floor 10: Windows applied in_place · Android applied …` in the message line |
| `commons/bridge/live_update.gd` | `_apply_void`: transform-only ops move the mount in place and patch the in-memory record; anything else replaces the floor record and runs `reset_floor` + `load_floor` on that floor only (the stream's residency record is dropped first, as game.gd does); a floor that is not resident only gets its record replaced and builds from it when entered (`mode: "data"`) |
| `commons/bridge/vr_link.gd` | the pose carries `proj:"void"` (+ `trial`), and the Void's rooms file is hashed when first seen |
| `tools/vr_link.py` | replay keys on `proj`/`trial` for the Void |
| `tools/live_update_test.py --void --floor 10` | the Void flow of the end-to-end test |

**Boundary for the Void:** A in place = transforms (not an artifact's `scale`, which
also sizes its plinth and lamps); B = one floor rebuilt in place (config, parts, add,
remove, walls, route, painted construction, any conflict) — the player, the
architecture and the other floors stay, but a visitor standing on painted construction
of that floor will drop while it rebuilds; C = nothing written to disk by the game: the
Quest's pck stays at the exported rooms.json until the next export, and a relaunch
converges through the replay only while the bridge's ledger holds the revision.

**Test — 2026-10-22, desktop, `ada_run/live_update_test_20261022-095245.md`**
(void.tscn on floor 10 with `--vr-link`; the real `/api/void-layout` save):

| step | revision | ack (Windows) |
|---|---|---|
| 1. move `museum-primitives_profiles-15-1` (film_profile_travels) [-10,-6.5] → [-8.5,-6.5] | `rev-20261022T075310Z-1d94ba59-f10` | **applied**, in_place: moved to [-8.5, -6.5] facing 0 |
| 2. back to [-10,-6.5] | `rev-20261022T075311Z-a0c87017-f10` | **applied**, in_place |
| 3. `op: "teleport"` | `rev-badop-void-…` | **rejected (invalid)** |
| 4. revision 2 again | same id | **rejected (duplicate)** |
| 5. relaunch; replay on entering the Void | `…a0c87017-f10` replay | **rejected (already_current)** |

rooms.json after the run is byte-identical to the file as it stood after the last save
by another editor session (09:52:51), i.e. the round trip left it as found. The grid
probe (11 checks) still passes with the Void branch in place.

## 8. Headset — 2026-10-22, both devices at once, report `ada_run/live_update_test_20261022-101452.md`

APK `ada_run/apk/ada_live_update_void.apk` (export preset `adaresearchonexy`, `--export-debug`,
18 min), installed with `adb install -r`, launched with `adb shell monkey -p <pkg> …` (the OS
runs it only while the headset is worn). The link was armed from an earlier session
(`user://vr_link.on`); the bridge's `adb reverse` made the headset dial in on boot. Palle
entered **The Void** from the main menu and stood on floor 10; the desktop ran `void.tscn
--void-start-floor=10 --vr-link` at the same time. Every revision went to both games.

| step | revision | Windows | Android |
|---|---|---|---|
| 1. move film_profile_travels [-10,-6.5] → [-8.5,-6.5] | `rev-20261022T081513Z-cb28572b-f10` | applied, in_place | **applied, in_place** |
| 2. back to [-10,-6.5] | `rev-20261022T081515Z-39d1a717-f10` | applied, in_place | **applied, in_place** |
| 3. `op: "teleport"` | `rev-badop-void-…` | rejected (invalid) | **rejected (invalid)** |
| 4. revision 2 again | same id | rejected (duplicate) | **rejected (duplicate)** |
| 5. desktop relaunch, replay on entry | `rev-20261022T081515Z-39d1a717-f10` replay | rejected (already_current) | — |

rooms.json byte-identical to the start. No APK rebuild between revisions; the change was
visible in the headset without leaving the floor.

Two earlier passes on the headset the same morning, kept for the record:
- 10:11 (`…101135.md`): Palle was on another floor — Android answered `applied, mode: data`
  (the floor's record replaced, built when entered), and the desktop answered the FIRST
  revision with `conflict (resolved_by_reload)`: the bridge's replay-on-entry re-sent a
  **ledger revision older than the file the desktop had just loaded** (a save made while
  the bridge was down leaves no envelope), and the conflict rule reloaded the floor from
  that stale record before the live edit corrected it. Fixed: **a replay is best effort, a
  live save is authoritative** — on the desktop a conflicting replay is `rejected
  (stale_replay)`; on Android, whose pck is older than every ledger revision by
  construction, it still converges by the reload (`live_update.gd::_stale_replay`). The
  installed APK predates that one rule; its Android behaviour is the intended one.
- 09:57 / 09:58 (`…095709.md`, `…095813.md`): the first APK (grid lane only, no Void
  branch) in the Void answered `rejected (not_loaded)` for the moves and `rejected
  (invalid)` for the bad op — the honest answers for that build, and the proof that the
  `update` command reached the headset over USB.

## 9. Milestone 2 (2026-10-22, same day, Palle: "yes")

| item | done |
|---|---|
| doctor knows the `update` command | `vr_link.py --headset` dates the installed build against `vr_link.gd` **and** `live_update.gd` (git date or the newer mtime in a dirty tree) |
| `/api/map-edit` publishes | the research loop's cell deltas go out as a revision through the same `publishRevision`; the response carries `live` |
| games are named | the game sends `hello{role:"game", name:"Windows/<host>" or "Android/<model>"}` once per connection; every ack row in the ledger carries `name`, and `GET :8772/state` lists `game_names` |
| museum lane, opt-in | `python tools/vr_link.py --museum-apply`: a `requires_reload (museum_plan)` ack runs `tools/em_map_halls.py --apply` (the one writer of map cells into the live plan), once per 60 s, in a thread, with start/done rows in the ledger; the desktop museum's own follow rebuilds the hall. The bake (`tools/em_bake.py`, a Godot run) is deliberately NOT started by the bridge — the hall prints `UNBAKED … (re-bake)` until it is run. Off by default: the plan is shared derived state, and a live museum must not have it rewritten underneath it without the person at the keyboard asking for it |

Not done, on purpose: a `hello` is not yet required for a game to count (an old build without it still works, unnamed).

### 9.1 Headset with the milestone-2 build — 11:23, `ada_run/live_update_test_20261022-112310.md`

APK `ada_run/apk/ada_live_update_hello.apk` installed 11:08. Palle on floor 10, desktop on
floor 10: both answered as **`Android/Quest 3`** and **`Windows/SIRENS`** — move applied in
place on both, move back applied in place on both, invalid rejected, duplicate rejected,
replay on relaunch `already_current`; rooms.json byte-identical. (A run at 11:08, before
Palle reached floor 10, had the headset apply by record, `mode: data`, as designed.)

## 10. Blender — a third live editor (2026-10-22, Palle: "can we add blender to the pipeline?")

`tools/blender/ada_void/` is a Blender 4.2 add-on (bpy only, no pip; `python
tools/blender/build_zip.py --install` zips, installs and enables it; the panel is the
3D viewport sidebar › **Ada Void**). It adds no second implementation of anything above:
it is one more client of the two things that already exist.

| step | what it calls | the web editor's own |
|---|---|---|
| **Import floor n** | `GET /api/void-layout` (rooms + **revision**) and `public/void-models/manifest.json` (the glTF export, `tools/export_void_trial.py main`): the floor's structure glb, each artifact's glb or its parts' glbs with their default poses, the props' catalog glbs, the exported lamps and `Label3D` texts | yes — the same payload `/lab-editor?mode=void` renders in Three.js (`void-model.ts::listEntries`) |
| **Publish** | reads the mounts back into the floor's records (artifact: position / height / facing, + scale if changed; prop: position / facing / scale; part: `config.parts`; route: position / height), writing **only what changed**, then `POST /api/void-layout {rooms, revision}`; a 409 re-reads the server's document, puts this floor's read-back on top and retries once; then it reads the acks from `GET /api/live-update?id=` and prints them in the operator report and the panel | yes — `src/lib/void-layout-store.ts::saveLayout` + `publishVoidRevisions` + the ledger proxy; nothing new on the wire |
| **Live** | a `depsgraph_update_post` handler notes a transform change on a mount; a timer publishes 0.5 s after the last change, never while a request is in flight (HTTP in a thread, bpy only on the main thread), revision refreshed after a 409 | the editor's `LayoutSaveQueue` autosave, in Blender's terms |
| **Cycles setup** | Cycles on the GPU (OptiX → CUDA → CPU), the export's evening sky bake as the world, the sun from `lighting.sun_matrix`, a camera at the route's **Arrival** waypoint looking along the route, 1920×1080, AgX; optional fog volume | — |

**Frames.** Every record is an Empty **named by its record id** that carries the record
transform; the glb meshes hang under it, so moving the Empty is the edit. Godot is Y-up and
Blender Z-up; Godot's `GLTFDocument` writes Godot axes straight into the glb and Blender's
importer applies `(x, y, z) → (x, −z, y)`, so a mount sits at `(x, −z, height)` with its
`facing` as the rotation about Blender +Z, same sign (`frames.py`). Measured, not assumed:
`headless.py` reads the first translated node out of the raw floor glb and checks where the
importer put it (floor 10: raw `[0, −0.18, −6]` → Blender `[0, 6, −0.18]`, error 0), checks
the film artifact `museum-primitives_profiles-15-1` at record `[−10, −6.5]` h 0.035 lands at
Blender `(−10, 6.5, 0.035)`, and checks that an untouched import reads back to the **same
document** (0 changes over 4 artifacts, 17 parts, 2 props, 10 waypoints of floor 10 — the one
mismatch found on the way, a part rotation of 180 reading back as −180, is settled on the
circle). Lamps, cameras and `Label3D` planes carry Godot's −Z-forward / +Y-up convention and
get one extra quarter turn about X after the change of basis.

**What does not survive the glTF export** (and so is not in a Blender render): procedural
shaders (a `ShaderMaterial` is exported as a static colour preview — 380 of them on the
2026-10-22 export), particles, animation, physics and every behaviour, viewport textures,
Godot's fog / tone mapping / light units (energies are converted with a rough factor).
`Label3D` text is re-created from the manifest's label data as Blender text objects, in a
Blender font. Walls and painted construction are not imported and stay untouched in the record.
Full list: `tools/blender/ada_void/README.md`.

**Test — 2026-10-22 12:35, desktop, `ada_run/live_update_blender_test_20261022-123554.md`**
(`python tools/live_update_blender_test.py`: void.tscn on floor 10 with `--vr-link`, Blender
headless `blender -b -P tools/blender/ada_void/headless.py`, the real `/api/void-layout` save):

| step | revision | ack |
|---|---|---|
| import floor 10 (2.4 s), axis conversion, known record, read-back identity | — | 4 checks PASS |
| 1. move `museum-primitives_profiles-15-1` (film_profile_travels) +1.5 m in x from Blender, publish | `rev-20261022T103644Z-24c6853f-f10` | **Windows/SIRENS applied in_place** |
| 2. move it back, publish | `rev-20261022T103656Z-c32a850a-f10` | **Windows/SIRENS applied in_place** |
| rooms.json afterwards | byte-identical | yes |

Save → request at the bridge → desktop ack: about 2 s; each publish step took ~11 s only
because the bridge had transmitted to **two** games and the add-on waited (up to 10 s) for the
second: the Quest was attached and posing on floor 10 but answered neither revision in these runs
(it answered the same two moves at 11:23 from the web editor's save — a paused app streams no
acks). The add-on now waits 4 s at most for a silent device. The first run of the day
(`…120648.md`, same verdict) measured 41 s per import and 49 s per publish: **writing the 800 KB
rooms document into a `bpy.types.Text` datablock costs 34 s** (one long line); it lives on a
scene ID property now (0 s). Render: Cycles/OptiX on the RTX 3070, 256 samples, 31 s →
`ada_encyclopedia/public/book-images/live-update/floor-10-blender.png`, from the **overview**
camera — floor 10's `Arrival` waypoint stands inside a large profile body, so the route camera
photographs the inside of a part (that camera is still made; the panel picks either).

| file | change |
|---|---|
| `tools/blender/ada_void/` | NEW — `frames.py` (axes), `chain.py` (HTTP), `floor_import.py`, `publish.py` (publish, 409 retry, live), `render_setup.py`, `headless.py`, `__init__.py`, `README.md` |
| `tools/blender/build_zip.py` | NEW — zip + `--install` |
| `tools/live_update_blender_test.py` | NEW — the end-to-end test with a report |
| `ada_encyclopedia/src/app/live-update/page.tsx` | a Blender section with the render |

Not touched: `commons/void/`, `src/lib/live-update.ts`, `/api/void-layout`, `vr_link.py`,
`live_update.gd` — Blender is a client of them as they are.

## 11. The spawn menu — Garry's Mod's spawnmenu, from the spine (2026-10-22, Palle: "do 2 then 3")

Palle: a prefab add menu like Garry's Mod's, but "we should not use the outside prefabs;
the prefabs we have built in the sequences we can use". Three pieces, each a client of
what already exists.

**1. The list is derived, never written.** `python tools/build_void_spawnlists.py` →
`commons/data/void_spawnlists.json`: `curriculum_spine.json` (25 sequences in order) → each
sequence file's maps → each map's `interactables` layer (the artifacts standing there) →
joined to the artifact catalog (`validate_void_rooms.py --catalog`: label, scene, footprint,
`map_ready`) and the artifact-gallery capture manifest (thumbnails, `/artifact-gallery/captures/
<token>/<angle>.png`). 25 sequences, 209 maps, 1016 artifacts (857 map_ready, 728 with a
thumbnail after a capture-manifest refresh; 288 never captured). The Void's own construction
props (`catalog.json`, Source-referenced) are left out on purpose. Served read-only at
`GET /api/void-spawnlists[?seq=<id>|?q=<text>]` (encyclopedia) and `GET :8772/spawnlists`
(the bridge, for a headset). `--check` says when the file is stale.

**2. `add` and `remove` are in-place lanes now** (`live_update.gd::_void_add / _void_remove`):
an artifact record is built through the Void's own `floor_content._build_artifact` (mount named
by id, `exhibits["%d/%s"]`, supply, reactions — what `load_floor` would do for it), a prop through
`SetDressing.build`; a remove frees the mount and forgets its registry key; the in-memory floor
list is patched so a later `reset_floor` rebuilds it where it stands. Nothing is written to disk
by the game. Verified `tools/live_update_spawn_test.py` (the editors' save route, floor 10,
`ada_run/live_update_spawn_test_20261022-141920.md`): add → **Windows applied in_place**, op
`add` ok ("spawned on floor 10 at [-14, -6.5]"); remove → **applied in_place**, op `remove` ok;
rooms.json byte-identical. `replace`, `parameter`, an artifact's scale, walls, route, copies and
painted construction still rebuild the one floor.

**3. The hand asks, the bridge saves, the revision comes back.** `commons/bridge/spawn_menu.gd`
(+ `spawn_menu_ui.gd/.tscn`) is created by the `VRLink` autoload the first time it sees the Void
— the link carries the request, so the menu exists exactly where the link does. In VR it is an
XR Tools `Viewport2Din3D` on the left controller (toggle: the controller's menu / Y button; the
right hand's own `FunctionPointer` clicks it — the panel takes that pointer's collision mask as
its layer); on desktop the same `Control` in a `CanvasLayer`, toggled with **B**. Left pane: search
+ the tree sequence → map; right pane: the thumbnail grid, "Remove last", a status line. Picking a
tile sends `{"k":"spawn", floor, token, position [x,z], facing}` up the link — floor from the
game's `floor_stream.floor_at(eye y)`, the point 2 m ahead of the right hand (2.5 m ahead of the
camera on desktop) in that floor's `Content<n>` frame, facing turned towards the player, snapped to
0.25 m / 15°. `tools/vr_link.py` (`Link.spawn`, a thread) GETs `/api/void-layout`, appends
`{id: spawn-<token>-<hhmmss>, artifact, station NW, position, height 0, facing, scale 1,
config.editor_label}` to that floor, POSTs `{rooms, revision}` — the editor's own route validates
(422 refuses, e.g. off the slab), saves, diffs, publishes — and answers the asking game with
`cmd spawn_result {ok, id, revision_id, warnings | error}`. The revision then reaches every game
as an in-place `add`; the menu prints the bridge's answer and this game's own ack
(`VRLink.update_acked`) on the panel. "Remove last" is `{"k":"spawn_remove", floor, id}` on the
same lane. `POST :8772/spawn` is the HTTP twin (tests, the AI loop). `adb reverse` now covers
tcp:8772 too, so the headset reads `/spawnlists` and `/thumb/<token>/<angle>.png` from the PC.
Thumbnails on desktop come straight from `ada_encyclopedia/public` beside the repo.

**Test — 2026-10-22 14:29, the bridge lane, `ada_run/live_update_spawn_test_20261022-142949.md`**
(`python tools/live_update_spawn_test.py --via-bridge --game-log …`: void.tscn on floor 10 with
`--vr-link`, the bridge restarted on the new code):

| step | bridge | ack (Windows/SIRENS) | on the panel (game log) |
|---|---|---|---|
| `POST :8772/spawn {floor 10, token film_profile_travels, position [-14,-6.5]}` | 200, id `spawn-film_profile_travels-143019`, `rev-…ded40510-f10` | **applied in_place**, op add ok | `spawn-film_profile_travels-143019 add: … spawned on floor 10 at [-14, -6.5]` |
| `POST :8772/spawn {floor 10, remove: that id}` | 200, `rev-…c32a850a-f10` | **applied in_place**, op remove ok | `… remove: … removed from floor 10` |
| rooms.json afterwards | byte-identical | | |

The same game log shows the menu's own life: `[spawn-menu] created` when VRLink first saw the
Void, `spawnlists: {items 1016, maps 209, sequences 25, with_thumbnail 728}`, `desktop layer
ready (toggle: B)`. The VR mount (the wrist panel, the menu button, the right-hand laser) runs
only with a headset: the APK `ada_run/apk/ada_spawn_menu.apk` carries it; the panel's wrist
transform (`spawn_menu.gd`: 7 cm up, 9 cm forward, tilted 55°) is a first guess to fine-tune in
the headset, as the grid-era `HandWorkstationVR` said of its own.

**14:55 — floor 3, worn.** Palle, with the 14:46 build on, moved a work in
`/lab-editor?mode=void&floor=3` (Point Lines, 47 artifacts) and watched it move on the
headset: "Yes, that worked." The first floor other than 10 to carry the chain, and the
first time the person editing and the person wearing were the same.

## 12. The hand message and grab-and-move (2026-10-22 15:xx, Palle: "lets do the hand message and VR grab-and-move next")

**The hand message** (`commons/bridge/hand_message.gd`, created by `VRLink` beside the spawn
menu): every revision this game answers (`VRLink.update_acked`, i.e. the ack `live_update.gd`
just produced) and every answer the bridge gives a spawn / move / remove from this hand
(`spawn_result`) becomes one line on the left wrist — a `Label3D` 16 cm above the controller,
turned to the eye, held 6 s, the last three lines stacked — and a toast bottom-left on desktop.
It reads the ack, not the wire: `floor 3 · museum-point_lines-31-12 moved to [-16.75, -2.5]
facing 0 · in place`, `floor 3 rebuilt: parts rebuilds the floor`, `floor 7 · changed while you
were elsewhere; it builds when you arrive`, `refused: conflict — …`, `spawned spawn-… · saved as
…`. The quiet refusals (`already_current`, `duplicate`, `obsolete`, `stale_replay`) say nothing:
nothing changed.

**Grab-and-move** (`commons/bridge/void_grab.gd`, owned by the spawn menu; active while the menu
is open = edit mode): the right trigger on a work picks up its **mount** — the record's node
(`<id>` / `Prop_<id>` under `Content<n>`), found by a ray on every physics layer (the Void's
pointer mask is handles / pointables / UI, most works are not on it) through the collider's
ancestry, or the nearest mount within 1.5 m of a hit on the slab — and drags it on the plane it
stands on; the thumbstick turns it (90°/s). On release: snap 0.25 m / 15°, then `{"k":
"spawn_move", floor, id, position, facing}` up the link; `vr_link.py` (`Link.spawn`, the `move`
branch) rewrites that record's `position` / `facing` and saves through `POST /api/void-layout`;
the revision returns to every game as a `transform` applied in place — this game included, which
re-seats the mount exactly where the file says. A refused save (422 off the slab, 409) snaps the
mount back. On desktop: menu open (B; the panel now takes the left 55 % of the screen), left-drag
in the view, Q / E turn. `POST :8772/spawn {floor, move: id, position, facing}` is the HTTP twin.
Not the artifact's own grab logic: a carried point light stays a carried point light.

**Test — 2026-10-22 15:21, the move lane, `ada_run/live_update_spawn_test_*.md` (`--move
museum-primitives_profiles-15-1 --game-log …`, void.tscn on floor 10, the bridge restarted
on the move code):**

| step | bridge | ack (Windows) | the hand message (game log) |
|---|---|---|---|
| `POST :8772/spawn {floor 10, move: museum-primitives_profiles-15-1, position [-8.5,-6.5]}` | 200, moved, `rev-…132119Z` | **applied in_place**, op transform ok | `floor 10 · museum-primitives_profiles-15-1 moved to [-8.5, -6.5] facing 0.0 · in place` |
| same, back to [-10,-6.5] | 200, `rev-…132122Z` | **applied in_place** | `… moved to [-10.0, -6.5] facing 0.0 · in place` |
| rooms.json afterwards | byte-identical | | |

The game log also shows `desktop layer ready (toggle: B; drag in the view to move, Q/E turn)`
and `desktop toast ready`. The wrist label and the trigger grab run only with a headset: APK
`ada_run/apk/ada_hand_grab.apk`.
