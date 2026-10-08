# Fire, then separate the effects

1. At FIRE COLOUR, press once and watch the target. Then inspect the nearby floor after the temporary cubes disappear.
2. Describe colour, visual shape and bodily support separately. The target and floor receive different operations.
3. Press again with the same aim. Read `mode_chromatic.gd`: the hue is random, while the flight glow changes without replacing the stored colour.
4. Trace the impact through `catalyst_projectile.gd` into the target callback and `chromatic_projectile.gd`. Locate the distance test, colour write and transform write.
5. Approach the altered grid. The render instance changes; its collision does not. A visual gap is not sufficient evidence of a traversable gap.
6. On the third hit, watch the target disappear and return. Compare its reset hit count with the grid's remaining edits.

The mounted bench chooses the aim so the comparison can focus on consequences. It does not teach manual aiming or wrist pickup. For Patterns, carry forward the cube and ask what a rule for repeated placement can add to a rule for changing appearance.
