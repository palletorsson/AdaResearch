# Pattern Maker → Roman Carpet Composer: Upgrade Plan

## The Problem

The MANN photos show Roman floors that are **nested-frame compositions** — carpets with borders within borders, threshold strips, corner treatments, and multiple pattern zones at different depths. The current mosaic-editor supports only **1 border ring** (field + border + corner + threshold). Real Roman floors have 2-4 concentric border rings, each with a distinct pattern and width.

## What Already Works

- **Pattern-maker** (`/pattern-maker`): single-pattern domain editor — 17 wallpaper groups, domain painting, shader preview. This is the **motif workshop**.
- **Mosaic-editor** (`/mosaic-editor`): 4-zone compositor (field, border, corner, threshold). This is the **carpet layout** tool.
- **Godot shader** (`wallpaper_tile.gdshader`): GPU-renders all 17 groups + 6 tile shapes + aging/weathering.
- **PatternLoader** + `pompeii_mosaic_floor` artifact: loads composite JSON, builds textured floor mesh.
- **Italy study pack**: 25+ motifs, 6 site presets, 5 period palettes.

## What's Missing (from the MANN photos)

1. **Multiple border rings** — Photo 3 has sawtooth → guilloche → large diamonds → field
2. **Per-ring width control** — outer sawtooth is narrow (2 tiles), inner diamond band is wide (6 tiles)
3. **Per-ring corner treatment** — each ring needs its own corner resolution
4. **Plain separator bands** — thin solid-color lines between zones (visible in every photo)
5. **Aspect ratio** — floors aren't square; photo 2 is clearly wider than tall

## Proposed Approach: Evolve the Mosaic Editor

Rather than building a new tool, upgrade the mosaic-editor to support **N border rings** as a stack:

### Data Model Change

```typescript
// Current (flat 4 zones):
zones: { field, border, corner, threshold }
borderWidth: 3

// Proposed (ring stack):
rings: [
  { pattern: ZoneConfig, width: 2, corner?: ZoneConfig, label: "outer sawtooth" },
  { pattern: ZoneConfig, width: 1, label: "separator" },  // plain band
  { pattern: ZoneConfig, width: 4, corner?: ZoneConfig, label: "guilloche" },
  { pattern: ZoneConfig, width: 1, label: "separator" },
]
field: ZoneConfig      // center fill (unchanged)
threshold?: ZoneConfig // bottom strip (unchanged)
aspectRatio: [5, 4]    // width:height ratio
```

### Composition Algorithm Change

```
composeMosaic() currently:
  1. Fill all with border
  2. Overwrite inner with field
  3. Stamp corners
  4. Stamp threshold

composeMosaic() proposed:
  1. Start from outermost ring, fill inward
  2. For each ring: fill its band, then stamp its corners
  3. Finally fill center with field
  4. Stamp threshold over bottom

  Total border depth = sum of all ring widths
  Each ring's inner edge = previous ring's outer edge - ring.width
```

### UI Changes to Mosaic Editor

1. **Ring stack panel** (left sidebar) — add/remove/reorder rings, each with width slider
2. **Ring selector** — click a ring in the preview to edit it
3. **Separator quick-add** — button to insert a 1-tile solid band between rings
4. **Aspect ratio control** — width:height dropdown (1:1, 5:4, 4:3, 3:2, 2:1)
5. **Floor preview** updates to show nested rings with click targets per ring

### Steps

1. **Update types** — `MosaicComposite` gains `rings: BorderRing[]` array, `aspectRatio`
2. **Update `composeMosaic()`** — iterate rings outside-in, each with its own width + corners
3. **Update `FloorPreview`** — render nested ring overlays with click targets
4. **Update `MosaicEditorPage`** — ring stack UI, add/remove/reorder rings
5. **Update `ZonePanel`** — show active ring's motif options
6. **Backward compat** — old `{ border, borderWidth }` format auto-converts to single-ring
7. **Update Godot `pattern_loader.gd`** — parse `rings` array from JSON
8. **Fix shader** — keep the `return` → `else` fix and `float/int` fix (these are legitimate bugfixes, not behavior changes)

### What We Do NOT Change

- Pattern-maker stays as-is (motif workshop)
- Shader stays as-is (already handles everything)
- The wallpaper group math stays the same
- The study pack motifs stay the same
