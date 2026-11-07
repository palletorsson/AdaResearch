# Artifact timeline

Read-only union of registered artifacts referenced by February/current grid maps,
Endless Museum plans and saved main Void rooms. Exact lookup keys establish identity;
renames/assemblies are not automatically equated. Registry entries never placed in
any of those contexts are excluded. Configured membership is not runtime acceptance.

Build: `python tools/build_artifact_timeline.py`.
Browse: http://localhost:3003/artifact-timeline

Reuses GLB/GLTF files named by the main Void and trial export manifests. The public
model folders are junctions to D: and are read only. No Godot export, world edit,
map recreation or image capture is required for this first version. Missing exports
remain searchable as pending. Existing image review is preserved and linked.

Models are static exported local poses, not current room arrangements or historical
reconstructions. Every exported variant identifies its actual source. Different
settings may share a source artifact; membership does not assert their model is
identical. Shader, particle, procedural and interaction limitations of the existing
exports remain. The viewer uses the prefab workbench's Three.js preview and loads
only the selected artifact. Saved configurations and assessment histories are untouched.


First verified index: 2,974 artifacts, 1,106 with usable models, 2,323 exported
variants, 1,868 pending. Grid membership 2,788; Museum 1,011; Void 1,132.
All exported GLB paths were checked for existence and binary header/declared length.
No map JSON parse failures. API index omits heavy part payloads; detail is fetched
on selection. Unknown keys return 404. Browser checked microscope geometry and
variant switching, missing mod_marble export state and search. Typecheck has baseline
repository errors but no errors in new timeline files after the API type fix.

The historical-image capture task is not resumed by this timeline. Its existing
images, snapshots and review records remain intact. No source-world edits were made.

## The editable timeline (2026-11-07)

Palle: "give every main artifact a place in the annotated path, the artifact timeline and in
space ... remove ... add ... move ... All artifacts in the void tower should be accounted for ...
environment [works] on a separate track, smaller. Number the artifact by the timeline."

- **Authored:** `commons/data/artifact_timeline.json`. `main` is the numbered track
  (number = position + 1, each row with the floor the timeline puts it on and an optional note),
  `environment` the recurring works that make space (not numbered, drawn smaller; props are
  `prop:<kind>`), `removed` the works taken off the path, each with a reason. One row per line.
- **Derived:** `ada_run/artifact_timeline_view.json`, written by `python tools/artifact_timeline.py view`
  (the page's API rebuilds it when the authored file, `rooms.json` or the construction path is newer).
- **Check:** `python tools/artifact_timeline.py check [--markdown]`. Exit code = tower works filed
  nowhere + main works with no place in the tower + removed works still standing + keys filed twice.
- **Edit:** http://localhost:3003/artifact-timeline. Move (↑ ↓, "move to #", drag one number onto
  another), remove with a reason, add from the catalogue after the main work you last selected,
  move between the main and environment tracks, set the floor, annotate. Save checks that nobody saved in
  between (409 otherwise).
- **The tower follows remove and add** (Palle, same day: "if I remove or add it in the timeline it should
  be removed in the void tower"). On Save, `artifact_timeline.py plan` turns the edit into a tower edit:
  a removed work leaves `commons/void/rooms.json` everywhere it stands (artifacts, copies, props), and its
  placements are kept on its removed row, so Restore puts it back at the same place in the same list;
  a main work that stands nowhere is placed on its timeline floor, on the free 1.3 m access square nearest
  the work numbered before it on that floor (else the floor's first route stop). The Void editor's
  validator judges the result (only NEW errors block; new spatial warnings are reported), and rooms.json
  is written by the Void editor's own save (revision check, `ada_run/void-editor-backups/`, Desktop copy,
  live update to running games). Moving a number to another floor does NOT move the work: that stays a flag.
  Tested: remove two works (15 placements) + add one, then the reverse, gives rooms.json byte-identical.

Seeded from the tower as it stood on 7 Nov: 1,145 tower works = 1,080 main + 65 environment
(20 prop kinds, 24 works on 5+ floors, furniture by last word, registry architecture/signage).
The seed's split is a first guess: move what is wrong. Gaps at seed: 739 main works stand on floors with
no walking route (only 37 of 211 floors have one), 119 stand more than 5 m from their floor's route,
107 are not on the construction path.

## The number becomes the walk; the number is in the game (2026-11-07)

Palle: "yes 1 and 3" - derive each floor's walk from the timeline, and show the number in the tower.

- **Derived, tracked, read by the game:** `commons/data/artifact_timeline_walk.json`, rewritten (only on
  change) by every `artifact_timeline.py view|check|save`, by a timeline Save, and in the background after
  every Void editor save. Per floor: each main work numbered on that floor and standing there, in number
  order, with a STAND point 1.2-3.5 m from it, free, at least 1.6 m from the other stands, nearest the
  previous stand.
- **The walk:** on a floor with no hand-made `route` in rooms.json (169 of the 206 floors with main works),
  an A* path on a 0.5 m grid joins the stands in number order around shafts, columns, low walls, props
  and the works. It tries a STRICT reading first (clear of every measured catalogue footprint) and a
  LOOSE one second (access squares only, for rooms you walk into). A floor with a hand-made route keeps
  it and gets the numbers only.
- **The seed numbers a route-less floor as a walk:** nearest-neighbour from the arrival shaft
  (`layout.json` descent.pad_shafts), then 2-opt. The first seed numbered those floors alphabetically and
  the walk on floor 75 crossed itself 20 times; the tour has 0 crossings there, 13 over the tower.
- **In the game:** `commons/void/timeline_walk.gd`, called from `floor_content.gd` for the main tower
  only. A pink disc at the stand (where the walk arrives), then `#0123` and the title lying on the slab
  ahead of it, top toward the work, and the walk as a 5 cm line with round joints. No collision. Lifted
  3.4 cm: the Tiling floors lay a pattern skin at +2.6 cm (`pattern_architecture_receiver.gd`) that hid
  the first version completely while every node check passed.
- **Probe:** `python tools/test_timeline_walk.py [--floors=1,5,39,75] [--no-shots] [--settle=90]` builds
  the real tower and checks per floor: captions = works, the caption reads toward its work, the work
  stands where the walk says, no caption lies under a walking surface (a ray down), the captions are
  visible, the walk is drawn (or not, on a hand-made-route floor). Photographs from above (orthographic,
  under the slab overhead) and from the first stand: `ada_run/timeline-walk/`.

### Measured, not guessed (same day)

The first full-tower probe (147 floors before a floor hung the game) found 75 captions on 45 floors lying UNDER
something: transition-grid floors at 0.97 m, tables, wedges, 2 and 5 cm plates. The footprint model could not
know them. So the floor is now measured in the built game:

- `python tools/measure_void_occupancy.py` (Godot probe `tools/probes/void_floor_occupancy.gd`): per floor a ray
  down at the centre of every 0.5 m cell (84 x 36), the first surface in cm (0 = slab), 254 = too high to stand,
  255 = nothing. Written to `commons/data/void_floor_occupancy.json` (derived, tracked, 144 KB) with the sha1 of
  each floor's rooms.json record. Without arguments it measures only missing or stale floors; a floor that
  hangs the game is recorded as unmeasured and the run goes on; a crash after some floors resumes.
- The walk uses the measurement where it is fresh: a cell is standable up to 6 cm (the Vectors floors' 5 cm
  plates are floor; a 7.5 cm bar already stops the walker), higher cells and their four neighbours are
  blocked. Captions and the line lie ON the measured surface (`y`). A stale floor falls back to footprints
  and is listed in `stale_occupancy` - re-measure after moving works.
- A work beyond the slab (annexes at |z| > 9 or |x| > 21) or inside a closed room gets the nearest free slab
  cell as its stand (`far`: the distance), so its number still lies where it can be seen.
- Result over the whole tower: 1,079 stops, every one on a free measured cell; 23 stops on 11 floors the walk
  cannot reach (closed rooms, annexes) - flagged on the page as "the walk cannot reach it".

## Base, child, collection (2026-11-07)

Palle: "we need to differentiate between artifacts and collections ... part of the main track if they exemplify an
algorithm, like arrays of things or random collations ... sometimes the collections are just an example and part of
the environment ... we should also be able to understand what artifacts are associative children of a base artifact"
- and: "children share base number".

Every main and environment row may carry a `form`:

| kind | means | on the timeline |
|---|---|---|
| `base` | one work (with its grammar `term` when commons/modular/terms.json describes it) | a numbered square |
| `child` | `association(config(base))`: a thing recognised in a base form - `of` names the base's key | a small letter under its base, sharing its number: `#0095.a` |
| `collection` | many things: `op` array, times, assemblage, collation or set; `algorithmic` true = the collection IS the algorithm | main track: a double-framed number; `algorithmic: false`: the environment collections lane |

`python tools/artifact_timeline.py forms` guesses the missing forms (`--refresh` re-guesses the ones still marked
`guessed`): a work the grammar describes takes its term's operator (`association(...)` -> child, `times`/`array`/
`assemblage` -> collection); a child's base is guessed as the first numbered work on its floor whose key names the base
form (`void_primitive_cube` for the cube's dice, cardboard box, ...); otherwise a collection is guessed from words in the
key (gallery, collection, array, row, stack, shelf, forest, garden, pile, cluster). Every guess is marked `guessed` and
flagged on the page until a form is set there (Confirm).

First pass: 74 forms guessed - 10 children under their bases (#0006 .a .b, #0026.a, #0067.a, #0095 .a-.f), 37 collections
on the main track, 14 children whose base form has no work on their floor yet (they keep their own numbers, flagged).
The walk file carries each stop's `label`; commons/void/timeline_walk.gd writes it on the slab (`#0095.a`).

Why it matters (the grammar's compression): a child is its base plus a configuration, a collection is an operator over
a base - the same expression the builder executes. A repeated collection is also what a MultiMesh draws as one mesh and
a list of transforms: the next step (collections as MultiMesh) reads `op` from here.

## In the time: comments and instructions (2026-11-07)

Palle: "we need to comment and add artifacts in the time by instruction prompt, so we can prompt in the context of the
time". Under a selected work, "In the time" keeps a thread (commons/data/artifact_timeline_threads.json, one entry per
line): a **comment** is stored; an **instruction** is stored and put to a model with its context - the work, eight
neighbours each side with their labels, forms, notes and flags, the works of its floor, its children, its grammar term
(`python tools/artifact_timeline.py prompt <id>` prints exactly what the model reads).

- The model runs READ-ONLY (Claude Code `-p --tools Read Grep Glob`, cwd the repo): it can look things up, not write.
- It answers `{"reply", "operations"}` - add, move, remove, form, note, to_environment, to_main. The tool checks each
  operation (keys must exist where the operation needs them) and refuses the rest, shown struck through.
- Nothing is saved by the answer: "Apply to the timeline" applies the valid operations to the page's unsaved timeline;
  the person looks at the strip and saves (and on save the tower follows, as before). "Reject" keeps the record.
- No model reachable (on 2026-11-07 the Claude Code login had expired; no ANTHROPIC_API_KEY in .env.local): the
  instruction is QUEUED. An agent session answers it: `python tools/artifact_timeline.py instructions`, then
  `prompt <id>` and `answer <id>` with the JSON on stdin; the page shows the proposal.
