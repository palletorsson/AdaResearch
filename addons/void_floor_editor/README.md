# Void Floors

Native Godot bottom panel; also runnable as `addons/void_floor_editor/editor.tscn`.
Reopen the project after installation. Click **Void Floors** in the bottom panel (expand it for more room). If absent, enable **Void Floors** under Project Settings → Plugins.

1. Choose a floor. The plan shows its fixed slab, pillars, shafts and landing.
2. Select an artifact in the plan or searchable list. A large circle is an assembly; small points are individual parts. Drag, enter X/Z, or rotate 90°. Search “Caption” to move lettering.
3. Choose **Draw unfinished wall** and click its two ends. The wall locks to an axis. Wall height applies to new walls; **Set wall height** changes a selected wall.
4. Choose **Place prefab** and pick a container, crate, pallet, concrete barrier or fence. Click the plan. Delete removes walls, scenery and route points. Teaching artifacts stay available.
5. Green route points record encounter order. They guide our editing; they do not restrict the player. Add or move them as the argument evolves.
6. **Undo/Redo** keep up to 100 whole-document snapshots. **Validate** checks the shared schema and structural placements.
7. **Walk this floor** launches the real desktop game with the unsaved draft. WASD/mouse, Space jump, R retry, Esc frees the mouse. Close the preview before testing another draft.
8. **Save layout** publishes to `commons/void/rooms.json`. Restart the Void scene to see it in VR. Reload the web editor to see the same layout there.

The editor saves a revision-checked file and keeps backups in `ada_run/void-editor-backups`. If another editor changes the source, saving is refused and your draft remains in `ada_run/void-editor`. Reload discards local changes only after confirmation.

Geometry and interaction logic stay in their original scenes. `config.parts` overrides the local position and rotation of named children in the four Lines assemblies. The plan's geometry bounds come from the actual built artifacts, recorded in `commons/void/line_parts.json` by the Godot probe. Refresh that manifest after changing generated geometry; it is not a second authored layout.

Validation catches malformed records, walls/props across shafts, blocked arrival areas and overlapping access footprints. It cannot prove that arbitrary arrangements of individual artifact parts are walkable. Use the walk preview; the curated route has separate desktop and synthetic-XR movement checks. Physical headset testing remains necessary.

Saving/validation needs the project's Python environment with `jsonschema`, also used by the web editor. Preview uses the running Godot executable.
