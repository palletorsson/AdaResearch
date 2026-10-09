# One possible composition: noise enters a tree's turn

This example was authored by the writing agent to check feasibility. It is not an independent ghost-student submission or a required silhouette.

Use the prepared Endless Museum workspace with its camera, lights, player and installed XRTools. Copy this folder into that project. Attach tree.gd to an empty, unit-scale Node3D on the floor for the unchanged Recursive Trees study. Attach noise_tree.gd to a second empty Node3D and leave clear space between the studies. PointBody and LineSkin stay alongside the scripts; there are no named scene-child dependencies.

The added code creates FastNoiseLite, declares its seed, Simplex type, disabled fractal layering and frequency before construction. A sample at (remaining depth, left/right sign) supplies a bounded offset to each child’s local Z rotation. Branches at the same depth and side share a sample. The offset defaults to 12 degrees and is capped at 15. This is static construction: re-run to rebuild. The inherited hand grips subsequently replace the first forks’ orientation; they do not resample the noise.

At three generations both studies have fifteen segments and the same lengths and attachments. Endpoints differ. Set influence to 0.0 in noise_tree.gd to recover the original. Identical settings reproduce the initial geometry before grip edits. recipe.json names the choices and prediction. Source changes are intentionally local to this optional study; no museum generator was replaced.

Twenty-one native Godot assertions checked those properties, bounded depth, independent originals, station placement and the carried XRTools pickup with supplied controller poses. This establishes one feasible response. It does not establish student understanding, aesthetic quality or headset comfort.
