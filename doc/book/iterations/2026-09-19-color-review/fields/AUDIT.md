# Color fields: Rainbow, Pillar and Grid Pallet

Local source and actual-museum review, 19 September 2026. Read against `doc/book/review-feedback/2026-09-18/color/01-review.md`, its preliminary `GLANCE.md`, and `doc/book/REVIEW_PRINCIPLES.md`.

## Decisions

| Hall | Current purpose | Decision |
|---|---|---|
| Color_Rainbow | Repartition a familiar arch while its total width and traversable route remain fixed; celebration is available before achievement. | Preserve the chapter and encounter. Correct source comments that confused 48 RGB mesh bands with a physically continuous optical spectrum. |
| Color_Pillar | Walk a hue/saturation field; compare its unoccupied positions with 35 pillar samples, then 12 authored palette collections. | Preserve the chapter. Restore the hidden gradient by fixing this placement's half-metre sinking. Bring stale teacher-facing tutorial and intent into agreement with the live encounter. |
| Color_Grid_Pallet | Select, write, leave, return, overwrite; a rule's reach exceeds the visitor's editable range. | Preserve the chapter and implementation. Current controls execute the claimed stored-state cycle in the actual museum. |

All three `final.md` files remain byte-identical to their frozen 18 September copies. No roles, sequence order, shared shader, registry or global capture mode changed. Existing secondary works remain available.

## Pillar: the source was right, the encounter was hidden

The first source/runtime probe passed 96 checks: all 35 columns had correct materials and labels, dimensions agreed, and the plane UV directions matched the pillar coordinate field. Looking at the actual museum image nevertheless showed a neutral grid between the columns, not the gradient described by the text.

The map token placed the entire artifact at Y=-0.5. Its internally correct gradient plane at local Y=0.026 therefore sat at world Y=-0.474. A downward physical ray found the supporting floor at Y=0.0. The gradient was below it, and the black column footings were buried too. The newly added support-height check failed before the repair.

Applied one token change in `commons/maps/Color_Pillar/map_data.json`:

```diff
-pillarcolorcollection:0:-0.5:1#layout:spatial_gradient#plinth:0
+pillarcolorcollection:0:0:1#layout:spatial_gradient#plinth:0
```

The gradient now stands 0.026 m above the same collision floor. Columns have their full 4.6 m height above it. Structure, utilities, other placements and artifact implementation are unchanged. The material still distinguishes an unshaded floor from illuminated columns: equal computed values are not a claim of pixel-identical appearance.

The neighbouring palette wall retains its existing placement. Its 144 swatches have pick-up/drop methods and visible hex/name labels. That capability check does not establish comfortable tracked-controller reach or actual human pickup.

## Exact text changes

The book text was kept. Teaching and source descriptions changed:

| Location | Original | Replacement |
|---|---|---|
| Pillar tutorial opening | “Pillars collect colour. Mixing reveals process. Build a pillar of coloured segments.” | “Begin at the pale edge of `pillarcolorcollection`. Follow one line of columns into the field, then cross that line. Ask which colour property each direction changes before introducing its name.” |
| Pillar tutorial implementation | A hypothetical 12-segment cylinder tower and a material-multiplication flashlight helper described as physically accurate. | The actual coordinate-to-HSV rule, 5×7 samples, 3.2 m spacing, fixed value, label comparison and named palette wall; explicit distinction between calculated colour and its lit appearance. |
| Pillar intent | “visual_color_mixing is the conceptual centerpiece” | “The primary encounter is `pillarcolorcollection` in its spatial-gradient configuration, followed by the wall-mounted `color_sets_overview`.” |
| Rainbow source, `continuous` preset | “No seams at all — the spectrum as it physically is” | “Forty-eight discrete HSV samples converted to RGB mesh colours. ‘Continuous’ names the preset; the bands and their seams remain.” |

Rainbow identity comments now acknowledge the celebration controls, fixed mesh location and non-optical model. The six/two-colour presets are described as authored choices rather than unsupported universal historical or linguistic claims. Noncomment code is identical. Complete original files and unified diffs are in `before/` and the four `*.diff` files here.

## Runtime evidence

**220 focused checks pass in total:**

- **Rainbow 93/93:** actual museum; real button signals generate 6/7/48/2 bands, total width stays 5.6 generator units, step transforms stay fixed, the 96-instance confetti starts/ends/repeats, physical visitor overlap triggers welcome, a capsule can traverse the level centre route, and eight optional steps have collision.
- **Pillar 97/97 after; 96/97 before the repair:** actual museum; 35 sample materials and labels, all four plane UV corners, 4.6 m column height, 12 named groups and 144 swatch interaction contracts, plus the supporting-floor height check. The before failure is retained rather than hidden by the passing source checks.
- **Grid Pallet 30/30:** actual museum; five buttons bind to the correct room floor, one cell changes on COLOUR, X/Z selection wraps and finds the stored value again, RULE overwrites it, PALETTE reapplies the coordinate-sum assignment, every instance transform remains fixed, console height and capsule approach pass.

These checks simulate button signaling and selected physics conditions. No headset, tracked pressing/grabbing, complete walk through the sequence or novice reader test was performed. Logs retain the existing UID/certificate diagnostics, renderer feature warnings and shader-cache write errors; no GDScript parse/runtime errors were observed in these probes. Passing assertions do not certify every surrounding system.

## Images and their limits

Use **`evidence/paired/pillar-field-before.png`** and **`evidence/paired/pillar-field-after.png`** for the comparison page. Both are actual Godot museum renders at 1280×800, Vulkan/mobile, camera `(24.8, 1.7, 4.0)`, target `(24.8, 0.5, 18.0)`, FOV 70°. To hold camera and lighting exactly constant, one run replays the snapshotted old map token's sole changed parameter (pillar Y=-0.5), captures it, then restores the accepted Y=0 and captures again. The replay changes no production file and records both measured transforms in `evidence/after/pillar-field-checks.json` → `observations.paired_replay`.

Independent actual before/after runs also remain under `evidence/before/` and `evidence/after/`. Their first cameras followed the artifact height and should not be presented as exact matching views. The replay pair removes that ambiguity. The first initial source-only capture and all logs remain as the record of how the hidden plane was discovered.

`evidence/rainbow_celebration_museum.png` and `evidence/grid_address_museum.png` are current-state captures, not before/after changes. Rainbow's celebration and Grid Pallet's addressing needed validation rather than redesign. The palette-wall captures are supporting current context; neither a new wall nor a tested full pickup cycle is claimed.

## Next pressure to apply

Keep the authored celebration before explanation. Let learners discover the field/sample distinction now that the actual floor supports it. Check the field from a standing headset view, palette-wall physical reach, and whether the selected cell is legible from the Grid Pallet console before deciding on additional controls or prose changes. Existing maps and the current book already support a strong progression: partition → field/sample → address/write → accumulated mark.
