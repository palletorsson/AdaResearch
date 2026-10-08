DRAFT 2026-10-01. Unreviewed; this hall is in no sequence, plan, trunk or book.

# Intent

A body here is a seed and an ordered list of rules. The hall lays one seed out fourteen times so that the list can be read by walking: what one more rule adds, what the same rules do in another order, what the same push does at another resolution, and what the same operation does under another selector.

It is the project's own grammar (`commons/mesh_grammar/`) put on the floor: a rule is a selector, an operation and its parameters, and the rules are applied in order, once per generation. Every station is a file of a few lines in `grammar/` beside the map, read by `mesh_grammar_artifact`. Change a line in a file and the body on that plinth changes.

Ask what the list permits and what it cannot say. Ground the question in an operation you can see and in the code that performs it. Do not infer growth, intention or nature from a branching outline.

## The encounter, in order

The hall is 15 cells wide and 42 deep. The visitor walks south down a three-cell aisle. Rows of the strip are read like lines on a page, from the visitor's left (column 10) to their right (column 4).

1. **Entry, row 1.** Spawn inside the north door. Five plinths stand across the hall on row 4.
2. **The seeds, row 4.** `mesh_grammar` at five seed types: icosahedron, cube, sphere, disk, flower disk, named above. No rule has been applied to any of them. They show that the seed is a choice, and that it already fixes how many faces a rule will find (12, 20, 24, 216, 352).
3. **The bench, (7,8).** `mesh_grammar_bench`: a box that has grown boxes, labelled MESH GRAMMAR. It states the claim of the hall as a picture: apply a rule, apply it again. It is not operable, and it is rebuilt from an unseeded generator at each visit.
4. **The strip, rows 11 to 29.** Fourteen stations, the same icosahedron (radius 0.4 m) on each plinth, numbered above.
   - 01 SEED and 02 SPLIT: the list is empty; then one rule that changes the count (20 to 80 faces) and not the shape.
   - 03 EXTRUDE and 04 INSET: one operation that changes the outline and one that changes only the surface, leaving a tag for later rules.
   - 05 INSET THEN EXTRUDE and 06 EXTRUDE THEN INSET: the same two rules with the same numbers, in both orders. In 05 six blocks rise. In 06 the extrude asks for a tag that does not exist yet, selects nothing, and the body stays flat.
   - 07 DISPLACE and 08 SPLIT THEN DISPLACE: the same noise field with the same seed pushing 12 vertices, then 162. The application's trade-off between polycount and smooth deformation, on two plinths.
   - 09 EXTRUDE THEN DELETE and 10 BRANCH: a rule that removes what the previous rule made; a rule that replaces a face with a tube.
   - 11 BRANCH THE TIPS and 12 AGAIN: rules acting on the output of rules. In 11 through a tag inside one generation; in 12 by running the list of 05 for a second generation.
   - 13 EVERY FACE and 14 UPWARD FACES: one operation under two selectors. Eighty faces act, then twenty-four.
5. **The room, rows 31 to 37.** `mesh_grammar_room`: a tower grown by a recursive box rule, on a seven-metre floor, with no collider. The visitor walks into and through it. It is the place for the closing question: what none of the fourteen lists can grow.
6. **Exit, (7,40).** The line WHO WROTE THE RULE? hangs before the teleporter.

## Where each claim comes from

The fourteen face and vertex counts in the essay were read back from the built hall on 2026-10-01, not computed by hand. Parameters for 03, 04 and 11 are those of the Extruded Spire, Inset Pattern and Branching Coral in `mesh_grammar_demo.gd`; 05 uses the Inset Towers order on the icosahedron instead of the cube.

Selectors are `up`, `all` or a tag in every station, so the same faces act at every build. Two things still vary between builds: the bend of the tubes in 10 and 11 (`curve_amount` draws from an unseeded generator), and the whole of the bench and the room.

## Deliberately left out

- **The twenty registry presets** (`mesh_grammar_extruded_spire`, `mesh_grammar_inset_towers`, `mesh_grammar_ca_growth` and the rest). Placed in a map, each of them builds the bare icosahedron: they point at `mesh_grammar_node.tscn`, which holds no rule list, and their recipes exist only inside the gallery scene `mesh_grammar_demo.gd`. A strip of them would be twelve identical bodies under twelve different names.
- **The cellular automaton on faces** (CA Growth) and the **L-system branch**. `mesh_grammar_artifact` has neither operation. The last row uses the grammar's own selectors to show that a rule decides which faces act.
- **Bulge, petals, scales, rivets, barnacles, spikes.** Decoration operations add nothing to the argument about order, resolution and selection.
- **The gallery scene itself** (`facade_grammar_demo`). It carries its own floor, two directional lights, an environment and a camera, and washes out a hall it is placed in.
- **`form_grammar_family`.** It is the shape-grammar hall's work and stays there.
- **Anything to operate.** Nothing in the hall can be pressed. The grammar keeps a copy of every generation, but no placeable artifact lets a visitor step through them, so the steps stand side by side.
- **A custom seed.** The sixth declared seed type needs a mesh handed over in code.

## Known gaps in this draft

- The declared axis is `seed_type`; the artifact reads the key `seed`. The tokens carry both. With `#seed_type:cube` alone the body stays an icosahedron.
- The `museum` block is copied from the sibling halls. The hall has been derived through `em_map_halls.derive_row` and `normalize_row` in memory only; it has not been built in the museum.
- Not walked in a headset. The captures are from the desktop map catalog.
