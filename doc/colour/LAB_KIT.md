# The lab kit: what the forces and waves studies are built from

*2026-10-28. Palle: "we need to dream how these items should look. It should be based on the prefab we made in earlier captures. So what prefabs are needed and good to have. We should see to that we have them and they are excellent."*

## The dream

A study in the spatial lab is a small workshop installation, built from the same props the Void's floors are built from (the earlier captures: `ada_encyclopedia/public/void-models`, 44 props with a model and a thumbnail each). Timber planks lapped into a gantry, pallets for feet, a crate for a mass, a black trace ball for anything thrown, a work light on a tripod, the record of a motion stuck down in coloured tape on a timber board standing on the workbench. The physics is the only thing drawn rather than found: arrows in painted steel, a steel coil, tape lines. Each artifact's own look stays the default; the kit is a `dress` a study can be switched into, so the defaults (and every placement of the artifacts) are untouched.

Pilot: `spring_tower` with `dress = workshop kit` (`/spatial-lab?family=colour&study=spring_tower&dress=workshop%20kit`). The same expression builds the real prop scenes in Godot and the exported models in three.js.

## How a prefab reaches both pictures

- **Godot:** a prefab leaf `{p: 'prefab', token}` instantiates the scene the spawn lists name. The spawn lists name none for the Void's `kit:` and `prop:` entries, so until today every one of them built a labelled placeholder box. `commons/modular/builder.gd` now falls back to `commons/void/catalog.json` `props[token].scene` (read only, only when the spawn list gave nothing; forum 261028-bwb8y).
- **three.js:** `KIT_PREFABS` in `src/lib/colour-study.ts` gives each token its exported model and `offset`. The Void's exports rest on the floor while their scenes are centred at the catalogue offset (a plank: 0.03 m), so `PrefabInfo.offset` (new, optional, in `modular-terms.ts`) shifts the model back and one expression places a prop the same in both. The sketch redraws as the models land and then aims the bench's camera at the real geometry (`ColourSketch.tsx`; timers, because the browser pane fires no animation frames).
- **Not everything with a model has a scene.** The Void's big packing crate is built in code: Godot cannot place it. The pilot uses the museum crate (`commons/artifacts/crate`, the spring tower's own `crate` bob, exported in `public/artifact-gltf/crate.glb`) at 1.3x.

## Inventory

**Have, in both pictures (checked in the pilot or by its plumbing):**

| piece | prefab | used for |
|---|---|---|
| beam, post, rail | `timber_plank_1m`, `_2m`, `_4m` | gantries (4 m lapped with 2 m), beams on edge |
| board, floor | `timber_panel_1x1`, `_2x1`, `_2x2` | the plotter board the record is taped to |
| feet | `pallet` | gantry feet |
| the record's stand | `workbench` | holds the board |
| light | `work_light` | staging |
| a mass | `crate` (museum) | the spring's mass |
| anything thrown | `trace_point_ball` | projectiles, pods, bobs (28 cm, black) |
| ground, court | `platform_block`, `melencolia_platform` | plinths, a court for a study |
| marks of risk | `warning_tape`, `traffic_cone` | the force pad's landing zone |
| a console | `interface_floor` | a readout stand |

**Needed, not in the kit yet (the lab draws them from primitives in the kit's materials for now):**

| piece | wanted by | what excellent means |
|---|---|---|
| **arrow** | spring tower, force pad, launch arc, centrifuge ring | painted steel, a head of fixed size at any length, a colour per force; one piece, not a stretched cone |
| **coil spring** | spring tower, shadow chain | steel wire, turns, radius and length as parameters, stretches without the wire thickening |
| **tape** | every record, the landing ring, rulers | a strip, a curve, a ring and a dot of masking, pink, blue, black or hazard tape, lying on a floor or a board |
| **hand wheel** | shadow chain, centrifuge ring, the wave machines | rim, hub, spokes and a crank pin; `sine_yoke` has one inside it, nowhere on its own |

**Good to have:**

- **The wave machines as prefabs.** `sine_yoke`, `belt_drive`, `torus_piston`, `pillar_barber_roll`, `single_cube_turntable` and `scale_zoetrope` are in the Void catalogue and on the wave floors, but their spawn entries are artifact placements without a scene, and none is exported to three.js. A second fallback (registry scene) plus a glTF export would let the waves studies stand next to them.
- **`two_point_ruler`** exported to three.js (its scene works in Godot).
- **A bearing or collar** for hubs and pivots (`trans_module_collar` exists only as construction-grid code).
- **A readout plaque** in the Point One grammar (cream panel, printed legend, raised readout) for a study's facts in the room.
- **A plotter board** assembled once: panel, tape axes, a clamp.

## The bar for "excellent"

1. The same in both pictures: same place, size and turn from one expression (the offset rule above).
2. Real size: a plank is 0.06 x 0.25 m, the ball 28 cm; nothing is scaled to fit a picture except a mass chosen to match an artifact's.
3. Reads from the bench's cameras (front, oblique, eye, plan) without being the thing that hides the physics.
4. Materials of one family: timber, steel, concrete, tape and paint.
5. No placeholders: a prefab that builds a labelled box in either picture is a missing prefab.

## Broken down into parts from primitives

*Same day, Palle: "can we break down these into subpart so we can create them from and in primitives?"* Each piece is a list of parts in the shape the handmade kits already use (`terms.json` `handmade.parts`: id, role, the primitive term it comes from, size, pose), so both builders can make it now and the workshop could take it apart later. The study `kit_pieces` (`/spatial-lab?family=colour&study=kit_pieces`) builds the four needed pieces from cylinders, cones, spheres, capsules and boxes, with an `explode` control that pulls the parts apart.

| piece | parts (role, from) |
|---|---|
| **arrow** | point of application (point, sphere) - shaft (line, cylinder, the length) - collar (cylinder) - head (cone, 18 x 22 cm at any length) |
| **coil spring** | top hook (line, 2 bends) - top ring (line x 12 round) - coil (line x turns x 12 on a helix) - bottom ring - bottom hook; it stretches by its pitch, the wire never thickens |
| **tape** | strip (tape, 5 cm) - curve (12 strips laid end to end, overlapping as real tape is) - ring (20 strips round) - mark (2 strips crossed) |
| **hand wheel** | hub on its axle (cylinder) - spokes (line x n) - rim (line x 36 round) - crank web (line) - crank pin, which drives (cylinder) - handle arm (line) - grip (cylinder) |

**The hand wheel is the machines' own.** Five of the six wave machines (sine yoke, belt drive, torus piston, cube turntable, zoetrope) are turned by `commons/artifacts/sine_yoke/hand_wheel.gd`. Its numbers at scale 1 are the piece's defaults: rim r .46 with a .025 tube, three spokes r .022, hub .055 on an axle from z -.16 to .11, an ivory crank web and pin at r .38, an ivory arm with a pink grip at r .48. The finish is the machines': steel `191d26`, ivory `f5f1e9`, pink `ec8fba`.

**The wave machines are already primitives.** Read in full (build functions cited in the session record), they are boxes, rods (cylinders between two points) and tori, in that finish plus chamfered timber. They share these sub-assemblies:

- **hand wheel** (above)
- **stand:** a foot box, a post box, a bearing block or boss
- **guide pair:** two rods with brackets (sine yoke), or rails (torus piston)
- **yoke:** two slot bars and two end blocks, the slot .079 for a .078 pin
- **belt:** a swept band. It could be two thin boxes and two arcs (160.2 and 199.8 degrees), 11.68 m round
- **carriage:** wrist pin, neck, cylinder, two banded tori
- **deck:** disk, rim torus, cubes on it
- **crank train:** shafts and a gearbox box
- **the playback console:** sliders, buttons and a readout from other scripts. This one is not primitives.

What is not primitives at all:

- the console sub-assembly
- Label3D text
- the barber roll's stripe texture (procedural: 3 bands, 3 helical turns over 4.8 m, which helical tape strips could approximate)
- the belt and the zoetrope shutter, which are swept or fan ArrayMeshes

Found on the way (not changed):

- the sine yoke's "DrivenTimberCube" is ivory, not timber
- the cube turntable's "TimberDisk" is steel
- `pillar_barber_roll` builds no pillar: the sleeve is an open tube
- in `scale_zoetrope`'s default closed shell, the 5 m disk and the cubes at r 2.22 pass through walls at +-2

**A trap paid for here:** a part's `rot` is *added* to the Euler angles of the `transform` it places (builder.gd `_place`: `rotation_degrees +=`, and the three.js builder matches), because a transform makes no node of its own. An upright turn [0, 0, 90] on a rolled plank [90, 0, 0] became [90, 0, 90] and laid the post along z, in both pictures alike. Two rotations compose only across two nodes: wrap the inner one in an assemblage (`kitPlank` does).

**Still open before the rims, cuffs and bands can be real tori:** the two builders disagree on a torus's axis (forum 261027-7ii2d). The lab draws rings as line x n round meanwhile.
