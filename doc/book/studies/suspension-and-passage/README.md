# Seven places for a passage

An original Godot 4.6 desktop study after Mona Hatoum's *Remains to be Seen*. Open `project.godot` in the supplied Godot setup. Its main scene is `gallery.tscn`.

Compare **One passage** and **Separate pockets**, walk with WASD and mouse, leave walking with Esc. Right-drag orbits the overview; the wheel moves closer. V changes view, H hides controls. Click two grid cells at different heights to exchange them. **Body** compares two declared capsule widths. Reset restores the passage arrangement; the chosen body width remains visible on its button.

The learner's source is `commons/artifacts/suspension_passage/score.gd`. The room, physics controller and mesh construction are supplied. Reading and making are separate in `ENCOUNTER.md` and `MAKING.md`; `LINEAGE.md` and `RESEARCH.md` record the proposal and its limits.

In the repository, `sync.py` copies seven canonical source files byte-for-byte into this kit. `source-hashes.json` records that relationship. In the downloaded kit these copies are directly editable; running `sync.py` is only for repository maintenance, not for the student's exercise.

Replay native evidence with Godot's `--path` pointing here and `--script res://capture.gd`. This creates six captures and `captures/results.json`. `publish.py` is repository-only review-page packaging. No main museum installation is implied.
