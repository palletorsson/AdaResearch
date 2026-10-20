# Void curation and native editor

User: floor services distract from artifacts. Preserve an encounter path; begin Lines with one line between two points. Half-built walls and existing construction prefabs. User needs direct control in Godot. Original museum final.md preserved.

Delivered:
- Overhead distribution at floor +4.8m, four sockets. Roof uses service masts; lower floors hang under slabs.
- Point Lines Floor03: relocated original black measurement enclosure to the south arrival, entrance facing south, exit west. Unfinished partitions screen later examples. Network in west wing, blue wooden police barriers in central north bay, fixed plank crossing into eastern construction studies, health X/+ beyond them.
- Native `addons/void_floor_editor` plugin enabled in project.godot; bottom panel Void Floors. Standalone editor.tscn also available. Grid move/rotate assemblies and named parts; two-click unfinished walls; prop palette; route waypoints; undo/redo; validation; revision-checked save/backups; launch real game from unsaved draft on chosen floor.
- Both editors and game share `commons/void/rooms.json`. Structural frame remains layout.json. Native plugin edits config.parts, preserving artifact scripts. Geometry manifest line_parts.json comes from actual built scenes, not guessed geometry. Refresh after code geometry changes: Godot probe emits line-parts.json in report output; copy to commons/void/line_parts.json.
- Palette reuses wood_pallet, fence_segment (razor wire disabled), concrete_barrier, plus existing container/crate. No claim that reference screenshots' asset pack is present.
- XRTools center_player_on skips runtime bodies without owner. Assign owner=self when creating VoidPlayerBody so relocation actually moves the body past walls.

Report: doc/book/iterations/2026-10-18-void-curated-route/index.html
Editor guide: addons/void_floor_editor/README.md

Verification: native game 219/219; PCK 220/220 (Windows export using Android exclusions); native editor 11/11; save validation 7/7; editor draft → real game position confirmed; shared web API 46/46. Forward+ and Mobile screenshots. Physical headset performance/comfort NOT tested. Existing engine warnings retained in logs. Changed web page has zero TypeScript diagnostics; whole encyclopedia has 288 elsewhere. Runtime sources match the tested stage; original final.md matches pre-task snapshot (already modified in working tree before this task).

Next curation: judge eastern workbench density in VR. Route points are advisory editorial records, not enforced in-game rails. Placement validation does not prove arbitrary individual part layouts walkable. Keep original scripts, use the shared placement layer; do not restore floor supply channels. Native editor preserves drafts and refuses saving over newer web/AI edits. Do not restart the user's open Godot editor automatically (unsaved work possible); tell them to reopen or enable the plugin.
