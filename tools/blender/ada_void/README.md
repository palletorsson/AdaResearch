# Ada Void — Blender as a third live editor for The Void

Blender 4.2, `bpy` only. Import a floor of The Void, move things, publish: the
running desktop game and the Quest take the change over the live update chain
built on 2026-10-22 (`doc/LIVE_UPDATE_BRIDGE.md`), exactly as a save in
`/lab-editor?mode=void` does. Then render the floor with Cycles.

## Install

```
python tools/blender/build_zip.py --install     # zip + install + enable in Blender 4.2
```

or Blender › Edit › Preferences › Add-ons › ⌄ › *Install from Disk…* with
`ada_run/ada_void_blender_addon.zip`. The panel is in the 3D viewport sidebar
(`N`) under **Ada Void**. Preferences: the encyclopedia URL (default
`http://localhost:3003`) and, optionally, the path of `ada_encyclopedia/public`
(found automatically when the add-on runs from the Ada repo; otherwise the
models are fetched over HTTP from the dev server).

Running: the encyclopedia dev server (`npm run dev`, :3003) for import and
publish; `python tools/vr_link.py` and a game with `--vr-link` for the live half.

## What a floor becomes

| record | Blender |
|---|---|
| floor architecture | `floor-<n>` Empty with the structure glb under it (collection *Architecture*) |
| artifact `{id, position [x,z], height, facing, scale}` | Empty **named by the record id**, location `(x, -z, height)`, rotation Z = facing, uniform scale; its exported glb hangs under it (*Artifacts*) |
| composite artifact (parts, e.g. `hall`) | child Empties `<id>/<part>` at `config.parts[name]` or the exported default pose, each with its part glb |
| copy (`floor.copies`, `only_parts`) | like an artifact, only the listed parts |
| prop `{id, kind, position, facing, scale}` | Empty named by id, the prop's catalog glb (*Props*) |
| lamps (exported per artifact / per prop kind) | Blender spot / point lights parented to the mount (*Lights*) |
| `Label3D` text (from the manifest) | Blender text objects in the label's pose |
| route waypoints | small Empties `route/<i> <label>` (*Route*) |

Godot is Y-up, Blender Z-up; the glTF importer's change of basis is
`(x, y, z) → (x, -z, y)`, so a mount's Blender rotation about +Z is the record's
`facing` with the same sign (`frames.py`; verified against the raw glb and the
film artifact on floor 10 by `headless.py`). Walls and painted construction are
not imported and stay untouched in the record.

The scene keeps the floor index, trial, map, the layout **revision** (sha256 of
`rooms.json`, the same value the web editor checks) and the whole rooms document
(scene property `ada_void_rooms.json`).

## Publish

**Publish** reads every mount back into its record — artifacts: `position`,
`height`, `facing` (+ `scale` when changed); props: `position`, `facing`,
`scale`; parts: `config.parts[name].position/rotation`; route: `position`,
`height` — writing only what changed (an untouched record stays byte-for-byte),
then `POST /api/void-layout {rooms, revision}`. The route validates, saves, diffs
the floor and hands the revision to the bridge; the acks the games send
(`Windows/<host> applied in_place`, `Android/Quest 3 …`) are read from the
ledger and shown in the operator report and the panel's status line. A `409`
(the file changed elsewhere) re-reads the server's document, puts this floor's
read-back on top and retries once. **Reload revision** takes the server's
current document without rebuilding the scene.

What the game does with it is the bridge's boundary, unchanged: a transform of an
artifact or prop is applied **in place**; a part pose, an artifact's scale, a route
change rebuilds **that one floor**; a floor you are not standing on has its record
replaced and builds from it when entered.

**Live** (the toggle) publishes automatically about 0.5 s after the last move: a
`depsgraph_update_post` handler notes transform changes on mounts, a timer
debounces, the HTTP runs in a thread, nothing is sent while a request is in
flight, and a `409` refreshes the revision as above.

## Render

**Cycles setup**: Cycles on the GPU when one is configured (OptiX → CUDA → CPU),
adaptive sampling + denoise, 1920×1080, AgX; the world is the Void's baked
evening sky (`public/void-models/evening-sky.exr`, from the export's `lighting`)
with the sun from `sun_matrix`; a camera at the route waypoint **Arrival** (eye
height 1.6 m, 28 mm) looking along the route to the next waypoint. Optional thin
fog volume in the export's fog colour. Then F12, or `render_setup.render_still`.

### What does not survive the glTF export

The export is a photograph of one moment of built Godot scenes
(`tools/probes/export_void_editor.gd`): geometry and PBR materials travel.
These do not, and are therefore not in a Blender render either:

- **procedural shaders** — a `ShaderMaterial` is exported as a static colour
  preview (`shader_material_previews` in the manifest counts them, 380 on the
  2026-10-22 export); the gloss, scrolling, noise and reaction-diffusion surfaces
  are flat tints in Blender;
- **`Label3D` text** — re-created here from the manifest's label data as Blender
  text objects, so the words are there but in a Blender font and without Godot's
  outline / billboard behaviour;
- **particles, animation, physics, behaviours** — a soft body is baked at the
  moment of export; nothing moves;
- **Godot's fog, tone mapping and light units** — light energies are converted
  with a rough factor (spot ×150 W, point ×100 W, sun ×5 W/m²); match by eye;
- **viewport textures** (screens, cameras) — the exporter skips `SubViewport`.

## Headless / tests

```
blender -b -P tools/blender/ada_void/headless.py -- --floor 10 --move museum-primitives_profiles-15-1 1.5 0 --report ada_run/r.json
python tools/live_update_blender_test.py            # the end-to-end test with the desktop game
python tools/live_update_blender_test.py --render ada_encyclopedia/public/book-images/live-update/floor-10-blender.png --samples 256
```

## Files

| file | holds |
|---|---|
| `frames.py` | Godot ↔ Blender transforms, settle-without-noise (pure Python) |
| `chain.py` | GET/POST `/api/void-layout`, acks from `/api/live-update` (pure Python) |
| `floor_import.py` | the import: collections, mounts, glb cache, lamps, labels |
| `publish.py` | read-back, publish with 409 retry, the live handler + timer |
| `render_setup.py` | Cycles, world, sun, Arrival camera |
| `headless.py` | the add-on driven from `blender -b` (what the test runs) |
| `__init__.py` | preferences, scene properties, operators, the panel |
