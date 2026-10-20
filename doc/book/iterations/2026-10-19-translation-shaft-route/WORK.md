# Translation / seven rides across the shafts

User: use full shaft space for impact; look at old museum; reuse cubes/wp; editable lab editor; desktop/VR tests and actual screenshots; wait with tutorial/final texts.

Complete on separate Transformation trial floor 3. Floor 4 is a catch floor. Pre and Introduction arrangements are preserved byte-equivalent as JSON objects; curated Primitives tower and all chapter tutorial.md/final.md files match before.json hashes.

Route: A south-west landing -> original wp -> Z -7 -> X +11 -> Y +2.5 -> Z +5 at height -> X -10 -> Y -3.5/Z -3 -> X +14/Z +4 -> original constrained/free door studies -> B north-east descent. Starts at deck 1m, rises to 3.5m, finishes at floor 0m. A and B shafts retain their full five-by-six-metre openings. Five recessed rectangles remove surrounding slab without covering original shaft bottoms. Five editable lethal surfaces protect the route; B north-east is reserved for descent. Six editable partitions bound the course.

Uses original transport_cube scene/script via the existing Void ride_platform skin, unchanged original unit cube/wp scenes, 13 original slide/collect pickups, three axis cubes, both original translation_cube_demo variants with motion traces, film_door_routes, toruscylinder. Distance/orientation adapted from the old 15x55m hall to the 42x18m tower; its seven operation types and sequence retained. Upper route height chosen for real player headroom under the six-metre storey. The final diagonal passes beneath the upper crossing with clearance.

Native source: commons/void/trials/transformation/translation_sequence.{gd,json,tscn}, translation_carrier.gd. The JSON recipe is the building geometry/route definition; user curation is rooms.json via the normal revision-checked editor API. Carriers have fixed editable anchors, local displacement, original tc collision/carry. apply_grid_config rebases both route endpoints after moves/turns/copies. Pickups explicitly bind the trial score provider so they never alter museum progression.

Streaming fix: floor_stream.floor_at retains the current hall between its bottom and the previous slab. Without this hysteresis, the Introduction basin's deep range put Translation to sleep during the lift. Standard descent and the previous Introduction regression pass. No museum source behaviour was replaced.

Verification: 214 assertions passed (production desktop + production XRTools rig with synthetic trackers; no physical headset). Continuous traversal of all seven rides, body/camera displacement and facing, all 13 pickups, safe landing/descent, lethal basin/shaft, retry, preserved collected state after returning, bypass wall, original door projection with supplied handle displacements, copied/moved/turned SideRide carrying the same players. Door checks supply positions to the original constraint method; they do not certify a real controller drag. 131 Introduction regression checks also pass; its test now waits for a real checkpoint after warping back from the new Translation floor. 13 production editor checks validate 67 native parts, copying/moving/turning seven representative kinds, preserved prior floors, unchanged chapter hashes, and equality between API/project/Desktop backup. Seven screenshots from the Godot Mobile renderer; carriers paused at 45% of real routes for legibility. No script errors; known RefCounted/ObjectDB shutdown warning remains.

Editor: http://localhost:3003/lab-editor?mode=void&trial=transformation&floor=3
Report: http://localhost:3003/book-review/doc/book/iterations/2026-10-19-translation-shaft-route/index.html
Run: main menu -> Void trials -> transformation; descend through Pre and Introduction. Direct native scene: commons/void/trials/transformation/trial.tscn with --void-start-floor=3.
Test: python -X utf8 tools/test_translation_sequence.py
Editor: node tools/test_translation_sequence_editor.cjs
Capture: python -X utf8 tools/capture_translation_sequence.py
Export: python -X utf8 tools/export_void_trial.py transformation

Do not rerun an old proposal generator or overwrite room curation. Moving banks/carriers independently is deliberately allowed and may make a route unwalkable; rerun native tests against any intentional new route, updating traversal waypoints only to match the design. Web previews are static native snapshots; runtime behaviour is in Godot. Structural holes/pillars stay fixed; props/partitions/artifact parts remain editable.
