# Work log — 19 November 2026

## Summary

Today's work in this chat made descent a playable part of the tower's subjects,
restored dependable local preview storage, and delivered the updated game to the
standalone Quest. This is a scoped checkpoint of that work, not a snapshot of every
unfinished edit in the shared checkout.

- Forces gained ten broad stepped descents with a separate stair lane.
- Wave Functions gained eleven connections using curved, eased, rippled and
  enclosed slides, alternating with three large fan staircases.
- Boolean gained two alternating floor openings with receiving pads below.
- The shared installation grammar keeps each connection editable in the room.
  Stable map names identify endpoints; floor numbers must be rechecked when the
  spine changes. The current 23 connections are recorded in `evidence/routes.json`.
- Preview recovery and publication tools use the C: generated-model store,
  validate geometry, preserve previous artifacts and publish manifests atomically.
  The separately requested Documents/godot move has its own guarded migration tool;
  generated web previews remain on C:.
- Detached prefab mesh merging now composes local ancestor transforms instead of
  querying unavailable global transforms.
- Quest version 20, `2026.11.19-sequence-descents`, was installed and opened at
  Color_Context_Placed, floor 28. The installed APK hash was verified. Eight
  progress/construction files were backed up and remained byte-identical through
  installation. A one-time debug request uses the ordinary staged menu launch.

## Files involved

- `commons/void/sequence_descent.gd` and `.tscn`: seven route geometries.
- `commons/void/columns_pipe_slide.gd` and `pipe_slide_provider.gd`: shared slide
  movement used by the wave routes.
- `commons/artifacts/mesh_merge.gd`: detached-template transform correction.
- `commons/scenes/main_menu/MainMenu3D.gd`: consume a one-time map launch request.
- `tools/install_sequence_descents.py`, `test_sequence_descents.py`,
  `publish_sequence_descents.py` and their probes: author, test and preview routes.
- `tools/generated_storage.py`, `void_model_publication.py`,
  `recover_void_previews.py`, `export_void_floors.py` and its probe: local previews.
- Quest export, deployment, retention-repair and verification tools preserve
  receipts and distinguish a successful export from a successful device launch.

## Verification

The existing native evidence records 120 passing checks across 11 desktop and
synthetic-XR cases, including collision, landing, route residency and movement
release. The detached-template regression compared 36 vertices. All 23 published
route previews returned HTTP 200; publication retained 2,294 prior artifact IDs.
Four model-publication failure-injection tests were rerun before this checkpoint
and passed.

The actual APK's packaged launch probe passed for Color floor 28 and all seven
route types, with 23 connections and 35,194 prior resources retained. Fresh Quest
telemetry at y = -180 and the device scene-load log confirmed Color arrival at
16:33 Budapest time. Compact receipts are committed under `evidence/`; detailed
logs, screenshots, saves and APKs remain local in `ada_run/sequence-descents/`.

## Recent related commits

- `16ecf1e01`: the validated rooms-file writer; already contains the 23 route
  placements and catalog registration. This checkpoint supplies their runtime
  implementation without restaging subsequent room edits.
- `e5798f5fe`: Color floor upgrades from the parallel work. They are related to
  today's destination, but are not claimed as work authored in this chat.

## Open items and next research loop

The frozen export omitted 337 cached museum scenes even though their source bytes
matched the previously installed APK. A checked repair restored precisely those
files, then verified alignment and signing identity. The omission's cause remains
unresolved; do not interpret this repair as a general exporter fix.

The exporter had a Windows teardown crash after completing the package. The first
device launch also failed creating its Vulkan window; a second immersive launch
succeeded. Both are recorded separately from the successful integrity and arrival
checks. Neither should disappear from the next deployment review.

Next, try one representative Forces descent, one wave slide, the fan stairs and
one Boolean drop in the headset. Record contact, scale, legibility, comfort and
frame time. Change one condition and repeat before propagating that revision to
the whole family. Arrival telemetry and synthetic XR tests do not establish
embodied comfort or Quest performance.
