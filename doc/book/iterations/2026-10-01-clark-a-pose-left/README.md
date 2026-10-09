# A pose left — after Lygia Clark

A working desktop study made from the project's existing `bicho_hinge` artifact. Six joined plates retain a pose, or return to a chosen reference after release. An optional corner trace makes two different journeys to the same final configuration visible.

[Review, native captures and texts](http://localhost:3003/book-review/doc/book/iterations/2026-10-01-clark-a-pose-left/index.html).

Open `project.godot` in Godot 4.6 and run. The project intentionally contains no XR addon and needs no main-project autoloads. Day Zero setup is assumed; this is a desktop research kit, not a Quest export.

Controls: drag a plate or use the joint selector and slider; Leave it / Return it selects the policy; releasing the slider or plate applies it; Release also applies the policy. Start again restores the starting angles and clears the trace. Right-drag orbits, scroll zooms, V changes view, H hides the panel.

- `ENCOUNTER.md`: the short reading.
- `MAKING.md`: the small making task.
- `score.gd`: the actual editable release policy.
- `gallery.gd`: supplied room, viewer, input and trace apparatus.
- `RESEARCH.md`: sources, decisions, findings and limits.
- `LINEAGE.md`: proposed relationship to the spine.
- `capture.gd`: native evidence probe; `captures/results.json` records the results.
- `sync.py`: refresh exact specimen/dependency copies; `source-hashes.json` records their origins.

To reproduce: run `python doc/book/studies/hinge-and-return/sync.py`, then Godot with `--path doc/book/studies/hinge-and-return --script res://capture.gd`. The graphical renderer is required for captures. The probe stops itself. No permanent service is installed.

The study copies the canonical geometry, rotation and pointer implementation. It supplies a neutral metallic material and rose selection colour to make the planes legible. Its trace keeps up to 1200 positions, sampled after 3 mm of corner travel. The supporting root is fixed. Gravity, contact and friction are not solved. State is not saved between runs.

The release comparison is an original study after Clark, not a reconstruction of a specific *Bicho*. Sources are listed in RESEARCH.md. No main hall installation or headset test is claimed.


## Museum placement, 2 October 2026

The study now has an installed museum adapter and an application passage in the book. See the [current spine integration](../2026-10-02-studies-in-the-spine/index.html). This page preserves the earlier companion evidence.
