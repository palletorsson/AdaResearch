# Science Screen System — Architecture for AI Onboarding

## What It Is

The Science Screen is a **2D visualization surface that mirrors 3D VR interactions**. In VR, the player grabs a point, draws a line, builds a triangle. The Science Screen — a large monitor standing in the map — renders a 2D coordinate grid showing exactly what the player is doing, with live coordinates, measurements, and trails.

The same visualization runs in the web encyclopedia as interactive editors. The player can iterate on the 2D version (fast, mouse-based) before experiencing it in VR (immersive, body-based). **Same lesson, different body.**

## Where Everything Lives

### VR Side (Godot 4.6)

```
commons/artifacts/science_screen/
├── science_screen.gd          # 1,455 lines — the VR artifact
└── science_screen.tscn         # Scene file

The artifact:
- Extends Node3D
- Builds a physical screen (PlaneMesh + border + stand + LED) with SubViewport
- Inner class _ScreenCanvas (extends Control) renders 2D graphics into the viewport
- The viewport texture is applied to the screen mesh as an unshaded emissive material
- Auto-scans nearby artifacts every 1 second to detect what to visualize
```

**Detection priority** (checked in order):
1. **Point mode** — finds nodes with `"point"` in lookup_name + `freeze` property (XRToolsPickable)
2. **Line mode** — finds nodes with `"line"` in lookup_name + two child grab points
3. **Draw dot mode** — finds nodes with `"draw_dot"` in lookup_name
4. **Triangle mode** — finds nodes with `"triangle"` in lookup_name + three child vertices
5. **Generic mode** — catches sort/noise/wave/force/fractal/swarm/graph/mesh artifacts
6. **Grid mode** (default) — finds any node with `apply_grid_config` method + grid data

**Artifact scanning** happens in `_process()` via `_scan_for_points()`, `_scan_for_lines()`, etc. Each scanner walks the scene tree looking for nearby nodes (within `scan_radius`) with matching metadata (`artifact_lookup_name` meta key).

**Rendering** happens in `_ScreenCanvas._draw()` which dispatches to mode-specific draw functions:
- `_draw_point_tracker()` — XY grid, glowing dot, trail, projection lines, coordinate readout
- `_draw_line_tracker()` — two endpoints (cyan A, orange B), golden connecting line, distance/angle
- `_draw_dot_tracker()` — 2D path plot of strokes, bounding box
- `_draw_triangle_tracker()` — filled triangle, three vertices, area/angles/side lengths
- `_draw_generic_tracker()` — dispatches to sort (bar chart), waveform, scatter, graph, radar

**Shared utilities** inside _ScreenCanvas:
- `_draw_xy_grid()` — draws the scientific coordinate grid (minor/major lines, axes, labels)
- `_draw_scanlines()` — CRT overlay effect
- `_world_to_screen()` — maps 3D world position to 2D viewport pixel

### Web Side (Next.js / TypeScript)

```
ada_encyclopedia/src/
├── components/shared/
│   ├── ScienceScreen.tsx       # Grid mode component (original)
│   └── ScienceScreenXY.tsx     # Multi-mode XY component (new)
└── app/primitives/
    ├── point/page.tsx          # Point Game — drag dot to target, explode, repeat
    ├── line/page.tsx           # Line editor
    ├── triangle/page.tsx       # Triangle editor
    ├── science-screen/page.tsx # All modes showcase
    └── ... (16 more primitives)
```

**ScienceScreenXY.tsx** — Reusable React component matching the Godot Science Screen exactly:
```tsx
<ScienceScreenXY
  mode="point"           // point | line | triangle | draw | scatter
  point={{x: 1.5, y: 2}} // current position
  trail={[...]}           // movement history
  width={480} height={400}
  range={5}               // coordinate range (-5 to +5)
/>
```

**Point Game** (`/primitives/point`) — Interactive game:
- Pink dot at origin, colored target ring at random position
- Click-drag the dot to the target
- On arrival: 24 particles explode, new target spawns, score increments
- Trail shows movement history, projection lines show X/Y components
- Coordinate readout updates live
- Teaching messages rotate: "position is distance from origin"

### The 2D-3D Bridge

```
Web Editor (mouse)           VR Experience (body)
/primitives/point    ←→    interactive_point_origin + Science Screen
/primitives/line     ←→    line artifact + Science Screen
/primitives/triangle ←→    triangle artifact + Science Screen
/primitives/wave     ←→    wave artifact + Science Screen

Same colors. Same grid. Same readout layout.
Design in 2D (fast). Experience in 3D (immersive).
```

### Map Integration

Science Screens are placed in maps via `map_data.json` interactables layer:

```json
"interactables": [
  [" ", "interactive_point_origin:0:0.2", " "],
  [" ", " ", "science_screen:180:1", " "],
  [" ", " ", " ", " "]
]
```

The screen auto-detects the nearby point artifact and switches to point tracking mode. No configuration needed — it scans and adapts.

### Timeline Integration

The timeline system can reveal/hide the Science Screen as part of a scripted sequence:

```json
{
  "id": "show_screen",
  "trigger": { "type": "after", "event": "player_reaches_point", "delay": 1.0 },
  "actions": [
    { "type": "reveal", "target": "science_screen", "animation": "fade_in", "duration": 1.0 }
  ]
}
```

## Visual Style (shared between VR and Web)

```
Background:     rgb(5, 5, 10)         — near-black
Grid minor:     rgb(15, 18, 23)       — barely visible, 20 divisions
Grid major:     rgb(26, 30, 41)       — subtle, 4 divisions
X axis:         rgba(179, 38, 38, 0.5) — red, horizontal
Y axis:         rgba(38, 179, 38, 0.5) — green, vertical
Point dot:      rgb(255, 153, 255)    — pink with glow halo
Accent:         rgb(102, 204, 255)    — cyan for headers/highlights
Text dim:       rgb(128, 128, 140)    — secondary labels
Scanlines:      rgba(0, 0, 0, 0.04)  — every 3px, CRT effect
LED:            rgba(50, 220, 80, pulse) — top-right, pulsing green
Frame:          rgba(102, 204, 255, pulse) — subtle border glow
```

## How to Add a New Mode

### Godot (VR):
1. Add member variables: `var _new_mode: bool = false`, `var _tracking_new: Node3D = null`
2. Add `_scan_for_new()` function following the pattern of `_scan_for_points()`
3. Add `_draw_new_tracker()` to `_ScreenCanvas` inner class
4. Route in `_draw()`: check `screen_ref._new_mode` before existing modes
5. Reset in `_process()`: validate tracked node still exists

### Web (encyclopedia):
1. Add mode to `ScienceScreenXY.tsx` props type
2. Add draw function following the Canvas2D pattern
3. Create `/primitives/new/page.tsx` with interactive game mechanics

### Key Rule
The VR and web versions must look identical. Same colors, same grid, same readout layout. The only difference is input: VR uses hand grab, web uses mouse drag. The visualization is the same because **the lesson is the same**.

## Data Flow

```
VR:  Player grabs artifact → artifact.global_position → Science Screen scans → _draw() renders
Web: Mouse drag → state.point = {x, y} → requestAnimationFrame → canvas.draw() renders

Both produce: XY grid + dot + trail + projection lines + coordinate readout
Both teach:   position = (x, y) = distance from origin
```

## Files Quick Reference

| What | Where |
|------|-------|
| VR Science Screen | `commons/artifacts/science_screen/science_screen.gd` |
| VR Point artifact | `commons/primitives/point/interactive_point_origin.gd` |
| VR Line artifact | `commons/primitives/line/line.gd` |
| VR Triangle artifact | `commons/primitives/triangle/triangle.gd` |
| VR Draw Dot artifact | `commons/primitives/point/draw_dot.gd` |
| Web shared component | `ada_encyclopedia/src/components/shared/ScienceScreenXY.tsx` |
| Web point game | `ada_encyclopedia/src/app/primitives/point/page.tsx` |
| Web all primitives | `ada_encyclopedia/src/app/primitives/` |
| Timeline system | `commons/grid/GridTimelineComponent.gd` |
| Timeline editor | `ada_encyclopedia/src/app/timeline-editor/page.tsx` |
| Artifact registry | `commons/artifacts/registry/primitives.json` |
