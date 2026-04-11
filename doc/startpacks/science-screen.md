# Development Start: Science Screen

**Intent:** `Science Screen`
**Matched topic:** `science_screen`
**Pack slug:** `science-screen`
**Category:** `visualization`
**Tags:** `science-screen, visualization, vr-web-bridge, 2d, primitives`
**Generated:** `2026-04-04T11:51:08+00:00`

Science Screen is the 2D mirror for 3D VR interactions. It is the right starting point when the task touches visual parity between VR and web, on-screen coordinate feedback, mode-specific visualizers, or the 2D-to-3D bridge.

## Trust Order
- repo files
- doc/ and docs/ contracts
- session handoffs and session summaries
- grounded wiki chat points and turns
- encyclopedia routes and source files
- DeepWiki overview

## Read First
- `doc/SCIENCE_SCREEN_SYSTEM.md` — System contract for the VR/web bridge, rendering modes, and style parity.
- `commons/artifacts/science_screen/science_screen.gd` — Main Godot artifact with scanning and mode dispatch logic.
- `commons/artifacts/science_screen/screen_overlay.gd` — Overlay and presentation logic around the rendered screen surface.
- `commons/artifacts/registry/primitives.json` — Registry truth for primitive artifacts the screen mirrors.
- `doc/PRIMITIVE_ONTOLOGY.md` — Conceptual frame for the primitives the screen is teaching.

## Core Principles
- The 2D screen is not secondary UI; it is the explicit mirror of embodied 3D interaction.
- VR and web should preserve the same visual language: grid, colors, readout, and mode logic.
- The screen should auto-adapt to nearby artifacts instead of requiring bespoke map configuration.

## Key Constraints
- VR truth is the science_screen artifact and its mode scanners; web parity should follow that contract, not drift independently.
- The screen style is intentionally scientific and shared across platforms.
- If you add a new mode, you need both a Godot renderer path and a web renderer path.

## Suggested First Moves
- Decide whether the change is a new mode, a visual-style adjustment, or a scanner/detection change.
- Check the current Science Screen system doc before editing the artifact or the web mirror.
- Verify whether the web mirror needs updating in parallel with the Godot artifact.

## Relevant History
- `doc/SESSION_HANDOFF_2026-03-28.md` — Over six days, this session built the Naples-to-VR pipeline end-to-end: 42 procedural floor patterns from MANN museum photos, 27 facade presets from Italian buildings, 23 museum maps with floor plans, a floor plan editor
- `doc/sessions/2026-03-19-garden-session-summary.md` — 8. **verlet_integration** — rebuilt: side-by-side Euler vs Verlet with ghost line
- `doc/sessions/2026-03-23-continued-session.md` — 8. **verlet_integration** — rebuilt: side-by-side Euler vs Verlet with ghost line

## Related Docs
- `doc/SCIENCE_SCREEN_SYSTEM.md` — # Science Screen System — Architecture for AI Onboarding
- `doc/LOD_TREE.json` — "xyz_coordinates"
- `doc/CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md` — "Random_Rotate_Random_XYZ",
- `doc/FOCUS_VECTOR.json` — "Study existing maps first (Point_One is the model)",
- `doc/PRIMITIVE_ONTOLOGY.md` — ## Point — The Act of Choosing

## Related Repo Paths
- `commons/artifacts/science_screen/science_screen.gd`
- `commons/artifacts/science_screen/science_screen.gd.uid`
- `commons/artifacts/science_screen/science_screen.tscn`
- `commons/artifacts/science_screen/screen_layout.tscn`
- `commons/artifacts/science_screen/screen_overlay.gd`
- `commons/artifacts/science_screen/screen_overlay.gd.uid`
- `commons/artifacts/science_screen/screen_theme.tres`
- `commons/primitives/point/draw_triangle_faces.gd`

## Grounded Wiki Chat Knowledge
- source project slug: `adaresearch-case-study`
- point [fact] support=3: What: The Science Screen is a **2D visualization surface that mirrors 3D VR interactions**. In VR, the player grabs a point, draws a line, builds a triangle. The Science Screen - a large monitor standing in the map - renders a 2D coordinate grid showing exactly what the player is doing, with live coordinates, measureme...
- point [decision] support=1: You're describing the 2D-3D knowledge loop again - but now applied to the Science Screen specifically. The web primitive editors at `/primitives/point`, `/primitives/line`, `/primitives/triangle` ARE the 2D versions of what the Science S...
- point [fact] support=1: Modes currently deployed through map data: `bars`, `field`, `grid`, `line`, `net`, `point`, `scatter`, `trace`, `triangle`, `wave`
- point [fact] support=1: Tracker modes detected in code: `point`, `line`, `trace`, `triangle`, `net`, `wave`, `field`, `scatter`, `grid`, `bars`
- claim [fact] support=1: What: The Science Screen is a **2D visualization surface that mirrors 3D VR interactions**. In VR, the player grabs a point, draws a line, builds a triangle. The Science Screen - a large monitor standing in the map - renders a 2D coordinate grid showing exactly what the player is doing, with live coordinates, measureme...
- claim [fact] support=1: What: The Science Screen is a **2D visualization surface that mirrors 3D VR interactions**. In VR, the player grabs a point, draws a line, builds a triangle. The Science Screen - a large monitor standing in the map - renders a 2D coordinate grid showing exactly what the player is doing, with live coordinates, measureme...
- claim [fact] support=1: What: The Science Screen is a **2D visualization surface that mirrors 3D VR interactions**. In VR, the player grabs a point, draws a line, builds a triangle. The Science Screen - a large monitor standing in the map - renders a 2D coordinate grid showing exactly what the player is doing, with live coordinates, measureme...
- claim [decision] support=1: You're describing the 2D-3D knowledge loop again - but now applied to the Science Screen specifically. The web primitive editors at `/primitives/point`, `/primitives/line`, `/primitives/triangle` ARE the 2D versions of what the Science S...
- turn `c5c4c59b-9852-43e3-acf6-0d49b1df6811#371` (assistant): Massive update - science screen went from 610 to 1,455 lines. Let me verify it parses: No science_screen errors! The parse errors are from other files (base.tscn, lab.tscn - those are from the dark sphere changes, not related). Let me commit everything: Done. The Science Screen now has **6 visualization modes** that au...
- turn `c5c4c59b-9852-43e3-acf6-0d49b1df6811#357` (assistant): Both agents completed. We have the full designs for: 1. **Line tracker** - two endpoint dots (cyan A, orange B), connecting line, distance |AB|, angle θ, projection lines, delta vector 2. **Draw dot tracker** - 2D path plot of all `_trail_points`, stroke visualization, point count, trail length, bounding box These are ...
- turn `c5c4c59b-9852-43e3-acf6-0d49b1df6811#463` (assistant): ...rum analyzer, lab equipment. Let me explore the current state and plan. Now let me also look at the Godot Science Screen `_draw_point_tracker` to understand what needs updating there: Now let me check the line and trace pages briefly for scope: Good - all three pages share the same light palette constants. Now I have e...
- turn `c5c4c59b-9852-43e3-acf6-0d49b1df6811#369` (assistant): Agent building all science screen modes + improved frame in one pass. It's adding: - **Line tracker** - two endpoints, distance, angle, projections - **Draw dot tracker** - 2D path plot of strokes - **Triangle tracker** - three vertices, area, angles, filled shape - **Generic tracker** - catch-all for sorting/noise/wav...

## Encyclopedia Surfaces
- Science Screen XY — route `/primitives/science-screen` — source `src/components/shared/ScienceScreenXY.tsx` — Web mirror component for the VR Science Screen modes.
- Timeline Editor — route `/timeline-editor` — source `src/app/timeline-editor/page.tsx` — Relevant when the Science Screen is revealed or sequenced in scripted map flow.

## DeepWiki
- Base: https://deepwiki.com/palletorsson/AdaResearch
- Suggested topic: Artifacts & Interactables
- Suggested topic: Interactive Components
- Suggested topic: Map & Content Definition