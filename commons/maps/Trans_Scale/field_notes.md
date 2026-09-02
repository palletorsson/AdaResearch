# Trans_Scale — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The pill

Palle: "the Alice scale me pill". `scale_me.gd` measured: on pickup it finds a
node named DarkSphere in the current scene (or the given world node, or its
parent) and tweens its scale ×100 over `scale_up_time` 5 s; it sets the
player's position to y = 5 with x and z multiplied by scale_amount/5 = 20;
after `scale_duration` 20 s it reverts over 5 s (auto_revert). The registry's
"rescales the world around the player" and the first draft's "the world
rescales around you" are not what the code does. The text now says the dark
sphere grows a hundred times and you are lifted five metres and carried
outward. **Flag:** x,z × 20 on the player's world position is a teleport far
outside a museum hall; in the grid map it is far outside the map. Worth fixing
before anyone takes the sphere in VR.

## Exactness decisions

- **Seven prisms, three cubes** (first draft said eight): prism_block at r8 c5,
  r11 c1, r11 c2, r12 c4, r13 c3, c4, c5; cube_scene at r10 c5, r11 c3, c4.
- **science_screen `#mode:bars` is not a mode**; falls back to the plain
  projection. The text describes that. Token should be corrected.
- **chair_assembly_puzzle**: model_scale 0.3 → final_scale 1.0, grow 1.5 s,
  grow_on_complete true.
- **clipboard** placed with `vr_scale_controls` config; "the scale controls on
  it" from the token.
- Volume ×8 at factor 2: probe item 7.
