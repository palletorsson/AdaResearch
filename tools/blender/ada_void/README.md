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

### The tower from outside

`tower.py` imports several floors with the same `build_floor`, hangs each under an empty at its storey from
`commons/void/layout.json` (`levels[i]`: 0, −6, −12 … in Godot y, Blender z), lights them with the export's sky and
sun, and photographs the stack from a raised three-quarter view outside, framing all of it:

```
blender -b -P tools/blender/ada_void/tower.py -- --floors 0-4 --out ada_run/blender/void_tower_0-4.png \
    --blend ada_run/blender/void_tower_0-4.blend --samples 256 --margin 0.9 --elevation 18
```

`--floors` takes ranges and lists (`0-4`, `3,7,10-12`); `--azimuth`, `--elevation`, `--lens`, `--margin` and
`--exposure` move the camera and the light; a JSON beside the PNG records each floor's level, counts and timings.
Floors 0–4 import in about 2.5 minutes; the render takes about 30 s on OptiX at 256 samples.

Two more modes work on a saved scene, so the camera can be tuned without importing again: `--reframe` (open the
`.blend`, move only the camera, render) and `--append` (import more `--floors` into the open `.blend`, keep the rest).
`--frame-floors` frames only some floors and lets the others run out of the picture — the tower without an end:

```
blender -b ada_run/blender/void_tower_0-9.blend -P tools/blender/ada_void/tower.py -- --append --floors 10-12 \
    --frame-floors 0-9 --out ada_run/blender/void_tower_0-12.png --res 1440x2560 --samples 256 \
    --azimuth -62 --elevation 12 --lens 50 --margin 1.04
```

### The tower from below, and far floors as structure only

`--from-below` puts the camera under the lowest framed slab and out beside the axis, looking up the tower
(`--drop` metres below, `--offset` metres out, aimed `--aim-up` metres above). A whole tower does not fit in memory with
its works (the works of 211 floors are about 8 GB, and one 10 PRINT floor alone holds a model of over 1,100 tiles), so
`--structure-floors` imports only the slab, halls, ceiling and lamps of the floors it names; from a distance the works
are specks anyway. The randomness floors looking up, with the 10 PRINT floor as structure:

```
blender -b -P tools/blender/ada_void/tower.py -- --floors 76-79,81-91 --structure-floors 0-75,80 \
    --frame-floors 76-91 --from-below --drop -18 --offset 55 --aim-up 90 --lens 20 --azimuth -62 \
    --out ada_run/blender/void_tower_random.png --res 1440x2560 --samples 256
```

### The carton heap

`carton_pile.py` is not a floor: it redraws the sorting line's AGAIN / YET cartons pixel for pixel from
`commons/artifacts/cube_sorting_line/carton_skins.gd`, drops them under gravity with Blender's rigid bodies (a narrow
falling column, `--column 3`, piles higher than a wide one) and photographs the heap lacquered on a dark mirror floor.
A generated image's pixels written with `foreach_set` render black until `img.update()` is called; the script packs
them too, so the saved `.blend` keeps its prints.

`--line` puts the heap where the game makes it: floor 7's exported `cube_sorting_line` glb (its 5.2 m belt along y at
0.95 m, the feeder at +y) with a jam of cartons on the belt and the missed ones spilled off its end, and the large
`prefab_box_library` shelf (from the ReturnToTheBoxLibrary hall's glb) across the aisle. The imported meshes are
unparented into world space first: a rigid body ignores its parent's transform. Every imported material gets the
cartons' lacquer coat.

The still from the visitors' aisle (the shelf across the aisle, the control stand kept):

```
blender -b -P tools/blender/ada_void/carton_pile.py -- --line --shelf-x -6.2 --keep-controls --count 45 \
    --cam=-2.4,-8.6,2.3 --look=-2.0,-0.2,1.1 --lens 28 --out ada_run/blender/carton_line.png --samples 256 --res 1920x1080
```

`--fill N` makes a film of the line RUNNING, seen from the works side with the shelf behind the baskets and the control
stand left out (the `--line` defaults since 3 Nov). N frames are simulated in one pass and filmed on the way, with a
step that grows from `--step-start` to `--step-end`; Blender's own ffmpeg encodes the mp4. `--wall` adds an L of 1 m
walls around the belt's end, so the spill rises in the corner instead of spreading:

```
blender -b -P tools/blender/ada_void/carton_pile.py -- --line --wall --fill 4800 \
    --out ada_run/blender/carton_fill.mp4 --res 1280x720 --samples 48
```

What it took to make the film honest (each was a way it lied):

- The belt is a loop of 41 unrendered slats that carry the cartons by FRICTION. Cartons carried as kinematic bodies
  have infinite force: once the pile reached the belt every arrival ploughed into it and flung cartons over the wall.
- A mesh collider's default 4 cm margin lies OUTSIDE the mesh, so the belt's top stood above the slats and held the
  cartons still: the line's meshes carry a 2 mm margin.
- A kinematic body keeps the speed of its last move: a carton is held still above the belt for two frames after the
  jump from its parking place, or it leaves at kilometres a second.
- Setting a parked kinematic carton's location from Python mid-simulation does not move its body (only the first
  carton ever arrived); the feeder adds keyframes to curves the carton has had from the start.
- The feeder holds while the spot under it is taken, as the game's line holds production (`active_limit`); placing a
  carton into a queue that has backed up to the feeder blasted the queue into the air (one carton ended 314 m up).
- Building the lights and camera after a simulation resets the rigid-body cache, and a jump of more than one frame
  without a cache does not simulate: the film is shot during its one pass, frame by frame.

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
