# Museum form sources

These four runtime scripts are byte-identical copies of the lesson files recorded
in `provenance.json`. The book's `doc/` tree is intentionally ignored by Godot and
excluded from the Quest export. A playable scene must not preload scripts there.

The runner and Shadow Game load these files, including FaceBody's relative
LineSkin dependency. Shadow Game shares the point, box and line builders rather
than carrying another copy.
The historical lessons remain unchanged. The package regression checks the
recorded hashes and loads the real runner scene from an exported PCK with `doc/`
absent. If a form changes, update its provenance deliberately; do not silently
replace a historical lesson to make the hashes match.
