# Transformation: text and encounter alignment

17 September 2026. Complete working drafts; learner and headset review remain open.

The source maps, current `final.md` files, primary encounter captions, sequence beats and museum plan rows now describe the same encounters. All seven `/api/compose-docs` responses were compared by text hash with the files served by the reading interface.

| Hall | Correction |
|---|---|
| Pre | Still pickup moved from (4,2) to (4,3). A visitor can observe it and move the first metre without collecting it. The book recalls four stations, with three moving demonstrations remaining after collection. |
| Introduction | Explicit standalone start at (5,2). Palle confirmed keeping the crossings without the head crab; the creature and its warning are absent. |
| Translation | All thirteen pickups now occupy the seven course routes, with measured heights and real XR body collection. The course list matches the objects. The secondary torus is acknowledged as a preview of combining translation and rotation. |
| Rotation | Approximately 1,100 words; four principal encounters retained. The exit concerns body size and fit. The two previously untracked helper scripts and their parents were committed with the chapter and required parser settings. |
| Scale | Fourfold change described as a discrete cut followed by relocation. Fixed entrance wall prevents the exterior bypass. The museum preserves the room's authored anchor and excludes intrusive furniture. The enlarged doorway is on the verified forward route. |
| Body | A 1.335 m lattice makes an open-topped cut. Captions invite stepping clear before observing return; crossing a plane does not instantly leave detection range. |
| Pit | Display title is The Moving Boundary; source ID retained. Level ground and optional bypass remain. Three separated 2 m pusher lanes clear walls and keep their collision bottoms on the floor. Growers share a tempo. The text asks which body can use the openings. |

## Spawn and bake ruling

`sp` is a score-points utility in the actual registry. Explicit `s` utilities and `utility_definitions.s.properties.player_rotation = 180` now resolve the entrance and forward facing for all seven standalone maps. The token suffix alone did not set this metadata, so the real resolver was tested.

The Endless Museum suppresses grid spawning and supplies its own vestibule arrival. Its entry floors were checked separately in Pre, Introduction and Translation. The missing standalone spawn was not evidence that the museum was starting on the pit lip.

Source footprints remain unchanged by generic width normalization. `_ruling` describes normalization operations; stale rotation/padding records have no place on these direct source-derived rows. Six halls embed a GridSystem and build their artifacts from source, so an empty list of stamped bake placements is not an empty hall. Scale uses a gallery placement instead: its targeted bake now records `scale_me`, no refusals, and an empty coarse seal. This leaves real wall and doorway collision intact. A coarse reachability graph cannot prove the room's interior passage; the physical tests do.

## Evidence

`verification-summary.json` consolidates the successful source-spawn, actual museum pickup, doorway, descent, proximity and timed obstacle tests. `text-map-alignment.json` records current source and text hashes. Scale's five rendered museum views and its 40 checks are under `scale/`; Body/Pit checks are under `body-pit/`.

The tests use Godot and actual collision bodies, including the XRTools player body for pickup rides. They do not establish tracked-headset comfort, every possible body configuration, or learner understanding. An ambient crab bite appeared in Scale's test; that separate museum system was not removed. No text promises safety from it.

Rotation commit: `b63990f884e0c0162961c3611395275f8b7e00ad`. Other edits in this pass remain working-tree changes. An isolated index preserved unrelated staged work; only Rotation's required numeric parameters were included from the shared parser.

Read and comment from `/compose/sources?map=Trans_Pre`. Re-enter or reload a running museum hall to rebuild its labels and placements from the updated source.
