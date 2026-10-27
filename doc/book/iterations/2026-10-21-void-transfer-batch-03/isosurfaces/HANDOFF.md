# Isosurfaces transfer / batch 03

Codex transferred all nine original placements from ISO_Introduction and ISO_LookupTable. The source inventory records original cells, tokens and hashes. Original scenes, algorithms, map files and chapter text remain unchanged. The main tower is unchanged.

## Host adaptations

- `iso_console.gd` and `lookup_console.gd` inherit the original workshop scripts. Only their binding/setup methods change: each finds its partner by artifact identity on its own streamed floor, rather than the Endless Museum `_edit_records` registry. Original actions, readouts and extraction are inherited.
- Console lighting is attached to its editable mount, replacing the old hall-coordinate lighting positions. The held field copy still uses the original eight-metre offset.
- Eight-metre trial storeys preserve the full 5.76 m field at its original four-metre anchor. Shaft A corner pads retain a protected descent. The artifact-height schema now permits taller anchors; validation checks the actual storey clearance rather than assuming a 2.5 m universal maximum.
- The original fifteen-case spacing (2.5), case size (1.2), field seed, sample-count controls, film, threshold study and metaball lattice are retained. Each original placement is a separate editor object.

## Fit and interpretation still pending

- The original GPU cave is 45 × 45 × 45 m at its museum scale of 0.15. It is positioned beside the west edge of this isolated trial, clear of both shafts. Its vertical extent crosses multiple storeys outside the tower. This is deliberately recorded as unresolved spatial integration, not disguised by shrinking it.
- The original cave produces 386,936 triangles and its own generator skips collision above its polygon limit. It is a display specimen, not a safe walkable cave. Mobile GPU extraction must succeed; the simple tunnel fallback is not an equivalent export.
- The field ScienceScreen retains its original `mode:field` configuration. Its generic field display is not a new verified live slice of the marching-cubes field; that interpretation is deferred to curation.
- Browser models are static native geometry snapshots. Procedural shaders, private film playback, physics and controls run in Godot.

## Acceptance evidence

See `evidence/source-checks.json`, `checks.json`, `editor-checks.json` and the four native PNG captures. Native tests use actual desktop mouse controls and synthetic tracked XR controllers. They cover threshold/sample changes, independent held copies, unchanged masks with changed crossing positions, display modes, moved/turned controls, real GPU extraction, descent, floor sleep and checkpoint retry. Physical headset review and curation remain pending.
