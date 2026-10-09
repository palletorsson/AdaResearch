# Tiling: keep the source, name what reads it

4 October 2026. Eight revised summary proposals, with a compact image/change card for each map. Keep the mature room order and critical writing. Full tutorials, artifact logic and placements are unchanged.

The sequence returns to Arrays’ addressed values and Colour’s palette assignment. It adds the separation between a finite source, the rule reading it and its receiving surface. Its most useful new making capacity is the small shader at the end. Reaching that shader does not require rebuilding the museum’s editors, loom, wardrobe or renderer.

## Eight decisions

1. **Disco:** reuse the existing checker lookup. Vary palette and phase independently. Super Triangle is a separate shader drawing and can remain an optional comparison.
2. **Foundry:** one four-by-four source and wrapping reader on the first visit; copies and saved states on a return. Keep the richer machines available without making them one programming assignment.
3. **Tutorial Pattern:** distinguish reading columns backwards from changing the entries inside each source row. Reversing the row order would be a different reflection.
4. **Array Patterns:** use the installed fixed source for now. State face origin, direction and cell width. A forty-centimetre cell makes a four-cell motif 1.6 metres wide; forty centimetres at the previous station describes the whole motif.
5. **Symmetry:** inspect two source blocks, then test a translation period. A four-row source allows the installed two-row glide shift. Three checked comparisons are not a proof of the seventeen-group classification.
6. **Ribbon 01:** explicitly read `SOURCE[z][x]` into `values[y][z][x]`. With shifting enabled, x=3, y=2, z=1 reads source [1][1]. Zero is a pale colour index. Hiding layers leaves all 64 values intact.
7. **Ribbon 02:** keep the reflective comparison. Equal source values, equal surface distances and equal viewed widths are different claims. No new code or prescribed perceptual response is required.
8. **Ribbon 03:** teach only UV, repeat, offset and texture sampling in the existing studio host. Save/apply uses an existing bounded recipe; finish, cut-out and vertex displacement stay optional encounters before their later shader study.

## What already connects, and what does not

`PatternTilePuzzle` stores palette indices in `_grid_data[row][column]`. Its `get_pattern_data()` returns a deep copy and `set_pattern_data()` imports one. It also publishes changes to TraceData, which `array_carpet` can consume. Persistence therefore already exists in the project. However, the later Pattern Maker, tunnel, symmetry comparison, volume and fabric studio install their own starting sources. Reappearance of a familiar mark is not evidence that the student’s edit travelled there. A new import would also need to preserve the meaning of palette indices.

The loom has a separate five-by-five card. Its receiver HOLD declines later images and keeps the accepted image; it does not freeze the source. Its SAVE includes the card, palette, band history, animation state, repeat metres and offset metres, but excludes held receiver images. The architectural console can repeat an entire machine output over a specified metre span. These are different storage and scale decisions from copying a small source array.

Tunnel cells measure 0.4 or 0.6 metres, so one four-cell source repeat occupies 1.6 or 2.4 metres. The plane and half-cylinder comparison later keeps physical surface spacing equal. In the studio, repeat counts are per mesh UV span: four repeats across a three-metre wall occupy 0.75 metres each, while four around a differently sized skirt need not. Preserve this unit change in the lesson.

## The existing shader host

`fabric_recipe.gd` converts four-by-four palette indices through its fixed palette into an RGBA8 image. `material()` binds that texture and the recipe uniforms to `fabric.gdshader`. The sampler uses nearest filtering and wrapping. `fabric_shader_studio.gd::refresh()` assigns the resulting material to the wall and applies the recipe to the preview skirt. Explain this support before presenting the small fragment calculation:

```glsl
vec2 address = UV * vec2(repeats, 2.0) + vec2(phase, 0.0);
ALBEDO = texture(motif, address).rgb;
```

This is an excerpt of the installed shader, not a complete standalone shader. The full lesson must select the exact edit location, explain `fragment`, and state the texture/uniform inputs and material receiver. There is no need to invent another host. The independent variation changes repeat count while holding offset, then changes offset while holding count. Keep ordinary material creation and wardrobe internals supplied.

SAVE writes recipe cells and supported settings, not arbitrary shader source, a palette, meshes or the chosen LOOK. Validated horizontal repeats are 4 or 8 and offsets 0 or 0.125. WEAR SAVED reads the saved data and chooses the current preview silhouette separately; a supported mesh named `Skirt` receives the fabric. Live source edits do not silently alter the worn snapshot. A shader experiment outside that schema is not made portable by SAVE.

## What remains

All three Ribbon `tutorial.md` files are absent. Existing controls and code excerpts provide material for the future lessons, not evidence that the lessons have been written or learner-tested. This pass makes the selection and support precise. Each map remains a separate reviewable proposal.

The exit to Change introduces a new callable curve. A nearest-sampled repeating texture is not automatically a smooth function for differentiation. What carries forward is the habit of naming an input, reading a result and keeping the receiving operation explicit.

**Compact AI brief:** Existing museum; summary pass. Source indices → palette → sampled image → stated receiver. Keep first Foundry visit small; copy/history later. Distinguish read reflection from source mutation. Declare cells/metres/UV counts. Preserve fixed-source truth and actual limited persistence. Volume ZX→YZX, zero=colour. Ribbon02 reflective. Studio host already exists; tiny fragment lesson, bounded recipe save. Preserve finals/order/code; full companions pending.
