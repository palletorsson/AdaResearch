Concept: The cube transformation primer. Before the chapter uses translation, rotation and scale to cross holes, each is shown as the plain difference between a cube and its copy: the same yellow block here and somewhere else, here and turned, here and larger, and then all three at once. Adding one difference at a time is the whole lesson.
Sequence role: Opens the Transformation sequence, ahead of Trans_Introduction. Palle, 2026-09-05: "Some time ago I also explained translation and scale with the mario cube. By adding the difference: first the cube, then translation, then rotation, then scale. Something like Transformation_1 but improved, all stages." Transformation_1 was the 2025 repo's "Cube Transformation Primer" (a cube, a transformation cube, a rotating cube, a pick-up cube and the axioms card on one row); this room does the same with one object and every stage.
Technical angle: The copies are one artifact placed with the map token's own fields - mario_cube (the cube), mario_cube at another cell (translation), mario_cube:45 (rotation about the upright), mario_cube:0:0:1.5 (uniform scale), mario_cube:45:1:1.5 (rotation, a translation along y, and scale in one token). The grid applies them as one Transform3D, which is what the axioms card names as the matrix.
Critical angle: A transformation is a difference, not a motion. Nothing in this room moves; the difference is laid out in space between two copies, and the visitor walks the difference. The rainbow that stands up over a block when it is reached is the Mario cube's own essence, darkness becoming colour, and here every stage earns one.
Key artifacts: mario_cube, nine of them, the unit and its copies; clipboard with transformation_axioms, the matrix said in words.

Gap: No gap identified.

## Rebuilt across levels, 2026-09-06

Palle, pointing at the 2025 map `AdaResearch26/commons/maps/Trans_Translation`
("Transformation_2 - Translation Route Field", an asymmetric multi-level
platform network): *"for trans_pre I mean something like this."*

The room was a flat 9x14 corridor with the five stages on one floor. It is now
11x21 on three levels - deck, a shelf a metre up, a summit two metres up - with
an inner wall at 3 closing the first stage off, a wedge east onto the plinth
that carries stage two's copy, wedges up to the summit and back down to the
door. Height is not decoration here: stage two's difference is a vector with a
metre of y in it and the ramp is the part of it you walk, and the rotation and
scale pairs stay strictly level because their difference must be the only one.
`museum.wall_height` is 4, so 2 and 3 are floors a metre and two metres up in
both engines, and 4 is the wall.
