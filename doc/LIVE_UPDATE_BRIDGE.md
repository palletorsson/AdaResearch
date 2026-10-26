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

## 13. The proposal lane — propose, review, accept (2026-10-22, the deferred AI loop's first half)

The brief of section 2 deferred the AI workflow. What was built instead is the lane an AI
(or anyone who cannot be trusted with the save button) would use: a **proposal** is a
revision somebody would like to see, filed as one small JSON document, reviewed by a
person in the editor that owns the file, and applied — on Accept — **through that
editor's own save path**, so the revision check, the validator and the publish of sections
2 and 7 run unchanged. Nothing is applied by itself; nothing in `commons/void/` or the
bridge's apply code changed.

| piece | where | what |
|---|---|---|
| **the store** | `ada_run/live_proposals/<id>.json` (git-ignored, derived) | one file per proposal: `{id, target: "void"\|"map", map_id, floor_id, trial, operations, source, note, created_at, status, decision}`; never the canonical file |
| **the API** | `ada_encyclopedia/src/app/api/live-update/proposals/route.ts` | `POST` files one (shape-checked: known ops only, a Void op cannot target a map and vice versa), `GET ?target=void&floor=N` / `?target=map&map=X` lists the pending ones **in words**, `?all=1` everything, `?id=` one; `PATCH {id, decision, by, revision_id}` records a decision |
| **the words** | `src/lib/live-proposals.ts` (node-free) | the op vocabulary live-update.ts already labels a diff with — move / add / remove / change / replace / structure / utility, transform / floor — as `describeOperation`; `live-update.ts` re-exports it so there is one list. `applyVoidOps` is the pure apply onto a floor record |
| **the strip** | `src/components/live-update/ProposalsStrip.tsx`, mounted under the header of `/lab-editor?mode=void` (`VoidEditor.tsx`) and above the toolbar of `/editor` (`editor/page.tsx`) | polls the pending proposals for the open floor / map every 4 s, shows each as `source: note · n op` + the first operation in words (click to unfold all), **Accept** and **Reject** |
| **Accept** | `VoidEditor.applyProposal`, `editor/page.tsx::applyMapProposal` | Void: `mutate(f => applyVoidOps(f, ops))` and `LayoutSaveQueue.flush()` — the autosave a hand edit takes (`POST /api/void-layout`: 409 on a stale revision, `validate_void_rooms.py`, `publishVoidRevisions`); the revision id the save produced is read back for the ledger. Grid map: the ops land on the artifact list and the layer refs, `saveMap(next)` (the same `POST /api/voxel-editor`, diff, publish), then the map is re-read from disk. Refused with a reason when it cannot land (missing id, occupied cell, a cell inside a folded collection, nothing changes) — the proposal then stays pending |
| **Reject** | the strip | records the decision; the file is untouched |
| **the ledger row** | `tools/vr_link.py` `POST /proposal` → `{"k":"proposal", id, decision, by, revision_id, target, map_id, floor_id, source, note, ops}` in `ada_run/live_updates.jsonl` | written by the encyclopedia on every decision; `GET /revisions?id=<rev>` returns it beside that revision's request and acks. The bridge writes nothing else for it — the apply arrived as an ordinary `/update`. The decision is written into the proposal file whether or not the bridge is up (`decision.ledger` says) |
| **the CLI** | `tools/live_update_propose.py` | `--void --floor 10 --move <id> --dx 1.5 [--dz] [--facing]`, `--set <id> key=value …`, `--remove <id>`; `--map <Map> --move-cell 8,0 7,0`, `--set-cell x,z "<token>" --layer …`; `--json file`; `--list [--all]`, `--read <id>`. Reads the current file to fill `before` (so the strip says "from … to …"), posts to the encyclopedia, writes the store directly when it is down |
| **the test** | `tools/live_update_proposal_test.py` | starts the bridge and the game if asked, files the proposals from the CLI, prints the editor URL, waits for the person's clicks, checks the ledger after each; report in `ada_run/live_update_proposal_test_<stamp>.md` |

An agent's whole interface is therefore `POST /api/live-update/proposals` (or the CLI): it
never touches a canonical file, never talks to the bridge, and never sees a save button.
What it sees afterwards is `GET ?id=` — accepted with the revision id, or rejected.

**Test — 2026-10-22 16:09, desktop, `ada_run/live_update_proposal_test_20261022-160908.md`**
(bridge restarted on the `/proposal` code; `void.tscn --void-start-floor=10 --vr-link`
launched by the test; the clicks made in `/lab-editor?mode=void&floor=10` through the browser):

| step | proposal | decision (strip) | ledger |
|---|---|---|---|
| A. CLI: move `museum-primitives_profiles-15-1` +1.5 m in x | `prop-20261022T140949Z-672d5e` | **Accept** → `rev-20261022T141100Z-28bd7b7d-f10` · ledger row written | `request` → `update_ack` **Windows/SIRENS applied in_place** (1 of 1 on floor 10) → `proposal accept by lab-editor`, the three rows side by side under one revision id; rooms.json places it at [-8.5, -6.5] |
| B. CLI: a second move, +3.0 m | `prop-20261022T140949Z-301e8d` | **Reject** · ledger row written | `proposal reject by lab-editor`, no request, file unchanged |
| C. CLI: move back −1.5 m | `prop-20261022T141120Z-7f90af` | **Accept** → `rev-20261022T141141Z-b4c45362-f10` | `update_ack` applied in_place; rooms.json **byte-identical** to the start |

14 checks PASS. The same morning on `/editor`: a bench copy of Point_One, the CLI's
`--map Live_Update_Bench --move-cell 8,0 7,0`, the strip showing `move point_corridor_door
from (8, 0) to (7, 0)` once the map was loaded, Accept → `rev-20261022T141316Z-a4a946b0`,
the door at (7, 0) in the file, the proposal row in the ledger (no grid game attached, so no
ack — the save was still live-published, `transmitted 0`). Note the editor's own save wrote
the tokens back with an explicit `:0` y-offset, as a hand save in `/editor` does.

**Before / after, in the editor (Palle, same afternoon: "or even better before and after view in
the web editor?").** Each pending proposal has a **Preview** button. In `/lab-editor?mode=void` it
puts a clone of the open floor with the operations applied (`applyVoidOps`, the same pure apply
Accept uses) in front of the scene: `entries` and `VoidScene.document()` draw from `previewFloor ??
rooms.floors[i]`, so the AFTER state renders through exactly the path a saved floor takes, from a
record the editor never saves (`rooms`, which autosave watches, is untouched). **Before / After**
flip the view with the camera where it stands — a fixed camera is what makes the two comparable;
*Focus object* first if the work is out of frame — the changed records are selected (highlighted)
as a hand selection would be, the legend reads `PREVIEW: with proposal · <source>`, and **Close**
(or Accept / Reject, or changing floor) puts the saved floor back. While a preview stands `mutate`
refuses with a message, so a drag cannot write a preview into the file. In `/editor` the artifact
list is swapped for the proposal's after-list the same way (interactables only; a structure or
utilities cell is reported as "shown on accept only") and restored on Before / Close; Accept
restores first and applies from the saved list. Verified 2026-10-22 16:4x on floor 10 with
`prop-20261022T144238Z-0cd58a` (move the film work 4 m east, 3 m north, turn 90°): After shows it
at [-6, -9.5] facing 90, Before at [-10, -6.5] facing 0, Close leaves the floor "Saved" with nothing
selected; the proposal is left pending for the hand to try.

**Boundaries.** A proposal is a WISH about a file: the editor's document at accept time is
what the ops land on, so a proposal filed against a floor that has moved on may land
differently from its `before` (the strip shows both) or be refused. The strip shows
proposals for the **open** floor / map only. A folded collection in `/editor` (count > 1)
refuses a move of its master and cannot see its members — move those by hand. Nothing
expires: a pending proposal waits until a person decides; `--list` shows the backlog.

| file | change |
|---|---|
| `tools/vr_link.py` | `POST /proposal` — one ledger row per decision, nothing else |
| `tools/live_update_propose.py`, `tools/live_update_proposal_test.py` | NEW |
| `ada_encyclopedia/src/lib/live-proposals.ts`, `src/lib/live-proposal-store.ts`, `src/app/api/live-update/proposals/route.ts`, `src/components/live-update/ProposalsStrip.tsx` | NEW |
| `src/lib/live-update.ts` | re-exports the op words |
| `src/components/lab-editor/VoidEditor.tsx` | the strip; `applyProposal`; `previewProposal` + `previewFloor` (the scene draws from the clone); `mutate` refuses during a preview; the save callback keeps the last `live` result |
| `src/app/editor/page.tsx` | the strip; `applyOpsToArtifacts`, `applyMapProposal`, `previewMapProposal` (list swap + restore); `saveMap(override?)` returns the response |
| `src/app/live-update/page.tsx` | a paragraph |

Not touched: `commons/void/`, `commons/bridge/`, `/api/void-layout`, `/api/voxel-editor`,
the differ, the apply boundary. Forum: 261022-f86oo.

## 14. The pipeline, drawn and live (2026-10-23, Palle: "can we work on a visualization of the pipeline?")

`/live-update/pipeline` (`ada_encyclopedia/src/app/live-update/pipeline/page.tsx`; `/pipeline`
was already the book-production pipeline) draws every lane of §§ 1–13 as one sepia-on-paper
figure — three rows, *where a change is made* (web editor, Blender, VR hand, agent proposal,
voice memo dashed as not yet in the loop), *the truth and its route* (save route, rooms.json,
bridge, ledger), *where it is seen* (desktop, Quest, hand message), and a faint *derived*
column (spine → spawnlists, glTF export, Blender renders) — and reads the bridge's ledger
every two seconds: a request pulses save route → file → bridge → each transmitted game, an ack
pulses back game → bridge → ledger → editors coloured by its answer (green in place, amber a
floor rebuilt, red refused) and on to the hand message, a proposal pulses agent → editor.
"Replay" runs the last 24 ledger events through the picture; "Export SVG" saves the still.
The still is also at `public/book-images/live-update/pipeline.svg`.

Two things it needed: a clock without `requestAnimationFrame` (the desktop app's pane does not
fire it; a 40 ms interval drives the pulses), and **history across a bridge restart** —
`vr_link.py::_load_ledger` now puts the file's last 400 rows back into the in-memory ledger, so
`/revisions`, the editors' status lines and this page show the day rather than an empty one
(before: a restarted bridge answered `rows: []`).

## 15. The five layers in three.js (2026-10-23, Palle's "Full System Architecture" map)

`/live-update/architecture` (`src/app/live-update/architecture/page.tsx`, data in
`src/lib/system-architecture.ts`) stacks the map's five layers as slabs — 01 research at the
bottom, 02 authoring, 03 truth and transport, 04 world and evidence, 05 writing on top — with
each layer's nodes standing on its slab (36 nodes) and 50 edges as tubes coloured by kind: ink
data, green acknowledgement, violet the two research loops, amber proposed, faint derived.
Node fill says status: working, derived, proposed, not yet connected. The bridge's ledger
pulses through the tubes live (the same `rowToEdges` reading as the flat figure); "Replay"
runs the last 24 events; a slider spreads the layers; checkboxes hide derived, proposed, loops,
labels; click a node for its text, files, connections and — in amber — where the 23 October
map and the measured system differ. Render loop on a 33 ms interval (no rAF in the app's pane).

Where the map was corrected in the data: the spawnlists are consumed by the VR hand today (the
API exists; the web and Blender menus are not built); an applied update does not always rebuild
a floor (transform / add / remove apply in place, config / parts / walls / route rebuild one floor,
a floor you are not on gets its record); Blender reads the glTF export, Godot makes it; the
endless museum (lane C, reported not applied) and the grid-map lane are absent from the map and
present here. Agreed with the map, and now drawn: authority is scoped (§ 5), the agent is one
more proposal producer on the same route (§ 6), and the voice memo is the one authoring
position not yet in a loop.

**Made clearer the same morning (Palle: "how can we make this clearer" → "yes"):** the page opens on
the live loop alone (data + acknowledgements; research loops, proposed and derived come in by their
boxes); every node has a lane column kept across the five layers so cross-layer tubes are near-vertical
plumbing; labels are constant-screen-size sprites (title only, the detail in the panel; back-row labels
sit higher); a tube's label appears on hover; clicking a node dims everything but it and its
neighbours and flies the camera to it, clicking a layer title tilts to that layer, the paper lets go;
and **Trace a revision** walks the newest *answered* revision from the ledger through the stack in six
captioned steps — the editor saves, the route checks and writes, the diff goes to the bridge and the
ledger, the broadcast to N games, each game's actual answer, the ack on the wrist and back in the
editor — camera following each tube.

**Real things, not boxes (Palle: "make real items like the book, the wiki, a ledger, VR set, a
data table … to make it concrete" → "yes build it"):** `src/lib/architecture-models.ts` builds each
node as a low-poly thing in the page's paper-and-ink style — three bound books on the top slab
(final.md violet, tutorial.md amber, technical.md blue and OPEN on the pipeline figure), a stack of
pages for the encyclopedia, an open register for the ledger whose lines fill from the live rows, a
single folded-corner sheet for rooms.json and map_data.json, a 25-cell data table for the spine
and the sequences (names from /api/void-spawnlists), a headset for the Quest, a monitor for the
desktop showing the evening render and one for Blender showing the book render, a hand with its
wrist panel (the hand message's panel reads "floor 10 · moved · in place"), the real floor-10
structure from the glTF export stacked three storeys for the tower, a colonnade for the museum,
two framed prints of the actual renders, a bridge whose piers are stamped 8771 and 8772, a gate
for the save route, a microphone in dashed outline for the memo, an envelope for the agent's
proposal, trays, a camera, a wire cube for glTF, a branch graph for Git, a card index for the
registry, trees for the lineage and the capacity tree, nested wire boxes for the LOD tree, a crate
stamped "release". Every model fits 2.6 × 1.3 and reports its height; a glass box over it takes
the click; front-row labels name the overview, back-row labels appear when their layer or node is
in focus. Each node names its shape in `system-architecture.ts` (`shape`).

**Stills for the book:** the architecture page has **Export PNG** (3200 × 2000 of a fixed print pose —
the whole stack from the front-right, labels a step smaller — then back to the live view) and
`window.__adaArchitectureStill(w, h)` for a scripted grab; `POST /api/live-update/still {name, dataUrl}`
saves one into `public/book-images/live-update/`. First still: `architecture.png` (23 Oct). The flat
figure's still is `pipeline.svg` beside it.

## 16. The knowledge tree, built from itself (2026-10-23, Palle's construction grammar)

`/knowledge-tree` (`ada_encyclopedia/src/app/knowledge-tree/page.tsx`; grammar + builders in
`src/lib/knowledge-tree.ts`): Palle's grammar — point + mesh(color) + collider = sphere_collider,
dist(point, point) = line, line + association(surface) = tape, line + skin + collider = plank,
line × 3 = triangle, face(3 edges), triangle × 2 = quad, quad × 6 = cube, association(cube) =
wooden_box · concrete_block · cardboard_box · warhol_box, assemblages, Melencolia (sphere vs
triangle shapes), pick_up_cube, grids, balls_test_grid, logic, sine, sine_surface, trace_test,
topology_test, random_cubes, noise_space — as 51 things on ten shelves (point, line, association,
triangle, solid, assemblage, transformation, array, logic, motion), ordered by depth along each
shelf (9 generations from point to noise_space). **Each thing's three.js model is built by calling
its parents' builders and adding only what the expression adds**, with every part tagged by the
parent it came from; the "construction" slider slides each part back toward that parent's cell, so
the construction shows on the table itself. Edges are the `from` relations; a darker plinth means
the registry has an artifact of that name (`artifact`, 24 of 51 — grab_sphere_point, timber_plank,
parallel_lines, cross_lines, quad, tetrahedron, pyramid_blocker, wedge_blocker, cardboard_box,
pick_up_cube, grid_2d_4x4, random_cubes, noise_space …), and the panel shows its gallery capture.
Export PNG writes `public/book-images/live-update/knowledge-tree.png` (top-down print pose).

## 17. The modular class system — kernel (2026-10-23, Palle: "build a modular class system for everything … to sculpt out the tutorial path")

`commons/modular/` is the kernel; nothing in it is a scene per thing.

| file | holds |
|---|---|
| `terms.json` | the 51 terms, each `{chapter, label, expr, from, build}` — `build` is an expression over primitives (`p`: point, mesh, collider, body, grabbable, label, light) and other terms (`t`), joined by operators (compose, associate, times, array, assemblage, engine, transform). One source for the game, the web tree and the tutorial path |
| `composite.gd` / `.tscn` | the one artifact: reads a term (export, `config_term` meta from the registry's default_params, or its lookup name `mod_<term>`), builds it at ready, rebuilds on `apply_grid_config`; `describe()` counts meshes, colliders, bodies, labels and the terms used |
| `builder.gd` | the operators; every sub-term node carries meta `term`, every primitive meta `primitive`, so the built tree stays legible (the scanner, the probe and the explode view read it); a `body` / `grabbable` part makes the composed thing a StaticBody3D / RigidBody3D / Area3D / XR Tools pickable so its colliders are direct children and work |
| `mod_mesh.gd` | sphere, box, plane, cylinder, cone, torus, wedge (PrismMesh), tetra, pyramid, triangle, dodeca (hand-wound, Godot winds clockwise) |
| `mod_surface.gd` | the associations as materials: stripes, red, hazard, wood, concrete, cardboard, warhol, plastic, paper — applied to every mesh but the construction marks (points, strokes, colliders' shells) |
| `mod_body.gd`, `mod_grabbable.gd`, `mod_label.gd`, `mod_point.gd` | bodies and colliders (+ `make_rigid`), the XR Tools pickable (plain RigidBody3D without the addon), Label3D captions, the ink point |
| `mod_behaviour.gd` | the engines: physics (static sphere_colliders become rigid and fall), trace (dots where the falling body went), hand (a sphere along a drawn path), sine, sine_field, noise (seeded value noise), random (seeded jitter), logic (the gate names) |

**Registry:** `commons/artifacts/registry/modular.json` is GENERATED by `tools/build_modular_registry.py` — 51 tokens `mod_<term>`, all on `composite.tscn`, `default_params {term}`, `configure_before_ready`, `map_ready`, footprint by chapter. The validator's catalog reads it, so the tokens are placeable in rooms.json and in a map at once, and the wrist menu lists them as a second tree ("Built from the grammar", `tools/build_void_spawnlists.py`).

**Verified:** `commons/testing/probe_modular.gd` builds every term headless — 51 of 51, no body without a collider (`ada_run/modular_probe.json`); the depth guard counts term references only (a term containing itself trips it, operator depth does not). `tools/live_update_spawn_test.py --via-bridge --token mod_tape`: the term spawned on floor 10 of the live desktop Void through the bridge, **applied in_place** both ways, rooms.json byte-identical, the hand message printing it. `capture_multi_angle.gd --mode=artifact --target=mod_tape` photographs it (two ink points, the stroke, the striped surface); all 51 tokens are being captured for the wrist menu's thumbnails.

**The scanner:** `tools/modular_scan.py` reads each registry artifact's scene AND script (node types, `.new()` classes, preloads; ~770 of the spine's scenes are one scripted root) into `commons/data/modular_signatures.json` — primitives, parts, behaviour, interaction — and matches the primitive set to a term. On the spine: 1081 artifacts, 952 with a mesh, 442 a collider, 100 grabbable, 639 a behaviour; 961 matched *some* term, but the match is containment of primitive sets and so lands on the small terms (point 292, trace 290, walk_line 244): a hypothesis layer, honest about being coarse. Structure (which part is made of which) needs the terms authored, not scanned.

**The tutorial path:** `tools/modular_path.py` → `doc/book/course/MODULAR_PATH.md`: the 51 terms in derivation order inside their chapters — each lesson with its expression, what it is made of, what it becomes, the registry artifacts the scanner reads as it and the spine maps they stand in (8 of 51 lessons already have rooms to stand in). Every lesson is a spawnable token, so a lesson can be stood in before it is read.

Two traps for whoever extends it: a new `class_name` is not in the headless class cache on a fresh checkout, so the kernel refers to its own scripts by `preload` path and never by name (the first probe failed on `ModularBehaviour.new()` and on the probe's `ModularComposite`); and a cycle guard that counts operator depth fires on honest deep terms (topology_test nests six levels) — count term references only.

**The studio (Palle: "each object like the line should be a bit of a visual gate … it has to look sexy good; build in
three.js first so we can sort out the relations"):** `/modular-studio?term=<id>` — one term at a time, large, on paper with
a shadow and a turntable; the construction PLAYED (parents first, then what the expression adds, then a violet gate ring);
"apart" slides the sub-terms away from the centre; the expression is edited on the right (label, words, chapter, parents,
the build JSON) with Preview, Revert and **Save to terms.json** (`POST /api/modular-terms`, atomic, refuses a term that
contains itself) — the same file the Godot kernel builds from. `src/lib/modular-terms.ts` is the three.js twin of
`commons/modular/builder.gd` (same expression language, same layouts and surfaces; engines drawn as resting poses and
marks). Arrow keys walk the derivation path; space replays; "Still" writes `public/book-images/live-update/modular-<id>.png`.
The 51 modular tokens have gallery captures now (all 51 with a thumbnail in the wrist menu), and the tree page shows
each term's own capture beside the sequences' artifact.

**The scaffold (Palle, 23 Oct: "the point should be a white point, until we change to line then black. In the
animation just keep the intended object — when animating tape remove the line and sphere in the end"):** a part of a
build may carry `"scaffold": true` in `terms.json` — the line inside a tape, plank or stick; the triangle inside a
triangle_face; the point inside a sphere_collider. It is shown while the construction plays and fades out as the gate
closes, so the tape ends alone; "keep the scaffold" in the studio brings it back. The Godot kernel frees the scaffold
nodes after the build unless `show_construction` is set (an export on `composite.gd`, also a config key), so a spawned
`mod_tape` is the tape and nothing else — `capture_multi_angle` confirms it, as does `probe_modular` (51 of 51 still
build; the freed line leaves the tape its mesh). The point is white (`ffffff`) on its own and both builders tint it ink
once it is built inside another term (`depth > 0`): the line's two points are black, the lone point is white. Both
rules live in `builder.gd` and `modular-terms.ts` alike, so the studio and the game agree.

**The ink stroke (Palle, 23 Oct: "make a shader for the line and make the line less wide"):** the line's stroke is
4 mm wide now (radius 0.004, was 0.01) and a mesh part may name a shader: "shader": "ink" wears
commons/modular/shaders/ink_stroke.gdshader in the game and the inkMaterial ShaderMaterial in the studio, the same
three ideas in both: the ends taper like a pen lifting (width 0.55 at the tips, full in the middle), the silhouette
darkens as wet ink does (a fresnel term), and a faint grain along the length breaks the flat shade. The stroke counts
as a construction mark, so a surface (tape, wood) never paints over it. Only the line term carries it; every term
built from line inherits it. Verified with capture_multi_angle on mod_line (windowed) and the studio at ?term=line.

**The plan for the whole spine (Palle, 23 Oct: "make a plan to integrate all the spine in a list"):**
`python tools/modular_spine_plan.py` writes `doc/book/course/MODULAR_SPINE_PLAN.md` — one row per spine sequence
(maps, artifacts, what the scanner reads them as, the chapter, the terms to author, the kernel piece it waits
for), the eight-step loop a sequence goes through, six build waves ordered by what the kernel needs (vary,
recurse/rewrite, connect/boolean/shader axis, the heavy engines, synthesis) and the 18-piece kernel work list.
82 proposed terms over 18 new chapters; proposals live in the script, terms are saved from the studio.

**The plan drawn (`/modular-plan`):** the 25 sequences in spine order, each with its Void floors as columns and
every artifact as a cell coloured by what it becomes — twin (189, one reconstruction per floor beside the primary),
swap candidate (53, already a small term; Palle's call per floor), document (213: films, plaques, screens, sliders;
never a construction), kept (993). Data from `commons/data/modular_spine_plan.json` (the generator writes it beside
the markdown), served by `/api/modular-plan`; "Still" writes `public/book-images/live-update/modular-spine-plan.png`.
The synthesis sequences carry meta-terms: compare (crisis_table, self_member — the kernel's refusal of a
self-containing term is the Russell exhibit), parametrize (axis_sweep, lambda_dial, phi_dial), rewrite (open_term,
after_table, commons_table). The change sequence has no floor in the Void.

**The plan, compressed (Palle, 23 Oct: "fold the compressed version into the plan. how would it look in three.js"):**
`tools/modular_spine_plan.py` now writes the compressed plan: five kernel pieces (connect, by, replicate, step, field)
instead of eighteen, 44 families with dna axes (89 variants) instead of 82 terms, the seven spine phases as chapters
instead of seventeen new ones, four waves instead of six, connect in wave 1, the done gate = every floor's primary has
a twin (189). `/modular-plan/3d` stands it up in three.js: a kernel bench with the five pieces drawn as constructions
in the grammar, then 25 stations in spine order — existing terms built by the Builder, proposed families as dashed
translucent blocks (width = variants, ticks = axis values), plinth height = wave, floor tint = phase. Still:
`public/book-images/live-update/modular-spine-plan-3d.png`.

**Edges and leaks in the kernel (Palle, 23 Oct: "where does leaks, edges go?"):** a kernel piece is a rule, so its
parameters are its edges, of the thirteen material kinds in `doc/EDGE_INVENTORY.md` — connect is Coupling, replicate's
depth a Ceiling and its minimum size a Deadband, by's index a Quantiser, step's tick a Clock and radius a Ball, field's
threshold a Deadband and its subtraction a Mask. The plan declares eleven of them with what escapes and what spills
to `LeakData`; six families inherit a named material edge from the artifact they twin (fractal: the Cantor set's
MIN_SEGMENT_WIDTH). The scaffold is the kernel's first leak in code: `composite.gd` spills the line inside the tape
to the bus (kind "scaffold", rule "composite.scaffold:<term>") before freeing it — `probe_modular_leak.gd` proves one
entry for tape, none for point. Named, never counted, as the bus insists.

**The knowledge tree's three new layers (Palle, 23 Oct: "wire the first three layers into the knowledge tree"):**
`/knowledge-tree` now reads `/api/modular-plan`. Joints: every arc is coloured by the kernel piece that made its
child (compose, associate, transform, replicate, by, step, connect, field — `PIECE_OF` in `src/lib/knowledge-tree.ts`),
so a thing assembled, repeated or behaving reads differently; the panel says "made by". Families: the plan's 44
proposed families stand as dashed translucent blocks on seven extra shelves named after the phase chapters, the width
of their variants with a tick per axis value, a dashed arc to the tree node their expression leans on; click one for
expression, axis, what it needs first, the edge it inherits — "a proposal until saved in the studio". Shadows: a ring
under each thing, one band per edge its piece declares, and the panel lists what the piece refuses and what it spills.
Still: `public/book-images/live-update/knowledge-tree-layers.png`.

**Coverage of the spine's principles (Palle, 23 Oct: "not only the heroes are relevant, I mean all principles. Are they
covered?"):** no. `tools/modular_coverage.py` reads every `truth`, `learning_objectives` line and `content` line of the
25 spine sequence files (420 principles) and matches them lexically against the 51 terms, the 44 proposed families and
the five kernel pieces: 122 covered, 39 reached only by the kernel, 259 uncovered (`doc/book/course/MODULAR_COVERAGE.md`,
numbers also in `modular_spine_plan.json` per sequence). The uncovered are not missing things; they are verbs —
compare (104), measure (67), procedure (47), retain (45) — so the proposal is a sixth kernel piece, `measure`
(read a value, retain it, compare it under a rule), the instrument half of the grammar. Proposed, not added.

**`measure` is the sixth kernel piece (Palle, 23 Oct: "add measure as the sixth piece").** In the plan generator: the
piece (read a value off a thing, retain it across steps, compare it under a rule), its three edges (quantiser on
resolution, window on the record, coupling on the comparison rule), wave 1, and eight families that stand on it —
length (primitives), velocity_readout (forces), entropy_meter (randomness; shannon_entropy_meter stands there),
spectrum_reading (wavefunctions), rule_census (cellularautomata), field_probe (isosurfaces), loss_meter
(machinelearning), dial_reading (qfeplaboratory). Coverage moved from 122 to 150 of 420 principles covered. The
knowledge tree colours measure arcs plum; the 3D bench has six pieces, measure drawn as a line with its length read
beside it. Not in `builder.gd` / `modular-terms.ts` yet: the families are proposals until authored in the studio.

**The spine as grammar text (Palle, 24 Oct: "can we do this for all the spine but with a symbol in the text for
prefabs"):** `tools/modular_spine_text.py` writes `doc/book/course/MODULAR_SPINE_TEXT.md` — one paragraph per spine
sequence in Palle's notation (a + b, a * n, association(), transform(), replicate(), by(), step(), connect(), field(),
measure(), = names what it makes), the primitives paragraph in his own words, the other 24 continued from each
sequence's truth and its maps' content lines. A name in [square brackets] is a PREFAB that exists in the registry or
the spawn lists (kit: and prop: prefixes stripped; nested registry files read); 568 named, 0 unknown — an unknown one
would print as [?name]. The text is authored in the script; regenerate after editing it.

**Drag a program (Palle, 24 Oct: "I want to be able to drag program in pseudo code. A net of prefabs. Plank + ball =
skateboard. Cube * 6 + plank = EU pallet … the beginning of logic if you add a ball. Add some strings. Sort
deconstructed EU pallet"):** `/modular-program` — palette of operators (+, *, array, association, transform, by, step,
sort, assemblage), the grammar's terms by chapter and the registry's prefabs with their captures (drag onto a block, or
select a block and click); the program as nested blocks; the pseudo code the blocks spell in the spine-text notation;
the JSON the kernel builds (editable); the thing built live by the studio's Builder; Save writes a term to terms.json
(`POST /api/modular-terms`), so it spawns from the wrist menu as `mod_<name>`. Two kernel pieces grew for it, in both
builders in the same change: `{"p":"prefab","token":…}` — a registry artifact standing in the grammar as itself (the
game instantiates the scene the spawn lists name; the page shows a box of its footprint wearing its capture) — and
`{"op":"sort","of":…,"by":size|height|width|name}`, measure's first operator (each part read, laid in a row by the
reading; `_aabb_of` measures before the node is in the tree). Palle's four examples are terms in chapter assemblage:
skateboard, eu_pallet, tilt_gate (step(plank tilted + ball, physics): the ball rolls one way), pallet_sorted.
Probe: 55 of 55 build.

**The handover of 24 Oct, built as a slice (`doc/book/course/MODULAR_HANDOVER_AUDIT.md`):** `/modular-program` renders
the sentence with symbol chips (a term's chip is the game's capture of mod_<id>; Save snaps `symbol-<id>.png` so `=`
makes an icon at once); expand / deconstruct (every instance of every leaf, sorted by type, `_lineage` kept) /
reassemble on the selected block; `connect` (rope|rod|spring between two parts by index) in both builders —
`tied_pallet` uses it; `sort` by type. `probe_tilt_gate.gd` runs the physical if for 180 ticks, authored and
mirrored: ok, right / left. `tools/visual_memory_atlas.py` draws 16 symbols into one self-contained PNG with the
canonical AST beside it; a blind reader (image only) recovered 16/16 names, parents and root operators and 14/16
counts — the two misses were definitions the tile cut with "…". Probe 56/56.

**Typed sentences parse (24 Oct, "continue to build"):** `parseSentence` in `modular-terms.ts` turns a sentence in
the notation into the same JSON the blocks make — `+`, `* n`, `array`, `association`, `transform(at/rot/scale)`,
`step`/`by`, `sort`, `connect(i-j kind)`, `assemblage`, `[prefab]`, `= name` — with the error marked at its character;
the program page has a sentence box. The notation folds a run of identical parts into `(part) * n`, on the page and in
the atlas. The visual-memory experiment ran three times: 14/16 counts with cut tiles, 16/16 with room, and a
pictures-only run that named simple things well, could not tell the tied pallet from the pallet, and exposed the
blank grab_sphere capture. Results in MODULAR_HANDOVER_AUDIT.md § 4.

**/modular-program, improved (24 Oct, "can we improve it"):** the sentence is the program and sits on top — symbol
chips with the game's captures, clickable (a chip is a block), the `=`, the name, save/update; a typed sentence
parses in the line under it. Below, three columns: the palette (start from an example with its picture, the
operators, the terms with their pictures, the registry's prefabs), the blocks (icons in the heads; at / rot / scale
editable on a transform; expand, deconstruct, reassemble; undo, redo, clear; Delete removes, ⌘Z / ⌘Y), and a taller
viewport with "play the construction" (space) and an "apart" slider. The page starts from the skateboard.

**Block ↔ thing (24 Oct, "keep going"):** the three.js Builder tags every node with `userData.path`, the address of
the block that made it (parts by index, `of` as −1), so on `/modular-program` the selected block's objects glow
violet and a click on an object selects its block; a chip dragged onto another chip moves the block; a prefab leaf
loads the registry's glTF export (`/api/artifact-gltf`, 650 of them) fitted to its footprint — `[pick_up_cube]`
stands as the real cube with its ring. Chip-to-chip drag could not be exercised with synthetic events in the
browser pane; the three other features were.

**The joint behind the tie (24 Oct, "go"):** under the physics engine every `connect` tie becomes a joint
(`mod_behaviour.gd::_tie_joints`): rope = a pin at the near end (a taut rope: the far end swings at the rope's length;
slack is not modelled, Godot has no distance joint), rod = a 6-DOF joint with linear and angular play locked, spring =
a 6-DOF linear spring on each axis at rest where the parts stood; a part without a body gets a static anchor. The
`pendulum` term hangs a ball beside a cube on a rope. `probe_tied_rope.gd`: with the rope the ball keeps 0.50 m while it
swings down; without the tie it falls 28 m away; a rod keeps 0.50. 59 terms build.

## 18. Headset — 2026-10-24, the modular kernel on the Quest (installed, not yet walked)

`ada_run/apk/ada_modular_kernel.apk` (885 MB, preset `adaresearchonexy`, `--export-debug`, 16 min) installed on the
attached Quest at 13:25:55 (`adb install -r`, versionName 2026.10.23). Inside the APK: the 22 files of
`commons/modular/` (the kernel scripts as .gdc, `composite.tscn`, `terms.json` with 59 terms, the ink shader),
`commons/artifacts/registry/modular.json` and `commons/data/void_spawnlists.json`, so every `mod_<term>` is spawnable on
the headset through the bridge. The bridge is up (`tools/vr_link.py`, `adb reverse` 8771/8772 set). The app was
launched with `adb shell monkey`; the OS runs it only while the headset is worn, so the live spawn to the headset —
`python tools/live_update_spawn_test.py --via-bridge --token mod_pendulum` — waits for a person in the headset standing
in The Void. Until that ack is in `ada_run/live_updates.jsonl`, VR is installed, not evidenced.

**The spine, disassembled (Palle, 25 Oct: "can we disassemble to extract the element and categorize every artifact
in the spine?"):** `tools/disassemble_spine.py` runs `commons/testing/disassemble_spine.gd` once per sequence under the
watchdog: every placed artifact is instantiated, builds for two frames, and its ELEMENTS are read off the tree it made
(meshes by shape, size and colour; colliders; bodies; joints; lights; labels; particles; multimesh counts; whether a
script ticks). Ledgers in `ada_run/disassembly/<seq>.jsonl` (resumable; a killed run charges the artifact in progress
as "hang"); census in `commons/data/spine_disassembly.json` and `doc/book/course/SPINE_DISASSEMBLY.md`, with a category
per artifact read from its elements (point, line, solid, array, field, assemblage, document, empty, void-built, hang;
·engine when it ticks) and its elements written in the grammar's notation, identical meshes folded to (shape) * n.
First run: 1331 artifacts, 1 hang (rhizome_inside), 239 void-built, 31 empty; 752 tick.

**New assemblies for the game (Palle, 25 Oct: "a prefab field of cones, a spring connected net that can be placed over
another object to follow its outline"):** `cone_field` = by(array(plastic_cone, 4 × 4), random) — the random engine
now takes `term` (which term it jitters), `lift`, `turn`, `vary_scale`; `net` = connect(6 × 6 sphere colliders, every
neighbour, rope) — 36 knots, 60 strings; `net_over_cube` = step(block 0.8 m + net above, physics): the net falls,
rests on the block and its margins hang (`probe_net.gd`: inside 0.83 m, outside 0.65 m, nothing flies off);
`curtain` = a vertical net whose top row is points (static anchors) — it hangs; `bead_chain` = point + 7 beads on
ropes. Three faults found and fixed on the way: a tie's joint was positioned BEFORE it joined the tree, so a parent's
offset moved it (the net as a term fell through its block; the direct net did not — `probe_drop.gd` told them apart);
sixty 6-DOF springs between free bodies blew a net to ten metres, so nets are tied with ropes (pins) and springs are
for pairs; freed bodies now use continuous collision. The drawn ties follow their bodies under physics
(`_follow_ties`), so a net under physics looks like a net.

**The logic machines (25 Oct, "let go"):** five machines built from the grammar, each term carrying its own `logic`
block — frame, movers, named inputs (what drops where), named outputs (regions), and the truth table as cases:
`or_gate` (a funnel with end walls over a bin), `and_gate` (a cup holds one ball; the second rolls over the low lip into
the tray), `not_gate` (a ball always runs down the ramp and along the run, unless a brick is in its way),
`branch_gate` (IF/ELSE: a roof; where the ball lands decides the bin), `domino_line` (one push, eight dominoes, a delay
line). New movers `ball`, `brick`, `domino`; the physics engine frees the terms a machine names (`"free": [...]`).
`commons/testing/probe_logic.gd` builds every case and reads every output: **15 of 15 at 60 Hz and at 90 Hz** (the
headset's rate). A mutant copy (`--terms=`) with the AND cup walled and the IF/ELSE inputs swapped fails 3 cases, so the
check bites. Found on the way: the probe first resolved frames by name from the real terms.json, so a mutant frame never
reached the physics (`probe_and_trace.gd` showed the real lip being rolled over); it now builds the frame from the file
it loaded, and only a full run on the real terms writes `ada_run/logic_truth_<hz>hz.json`, which `/modular-program`
shows beside each machine (declared, then measured). The program page also runs without WebGL now.

**The construction path (Palle, 25 Oct: "a next and previous gallery … starting in point. So the object and how it is
being constructed"):** `/construction-path` walks every thing Ada has in one order — 1358 steps on the working tree:
97 grammar terms, 1016 registry artifacts the spine places, 245 works The Void builds itself. Data from
`tools/construction_path.py` → `commons/data/construction_path.json`. Default order: per spine sequence, its terms in
derivation order (a term never before its parents — 0 violations), then its artifacts in map order. Each step shows the
object and how it is built: a term's notation, "made from" (earlier) and "becomes" (later); an artifact's elements read
off its tree. The order is Palle's to decide: drag the list, ↑ / ↓, "move to #", Save (a complete permutation only;
`/api/construction-path`); the tool keeps an authored order and slots new steps after their default predecessor.

**The main track and its branches (Palle, 25 Oct: "not every term has to be on the main track … what is the main
principle that we need to flow … a good progress of relevant difference"):** the principle is ONE STEP, ONE NEW
CAPACITY — one new kind of relation to space, the body, time, other things or a reader. Eight principle axes with
ordered notches: form (point · line · surface · solid · field), body (seen · collides · falls · graspable), many (one ·
repeated · at scale), parts (one kind · a few · many kinds), joint, drive (a function of time), react (physics ·
decides), measure. Colour, scale, surface, place and the count of identical parts are not axes: they vary a thing, and
make a branch. Staging (a label, a lamp, a sensor) is not an axis either — the new `exhibit` operator (both builders)
wraps any thing in all three, and `exhibit_cube` shows it. `terms.json` now carries a `track` list, 15 terms and one
hole: point → line → quad → box (a solid you see) → cube (collides) → falling_cube → pick_up_cube → cube_row →
elevated_plank → pendulum → sine_movement → lattice (216 boxes) → skateboard_3 → pallet_sorted → and_gate → *a field*
(the hole: the grammar has no field operator). New terms `box`, `falling_cube`, `cube_row`, `lattice`, `exhibit_cube`
fill the gaps the gate found. `tools/capacity_track.py` reads every signature off the SAME instantiated trees for terms
and artifacts (the disassembler now reads the mod_ tokens too, `--seq=modular`, and counts triangles of generated
meshes) and gates the track: each step must exceed the envelope of the steps before it on exactly one axis by exactly
one notch (falling brings obeying physics with it). **Gate OK on the full re-disassembly (1435 rows); a mutant track
(lattice before cube_row, falling_cube removed) fails four steps and exits 1.** Every other term and every artifact
hangs off its nearest step by notches; a tie goes to the step it lacks least of (a variation, not a precursor), then to
the later one. 1015 artifacts read: 575 within one capacity of their step; 167 go beyond the whole track on form and wait
on the field hole (isosurfaces, CSG booleans, generated surfaces) — the clearest measure yet of what the field operator
would unlock; 33 built nothing in two frames and are unread, not points. Reader faults the gate's first runs exposed:
the line "added composition" by counting its end points (parts now count only kinds of comparable size); 53 artifacts
read as points because MultiMesh instances and CSG shapes have no mesh bounds (form now read off the replicated shape;
CSG is the boolean hole); a 10 cm grab sphere read as a point (a point has nothing to touch); and 105 physics things tied
between falling_cube and and_gate went to the gate by the later-step rule. Blind spot, kept visible: a tree cannot show
a decision, so no spine artifact reads as react 2 and and_gate has no artifact branches. `/construction-path` now walks
the track by default (each step followed by its branches, closest first; the parts a track term is made of come just
before it; 0 parent-after-child), with a "the track only" filter, ⇐ / ⇒ step buttons, tall ticks on the strip, a red
hole, and a panel that says which step a branch hangs off, on which axes it differs, and that its staging is covered by
`exhibit`. "by sequence" keeps the older order as a reading (not editable).

**The tree of life (Palle, 25 Oct: "the shape is it a tree or is some other git structure … if you would visualize it
as the tree of life how would it look?"):** `/tree-of-life` draws the spine as Haeckel's Stammbaum. It is three
structures and a walk: the TRUNK is the main track (a line — git's first-parent history); the LIMBS make a tree (every
term and artifact hangs off exactly one step, the closest at the heart of its crown); the violet threads are MERGES
(terms made of parents on other limbs — composition makes the whole a web, as symbiogenesis makes the tree of life and
merge commits make git); a SEQUENCE is a walk across the crowns. The fallen leaves on the ground have no tree to
measure. The trunk is mutable on the page: move, remove or insert steps (the panel lists the terms that would add exactly
one notch at a step, the collection's artifacts that would if written as terms, the exact examples, and whether a swap
keeps the gate green); the gate and the re-hanging run live in the browser (a port of `tools/capacity_track.py`) and
the leaves fly to their new limbs. Save posts to `/api/capacity-track`, which runs `capacity_track.py --propose`: it
gates the proposal again and writes `terms.json` only if it passes, appends the version to
`commons/data/capacity_track_history.jsonl` (the trunk's own lineage, loadable from the page) and regenerates the
path. Tested: a failing proposal exits 1 with terms.json byte-identical; an accepted one (in a sandbox copy) keeps the
file's format and writes two history rows (origin + mutation). Finding on the first look: every spine sequence
"climbs" (next artifact on the same step or higher) only 52–75 % of the time — no sequence follows the trunk yet.

**The timeline from the point — morphospace (Palle, 25 Oct: "if we see it as a time line starting with the point
that can help to get the right shape … whatever the shape is I can flow it … the shape does not even exist or have
materialized until now"):** `/morphospace` lets the collection draw its own shape. Every term and artifact is a point in
capacity space; things sharing a signature are one species. Height is time: a thing with n notches can exist no earlier
than step n of any trunk, so the rows rise from the point one notch at a time. Measured: 1076 things in 149 species of
4320 possible signatures (3.4 % of the space made); things per row 1, 6, 20, 43, 118, 170, 175, 162, 183, 134, 51, 12, 1
— a spindle standing on the point. A trunk is a path up through it, one notch per step (the fall brings physics with it),
and the shape materializes along it (each thing appears at the step its last capacity arrives). **644,000 trunks** reach
the same end through the terms Ada has (counted by DP over envelopes, in Python and in the page — the same number). The
current trunk materializes things in bursts — 3 at grasp, 157 at the first composition, 272 at many kinds of parts,
1 at measure, 5 at decide; the most even possible trunk still bursts (~226), because the collection is dense in
composition. Its end lies in unmade space: no thing has more than 12 notches, the trunk's envelope has 15, and its only
next step is the field (+167, no term). The page: grow it from the point (play), pick a pace (even, crescendo,
front-loaded, breathing, slow start) or draw one, and the trunk closest to that pace is found by DP; or step it by hand
through the adjacent possible (from the point only form and parts have a term). "make it the trunk" goes through the
same gated `--propose` as /tree-of-life.

**Grow it from the point — `/spine-film` (Palle, 25 Oct: "can we animate the objects of the spine and I can drag a
timeline through the capabilities and associations … and can we see the code develop in a side panel?"):** the timeline
is the trunk, one segment per step. Inside a step the trunk's object is constructed part by part (the Builder's own play
order, ticks on the timeline), then its associations — the terms with the same capacities and another surface or
colour (quad has eight: tape, walk_line, red_line, parallel_lines, cross_lines, danger_x, triangle_face, ply) — bloom in a
ring around it (green dots). Drag anywhere, ← → jump steps, space plays. The side panel is the code: "the program so far"
grows a line per step with the tokens this step added in green, and "how <term> is built" lights the block that made the
part now appearing (every built node carries its block's address, `userData.path`: parts by index, `of` as −1), built
blocks solid, pending ones faint. Below the viewport, the works of the spine that materialize at the step (their last
capacity arrives there; 268 at skateboard_3). Renders with WebGL where there is one, else with three's SVGRenderer
(no labels, textures or shader strokes) — the in-app browser pane has no WebGL, and that is how it was checked. Trap
found on the way: an SVG renderer sized in pixels widens its grid column, the ResizeObserver reads the wider host and
the SVG grows again (6530 px) — the element is now absolute and the column `minmax(0,1fr)`.

**The lineage film (Palle, 25 Oct: "after line triangle must be a new node leading to its different form, then
tetrahedron, pyramid, wedge, then platonic solids … what happens when we add the time domain of transform … then arrays,
color … load the glbs from godot instead of three? … how to reconstruct the whole sequence and how I can sort the
order"):** the film now plays the LINEAGE, not the capacity track — two orders had been conflated: the track is a coarse
gate (one new capacity per step, 16 steps); the lineage is every new form, each built from earlier ones. Every term is a
node (95), except a term written `associate(N)` — the same thing with another surface or story, nothing else around N —
which blooms around N (walk_line and red_line around tape, danger_x around cross_lines, the wood/concrete/cardboard/
Warhol boxes around cube). New terms: `pentagon`, `octahedron`, `icosahedron`, `dodecahedron`, `platonic_solids` (true
solids: new mesh shapes `octa`, `icosa`, `dodecahedron` in builder.gd's mod_mesh.gd and in modular-terms.ts; the old
`dodeca` icosphere stand-in is untouched), and the transformation chapter `moved_cube`, `turned_cube`, `scaled_cube`.
Each node: construction → TIME when it is a transform or an engine (the static transform unfolds: a place becomes a move,
a turn a turning, a size a growing; physics falls or swings on its tie, a sine oscillates, noise wanders) → its
associations. Godot builds all 8 (probe 103 ok, the 7 failures foreign). The order is Palle's: the film's list is
sortable (drag, ↑ ↓; red = before what it is made of) and saves into the one authored order,
`commons/data/construction_path.json` (term places refilled, artifacts untouched, a complete permutation). Palle's
sentence is saved as the authored order: line → triangle → triangle_face → tetrahedron → quad → pyramid → wedge → box →
octahedron → icosahedron → pentagon → dodecahedron → platonic_solids → (the rest in the spine's order); "default order" on
/construction-path undoes it. Godot's own geometry: `commons/testing/export_terms_gltf.gd` exports every term as Godot
builds it to `ada_encyclopedia/public/artifact-gltf/mod_<term>.glb` (102 of 102; meshes renamed `o<NNN>_` in build order,
scaffolds already freed), and the film's "Godot's build" switch plays those instead of the three.js rebuild.

**Filling the gaps after the solids (Palle, 26 Oct: "can you continue to fill in the gaps"):** the lineage now runs on
through transformation, arrays, colour, tiling and change — 17 terms, each a construction from earlier ones and each
answering a principle MODULAR_COVERAGE.md listed as uncovered. Three additive words in both builders (a repeat or an
engine without them is built exactly as before): `palette` + `palette_by` (index | checker | row | column | layer) on
`array` and `times` — a copy's colour follows its ADDRESS, not its place, and `#rrggbbaa` carries alpha; `profile`
(ramp | sin | parabola) — a copy's height follows a function of its index; and the engine kind `tween` — the transform's
time domain as a real behaviour (mod_behaviour.gd plays at / rot / scale over a period, out and back; the film plays it
in its time phase). Terms: transformation `combined_move`, `trs_cube`, `travelling_cube`, `turning_cube`,
`growing_cube`; array `disco_grid` (a grid with a clock: spheres coloured by checker, set going by sine_field); colour
`rainbow_row`, `color_grid`, `color_nails`, `alpha_steps`; tiling `checker_tiling`, `stripe_tiling`,
`reflection_tiling`, `star_tiling`; change `rate_steps`, `accumulation`, `parabola_arch`. New chapters color, tiling,
change (mapped to their spine sequences in tools/construction_path.py). Godot builds all 17 (probe 120 ok, the 7
failures foreign); captures confirm the palette, the checker by address, the sine profile and the alpha steps; a film of
travelling_cube shows it travel out and back. Placed in the authored order: the transformation additions after
scaled_cube, then after lattice the grid with a clock, colour, tiling and change, before the motion terms — 112 nodes, 0
before what they are made of. glbs for all 17 (119 terms exported). The notation prints palettes, profiles and tweens
(`tween(cube, at 1.2,0,0, every 4 s)`).

**Sequences 7–11 and the recursion (Palle, 26 Oct: "yes go on with 7-11 and the recursion"):** 25 terms. Two new
operators in both builders. `recurse` — a thing made of smaller copies of itself: generation n+1 is the rules'
transforms applied to generation n (an iterated function system); `keep: seed` keeps a fresh seed in every generation
(a tree carries its trunk), `stack` shows every generation offset (predict one before seeing the next); depth capped
at 3000 copies; the film plays the seeds in the order the recursion reaches them. `rewrite` — an L-system: the axiom
rewritten by its rules, then read by a turtle in the vertical plane (F/G draw, f moves, + − turn, [ ] keep and return);
the film plays it stroke by stroke. Smaller additive words: `rise` (a profile MOVES the copy — a sampled path),
profiles `gauss` and `beat`, times layouts `circle` (vertical: each height is the sine of its angle) and
`phyllotaxis` (the golden angle), `angles` on the random engine (a choice among a few turns), `frequency` on the
noise engine (an octave). Terms — forces: `arrow`, `vector_sum` (head to tail, the resultant in red, √3 at 30°),
`launch_arc` (equal time steps of a flight), `spring_oscillator`; form finding: `catenary` (drafted as a parabola,
settled by physics), `gradient_descent`; waves: `unit_circle`, `sine_graph`, `circle_to_graph` (the coordinate that
draws the graph), `standing_wave`, `beat_graph`; randomness: `ten_print`, `random_sizes`, `gaussian_bins`; noise:
`noise_heights`, `layered_noise` (two octaves summed); fractals: `sierpinski` (3⁵ = 243), `cantor_set` (every
generation, 63 bars), `fractal_tree` (2⁸−1 = 255), `sierpinski_carpet` (8³ = 512), `phyllotaxis` (160 at 137.5°);
L-systems: `lsystem_plant` (1488 strokes), `dragon_curve` (1024), `sierpinski_arrowhead` (729 — the same triangle
as the recursion, drawn as one line: what exactly is repeated?), `koch_curve` (256 — by rewriting, because a Koch
curve by uniform-scale recursion thins its own stroke to nothing). Godot builds all 25 with exactly those counts
(probe 145 ok, 7 foreign failures). Chapters forces, formfinding, waves, randomness, noise, fractals, lsystems, mapped
to their sequences. Placed in the authored order: 7–11 after the motion terms, fractals and L-systems after the logic
block (cellular automata, 13); 0 before their parts.
Fault found by filming: a spring tie set its equilibrium to the parts' starting offset, but Godot measures the
equilibrium from where the joint starts, so the offset counted twice and spring_oscillator's ball swung through the
floor at any stiffness; the equilibrium is 0 now ("at rest as they stand"), and the film shows a damped oscillation
(stiffness 40, damping 1). No other term used a spring.

**The field operator — the track's last step (Palle, 26 Oct: "continue"):** `{"op": "field", "fn": f, ...}` in both
builders (commons/modular/mod_field.gd; ada_encyclopedia src/lib/modular-field.ts): a surface where a function of space
crosses zero, so isosurfaces (18) and booleans (19) are one operator. `f` is a tree of signed distances (sphere, box,
torus, cylinder, plane), gyroids, metaballs, noise terrain and noise blobs, combined by union, intersect, subtract
(the cutter's OWN distance: max(a, −c), smooth −smin(−a, c, k)) and smooth union; the field is intersected with its
sampling box so a cut surface is capped; `collide` adds a trimesh body you can stand on. Meshing went through three
versions, each one caught by commons/testing/probe_field.gd, which asserts every mesh against the field that made it:
surface nets (one vertex per cell) folded where two sheets met in a cell — the gyroid came out with 24 non-manifold
edges; marching tetrahedra (six per cube about its diagonal, the same cut everywhere, welded per grid edge) closed
every mesh, but orienting a triangle by its own geometry failed where box faces sat ON grid planes and crossings
collapsed onto grid points — 6481 inconsistent edges in bool_subtract; orienting by the MIDPOINTS of the crossed edges
(a proxy that never collapses) made every mesh consistent. Final probe, all ten: closed (0 open, 0 non-manifold
edges), consistently wound, outward by signed volume, vertices within one cell of the surface, and FOLDS (facets
tipped where a wall is a few cells thin) at most 0.62 % (noise_blobs), gated at 1 %, drawn double-sided; the carve test
passes on bool_subtract (the far corner survives, nothing inside the cutter, 2820 vertices on it) and FAILS on the
intersection of the same two, as it must. Terms: isosurfaces `metaballs`, `gyroid`, `torus_field`, `noise_blobs`,
`field_terrain` (+ ground); booleans `bool_union`, `bool_subtract`, `bool_intersect`, `smooth_union`,
`smooth_subtract` (+ ground: a bored passage). `metaballs` fills the main track's last step through the gated
`--propose` (the trunk's lineage file now has its origin and this first mutation): 16 steps, 0 holes, gate OK; the
167 works that waited on the hole now hang off their nearest step (77 off metaballs).

**The open sequences — shaders, procedural generation, soft bodies, swarms, graphs, machine learning (Palle, 26 Oct:
"continue"):** 16 terms and four additive words in both builders. Surfaces `glow` (emission: bright without being lit),
`rim` (a view-dependent edge; three.js draws it as sheen) and `pink_rim`; `inside` on arrays — a copy stands only where
its centre is inside a field (centre-based voxel sampling, the field functions of mod_field.gd); `keep` on the random
engine — each part survives a draw with probability p, else it and the support it gave are gone; the engine `flock`
(Reynolds: separation, alignment, cohesion within a radius, steered back into a box; the film replays the same rules
from the seeded scatter). Terms — shaders: `glow_cube` (an association of cube), `rim_sphere`, `pink_extravaganza`
(repeated pigment, rim and emission composed on fixed bodies); procedural: `bush`, `percolation` (39 of 64 tiles
kept), and after the booleans because they stand on the field operator, `cave_chamber` (rock minus smooth carving
centres, with ground and a way in) and `voxel_sphere` (305 cubes); soft bodies: `soft_cube`; swarms: `boids`; graphs:
`graph`, `graph_circle` (the same ten edges on a circle: a connection is not a coordinate), `spanning_tree` (Kruskal
over the same edges: 6 = n−1, total length 2.96 of 5.12), `grid_graph`; machine learning, computed at authoring time and
recorded: `line_fit` (least squares, slope 0.298, intercept 0.523, MSE 0.0037, residuals drawn), `kmeans` (3 centres,
converged in 2 rounds, 10/10/10), `neural_net` (2-3-1, nine weights). Films: the boids leave their grid and fly in
groups; the soft cube first COLLAPSED (60 N/m cannot carry two layers of balls, and a lattice without diagonals shears
flat) — at 400 N/m with each sub-cube's four body diagonals (86 springs) it lands, yields and keeps its shape, which the
spring-equilibrium fix of the previous round made possible at all. Godot builds all 171 terms (the 7 failures foreign).

**Sequences 23–25 — objects for arguments (Palle, 26 Oct: "continue"):** five terms; one additive word, `arc` on the
times circle layout (a part of a circle, both ends included). The foundations crisis: `spherical_triangle` (three
quarter great circles on a sphere meet at three right angles — 270°, not 180°: what changes with the geometry),
`impossible_triangle` (three straight bars along x, y and z that close into a triangle only from the direction
(1, 1, 1); every standard capture angle shows the staircase — the convincing view is one place), `self_containing_box`
(a box holding a copy of itself, eight times: self-reference regresses; Russell's contradiction needs more, unrestricted
membership — the label says so, because the hall asks exactly that distinction). The QFEP laboratory: `same_total` (four
cubes in a row and four in a square: the same scalar, two arrangements). After the crisis: `rhizome` (24 points grown by
nearest neighbours, each tied to its nearest earlier point and a third of the time to its second: 29 ties, degrees 1 to
6, no centre planned — computed and recorded). Every sequence now has nodes; the lineage has 167, the README says so.
Godot builds all 176 terms (the 7 failures foreign).

**Re-measuring the principles (Palle, 26 Oct: "push it and continue"):** `tools/modular_coverage.py` re-run with every
term so far: 150 → 246 covered of 425. Then a fault in the MEASURE: a principle counted as covered only when it shared
two stems with a term, so a one-word content title ("Metaballs", "Caves") could never count, whatever the grammar held
— the field terms were reported "uncovered" this way. The threshold is now min(2, the principle's own stems), and the
header counts terms and families instead of printing the 51 of 23 Oct. Then six terms for what remained genuinely
uncovered: `circle_limit` (polygons of 3, 4, 6, 8, 12, 24 sides at one circumradius beside the circle: finite
refinement, tolerance, the limit no n reaches), `cube_assembly` (a cube from six faces), `column` and `column_family`
(one profile, three sizes), `terrain_overhang` (terrain ∪ blobs ∩ slab: a heightfield cannot overhang, a field can;
first probe failed it — folds 1.18 %, three bodies — coarser blobs made one body, folds 0.20 %), `rhizome_body` (the
rhizome's own 29 ties and 24 knots as capsules in one smooth union: one body). The field gained `capsule` and a
smooth union over any number of parts. Three terms got the accurate name for what they are — `metaballs` an implicit
surface, `bool_union` implicit modelling, `cave_chamber` cave generation — wording only, nothing claimed they are
not. Result: 264 covered, 13 kernel only, 148 uncovered. Left uncovered on purpose: Animated Noise (re-meshing every
frame is too slow in GDScript), VR Sculpting (interactive), and The 256 Cases — the grammar meshes with marching
tetrahedra precisely to avoid that table. All 13 fields pass probe_field.gd; Godot builds all 182 terms.

**Comparisons (26 Oct, continued):** the uncovered list is mostly verbs (compare, measure, retain), so the next
terms are comparisons, two things under one rule, with every number in the expr computed from the build's own data.
`csg_order` — (A − B) − C beside A − (B − C), one field: the same box, bore and ball; the left bore is countersunk,
the right one sealed at the top, because A − (B − C) gives back A ∩ C. `csg_tree` — (box ∩ sphere) − (three bars).
`traversal_pair` — one 5×5 grid, the queue's tree (depth 8) beside the stack's (depth 24). `route_after_stone` — a
wall with two gaps: 6 steps, take the near stone away, 12. `one_more_route` — the spanning tree plus one edge closes
exactly one cycle (5 nodes, red). `matching_block` — on a path of four the middle pair is maximal and blocks the two
outer pairs. `centrality_pair` — two cliques and a joint: fewest edges (2), most shortest paths (16 of 36 pairs).
`flow_field` — 9×9 directions, three particles sampling where they stand. `two_basins` — two starts 0.16 apart,
two stops (heights 0.077 and 0.221): descent finds a bottom, not the lowest. `euclid_vs_sphere` — the same three
sides, 180° and 270°. `generations` — Sierpinski at depth 0–3, every generation kept. `field_gallery` — six
functions, one mesher. All 16 fields pass probe_field.gd (csg_order: 2 bodies, as built); Godot builds 194 terms.
**What the measure got wrong:** reading why each principle was matched showed the lexical match over-counts — a
principle "covered" when it shares two generic stems with any term (`star_tiling` covered a wave principle through
"repeat" + "replicate"). About 80 of the 282 covered rows rest on exactly two shared stems, many of them coincidences.
Not rebuilt (no new instrument); the stop list gained function words ("you", "take", "give", "read") that had matched
as content, and three exprs were reworded so they no longer catch halls they do not show. Result: 282 covered, 12
kernel only, 131 uncovered — of the 21 rows this round added, 19 are what the terms show, one is partial (the Flow
Field hall's wrap-around trails) and one is false ("Change evaporation…" — "change" is the chapter's own name).

**Behaviour over time, first engine: trail (26 Oct, Palle: "yes").** What stayed uncovered was mostly what a still
cannot show, so the grammar gained an engine rather than more objects: `trail` — stigmergy, agents that write the
field they read. Each agent senses the field ahead (left, centre, right), turns toward the strongest, wanders, moves,
deposits; the field diffuses and evaporates; fixed anchors feed it; `exclusive` allows one agent per cell (Jones's
physarum — without it every agent collapsed onto one band); two channels make an ant colony (searchers lay home and
steer by food, carriers the reverse, the deposit fading with the journey to nothing — at a 5 % floor the first Godot
run formed an ant mill, a closed loop away from nest and food). Tuned first in a Python prototype, then written twice:
`commons/modular/mod_trail.gd` (the field one texture, the agents one multimesh, `warm` steps at build time so a still,
a glb and a probe see a formed trail, then 15 steps a second in the game) and `ada_encyclopedia/src/lib/modular-trail.ts`
(the studio's still; the film replays the rule from the seed as the timeline is dragged). The two random streams
differ, so they are the same rule, not the same run. Five terms: `pheromone_mark` (a mark enters the next decision),
`record_vs_signal` (the same walkers and seed, marks only recorded beside marks read: a wash against paths),
`evaporation_pair` (0.3 % against 8 %: a kept network against the one path walked now), `physarum` (five supplied
anchors, agents' own traces: a network on the anchors that nobody drew), `ant_colony` (a bent route between nest and
food; nothing proves it shortest). `commons/testing/probe_trail.gd` checks that the game keeps stepping after warm:
about 32 steps in two seconds, the field changing, the ants delivering (704 → 782). Coverage 282 → 288; the six rows
gained are the pheromone, physarum and ant-colony halls and their objectives, and "Change evaporation…" — false last
round — is now covered by the term that shows it. Three wordings were changed again so the ant and record terms do
not catch the Lab_Path, Random_Cubes and "formal grammars" rows they do not show.

**Second engine: pso (26 Oct, Palle: "yes").** Particle swarm optimisation, `commons/modular/mod_pso.gd` and
`ada_encyclopedia/src/lib/modular-pso.ts`: particles fly over a landscape of five gaussian hills (the objective drawn
as height); each remembers its personal best (a gold disc where it was found, as high as its score), all share the
global best (a red pin); each update v = w v + c1 r1 (pb − x) + c2 r2 (gb − x). Prototyped first: over 20 seeds the
shared memory found the highest hill 15 times, personal memory alone 6. Two terms: `particle_swarm` (16 particles,
20 steps in: a search under way) and `swarm_memory_pair` (personal only beside personal + global, same seed, 80 steps:
spread over the hills against gathered on one). Godot's run (seed 3) gathers on the second-highest hill, the three.js
run on the highest — "usually but not always the highest", as the expr says. Two faults found by looking: the
landscape rendered unlit, because its top faces were back faces and with culling off Godot flips a back face's normal
away from the light (normals are now the height function's gradient and the top is the front face); and the pair
first photographed as a fresh scatter, because the game had stepped past the 90-step cycle and restarted the search
before the camera fired (the cycle is 240 steps now). probe_trail.gd covers pso too: 20 → 32 steps in two seconds,
the global best never falling. Coverage 288 → 290 (the PSO hall and, partly, "remembered positions from their
scores" — no novelty archive yet); one wording changed so "score" + "step" stop catching a music row.

**A driven constraint (26 Oct, continued).** "What changes when the constraint itself is driven?" (SoftBodies_Carusell)
needed the physics engine to move an anchor while what hangs from it stays free — no engine could. Additive and gated:
a physics engine with `"drive": {"term", "spin" °/s about y through "pivot", "sway" [m, s], "ramp" s}` turns the named
static bodies into AnimatableBody3D (`mod_body.gd make_animatable`) BEFORE the joints are tied, so the joints hold them,
and moves them every physics step; a term without `drive` is untouched (pendulum and spring_oscillator build as before).
Two terms: `carousel` (four balls on ropes from a hub driven at 200°/s: nothing pushes the balls, the ropes' upper ends
are carried round) and `carousel_pair` (the same at rest beside driven: plumb against leaning out). probe_trail.gd
checks it live: six hub bodies driven, the balls' mean radius 0.55 → 0.81 m in 2.5 s. The film turns the hub; the
studio shows the rest pose. Coverage 290 → 292, both carousel rows; "they" joined the stop list after it and
"physics" + "turns" matched a forces row about an along-rail component. Still open: the PSO landscape's height
colours do not reach the albedo in Godot (it reads by shading alone), "the enclosing architecture deforms"
(SoftBodies_Obsticals), reaction-diffusion (GPU), directed graphs and flow, and sequences 23–25.
