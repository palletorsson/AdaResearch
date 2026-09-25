# Same fall, another encounter

<!-- @softbody_gallery_part2 -->

The array contains several kinds of encounter. Start with the names: a slippery collider, a corner strike, high drag, a torus. They do not vary just one property. Choose one cell and compare it with a cell whose difference you can describe.

REPLAY restarts the group from its declared seed. The opening study removes the gallery's additional random changes to stiffness and pressure. VARIATION restores those changes. A fixed seed repeats a recipe for initial conditions; it does not promise bit-for-bit identical physics on every computer.

```gdscript
sb.linear_stiffness = 0.5
sb.damping_coefficient = 0.01
sb.pressure_coefficient = 0.0
```

The gallery applies each named cell's settings on top of these defaults. Optional variation then adds another layer. The final coefficients, the starting mesh and the obstruction all matter. A name like “Jelly” cannot substitute for that construction.

HOLD pins the current vertices. RELEASE restores the pins recorded before that hold. Neither action retrieves an untouched original body. GROUP opens another set of encounters; the study disables automatic respawning and ongoing deflation so that bodies do not multiply while you are trying to inspect one.

The most interesting result may be an awkward fold that a smooth rendering would conceal. Hold it and move around it. Ask which part is an effect of contact, which part comes from the triangulation, and which part depends on the solver's finite effort. Those are invitations to further experiments, not conclusions available from a single silhouette.

The array is useful because it holds differences near each other. It becomes misleading if proximity is mistaken for a controlled comparison. The next hall turns that problem toward time: when we keep a shape, what have we selected from the event?

<!-- @ -->
