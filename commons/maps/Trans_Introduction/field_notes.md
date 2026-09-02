# Trans_Introduction — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The arc, found

Palle's ruling (2026-09-02): transformation's red thread is that each move
*creates space in a different way*. The blurbs already said it, one clause per
map: translation produces space as extent, rotation produces space as
anisotropic, scale produces space as relation; the intro is three ways to close
a gap, the pit the same three from inside. The chapter follows Melencolia and
opens with "the primitives finally move".

## Exactness decisions

- **Shear keeps area.** The first draft said "shear it and almost nothing
  survives"; `probe_transformation_tutorials.gd` item 1 measured a shear keeping
  the triangle's area exactly. The text now says only the area holds.
- **The three lane cubes are utilities**, not interactables: `tc` transport
  cube ("carries players across voids"), `rc` rotation cube ("rotates to create
  walkable ramps"), `sc` scale cube ("scales to fill gaps with presence"), per
  `UtilityRegistry.gd`. Cyan/orange/green from the blurb.
- **scale_me does not rescale the world around you.** `scale_me.gd` finds a
  node named DarkSphere in the scene and tweens its scale ×100 over 5 s, and
  sets the player's position to y = 5 with x, z multiplied by 20; auto-revert
  after 20 s. The registry's "rescales the world around the player" is prose.
  The text says what happens. (Flag: the x,z ×20 on the player is a teleport
  far from the hall in the museum; worth a look.)
- **invariants_demo** is placed with `pose:rotate` (arrives showing the
  rotated face) and has TRANSLATE/ROTATE/SCALE/SHEAR/RESET/PROJECT buttons, so
  "put it through a move" is true.
- **head_crab** `#detection:14` reaches `detect_m` (head_crab.gd:395); it
  chases (chase_speed 0.95).
- **rotation_gimbal** locks within 5° of 90° on the middle ring
  (gimbal_lock_threshold).
- **balance_puzzle** piece_count 8.
- "Alice had a bottle for this": the bottle and the cake, not a pill.

## Probe

`commons/testing/probe_transformation_tutorials.gd` (PROBE OK): srt vs trs
land differently; a*b applies b first; t·invert(t) = identity; the invariants
table; a square returns under a quarter turn, not an eighth; Rx·Ry ≠ Ry·Rx;
rotation commutes with uniform scale and not with non-uniform; volume ×8.

## Open

- The `sp` utility ("score points", `score_cube.tscn`) has no script on disk
  under that name; whether it adds to the score or only shows it is unread.
