# Map Building Guide — What Claude Understands

## The Three Layers

### Structure Layer (what the player walks on)
```
"0" = void (no floor, player falls)
"1" = standard floor (1m cube, walkable)
"2" = wall (2m, blocks movement)
"3" = tall wall (3m)
"4" = very tall wall (4m)
"5" = decorative pillar (5m)
```
GridSystem reads these → creates BoxMesh geometry.

### Utilities Layer (game mechanics)
```
" "  = empty
"sp" = spawn point (player starts here)
"t"  = teleporter (goes to next map in sequence)
"r"  = ramp (connects different heights)
"ds" = dark sphere (darkens scene, artifacts glow)
"l:text" = label (floating 3D text)
"m:x:y:z:delay" = move player to position after delay seconds
"an:angle" = set player facing angle
"sub:scene_name" = sub-scene portal
"3t:text" = 3D text display
```

### Interactables Layer (artifacts)
```
" " = empty
"artifact_lookup_name" = places the artifact at this cell
"artifact_name:rotation" = with rotation in degrees
"artifact_name:rotation:y_offset" = with vertical offset
"artifact_name#variant:rotation:scale" = variant with scale
```

## Map as Narrative Space

Every good map follows a 5-phase narrative:

### Phase 1: Entry
- Spawn point with clear sightline
- Context-setting artifact (origin marker, coordinate system)
- `m:x:y:z:0.1` to position player precisely

### Phase 2: Teaching
- Main artifact (the thing this map teaches)
- Placed at center or prominent position
- Interactive — the player DOES something

### Phase 3: Exploration
- Related artifacts around the teaching artifact
- Supporting visualizations
- Different perspectives on the same concept

### Phase 4: Reflection
- Text labels (`3t:quote`) with definitions or quotes
- Dark sphere (`ds`) creates contemplative atmosphere
- Smaller, quieter artifacts

### Phase 5: Exit
- Teleporter (`t`) with clear path
- Often at the edge or far end of the map
- Leads to next map in sequence

## Example: Point_One (7x10 grid)
```
Row 0: Entry — origin marker, folding sculpture, static point, spawn
Row 2: Sub-scene link to point_zero
Row 3: Interactive point origin (TEACHING)
Row 5: Teleporter + dark sphere (EXIT through darkness)
Row 8: "that which has no part" — Euclid (REFLECTION)
Row 9: Frame counter + coordinate system (REFERENCE)
```

## How to Use Map Studio

1. Open /map-studio in the encyclopedia
2. Set grid size (Width × Depth)
3. Structure tab: paint floors (1) and walls (2)
4. Utilities tab: place spawn, teleporter, dark sphere
5. Interactables tab: search artifacts, click to place
6. Save to Godot → creates map_data.json
7. Load in Godot to test

## Key Principles

- **Less is more**: 3-5 artifacts per map, not 20
- **Sightlines matter**: player should see the main artifact from spawn
- **Dark sphere creates focus**: darkness makes artifacts glow
- **Walls create rooms**: use height 2 walls to define spaces
- **Void creates drama**: holes in the floor create tension
- **Labels teach**: `3t:` text gives context the artifacts can't
- **Sequence flow**: each map should feel like a chapter in a book

## Map Studio
Built at `/map-studio`. I (Claude) built this from scratch and understand every layer.
API: `/api/map-studio` (save/load), `/api/map-studio/artifacts` (search registry)

## Design Language (learned from studying primitives maps)

### Layout Principle: Top-to-Bottom Like a Book Page
Maps are TALL, not wide. The player reads the map by walking forward (increasing row).

### Consistent Elements
- **Row 0:** Spawn (`sp`) + `m:x:y:z:0.1` for precise position + `an:-90` at right edge
- **Row 1-3:** Teaching artifacts (the main content)
- **Center area:** Dark sphere (both artifact + `ds` utility)
- **Row 10-20:** Exploration artifacts, sub-scene portals (`sub:`)
- **Near bottom:** Teleporter on VOID (`t` on S=0 — you fall to exit)
- **Last rows:** Text label (`3t:concept_name`) + reference tools

### Artifact Parameters
```
artifact_name                      → default placement
artifact_name:rotation             → rotated (degrees)
artifact_name:rotation:y_offset    → rotated + lifted/lowered
artifact_name:rotation:y_offset:scale → rotated + offset + scaled
artifact_name#variant              → variant of the artifact
artifact_name:0:1.2:0#fillhole:remove → with group commands
```

### Grouping System
- `#fillhole:remove` — this artifact creates a hole when removed
- `#group:fillhole` — this artifact belongs to the fillhole group
- When the puzzle artifact is solved, grouped artifacts appear/disappear

### Key Dimensions
- Point_One: 7x10 (small, focused)
- Point_Lines: 7x27 (tall, sequential)
- Point_Trace: 7x14 (medium)
- Average: 7 wide, 10-27 deep

## Artifact Reading Light

Artifacts store a `reading_light` in their registry `parameters` that describes how the artifact radiates readability toward the player. Based on light principals:

**Light types:**
- **Omni** — readable from all sides, like a point light (sculptures, 3D objects you walk around)
- **Spot** — cone of readability from a front face (displays, demos with a viewing sweet spot)
- **Area** — flat directional projection, narrow cone (screens, paintings, info boards)

**Properties:**
```json
"reading_light": {
  "type": "spot",        // "omni" | "spot" | "area"
  "direction": "+z",     // front face: "+z" | "-z" | "+x" | "-x" (ignored for omni)
  "cone": 90,            // viewing angle in degrees (spot: 30-170, area: 45, omni: 360)
  "radius": 3            // readable range in grid cells
}
```

**Rotation mapping** (to point the front toward the player):
- `direction: +z` → `:0` rotation
- `direction: +x` → `:270` rotation
- `direction: -z` → `:180` rotation
- `direction: -x` → `:90` rotation

**Edit** in the encyclopedia at `/scenes/detail` — the footprint card shows the light cone on the grid. Click to cycle direction, adjust cone and reach with sliders.

**Footprint:** 669/1678 artifacts have `footprint: [w, h, d]` in registry.
The rest need measurement or capture to understand their size.

**386 artifacts have 4-angle captures** in the encyclopedia gallery.
The Map Studio should show these previews when placing artifacts.
