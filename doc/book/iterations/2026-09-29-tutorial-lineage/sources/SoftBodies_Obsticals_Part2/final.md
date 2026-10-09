# Same fall, another encounter

<!-- @softbody_gallery_part2 -->

The array contains twelve encounters. Start with the names: Bouncy Collider, Slippery Collider, Torus, Prism, Corner Strike, High Drag, Vacuum, Tiny Sphere, Giant Sphere, Super Soft, Caving Sphere, Collapsed Box. They do not vary just one property. Choose one cell and compare it with a cell whose difference you can describe.

REPLAY restarts the group from its declared seed. The opening study removes the gallery's additional random changes to stiffness and pressure. VARIATION restores those changes. A fixed seed repeats a recipe for initial conditions; it does not promise bit-for-bit identical physics on every computer.

```gdscript
sb.linear_stiffness = 0.5
sb.damping_coefficient = 0.01
sb.pressure_coefficient = 0.0
```

The gallery applies each named cell's settings on top of these defaults. Optional variation then adds another layer. The final coefficients, the starting mesh and the obstruction all matter. A name like “Super Soft” cannot substitute for that construction.

Read the cells against those three lines. High Drag changes one number, damping to 0.8, and nothing else: it is the one controlled comparison in the array. Vacuum sets pressure to nought, which is where every cell already starts, so its name promises a difference its numbers do not contain. Caving Sphere is the only body in the sequence that asks the solver for seven passes instead of five, and the only one whose pressure is negative, so it is drawn inward as it falls. Super Soft and Collapsed Box are both boxes without pressure, but one is half as stiff as the other and lands on a sphere where the other lands on a cube: two differences at once, and the array cannot tell you which one you are watching. Bouncy and Slippery change the collider rather than the body, one perfectly elastic and one without friction, and change its shape at the same time.

HOLD pins the current vertices. RELEASE restores the pins recorded before that hold. Neither action retrieves an untouched original body. GROUP opens another set of encounters; the study disables automatic respawning and ongoing deflation so that bodies do not multiply while you are trying to inspect one.

The most interesting result may be an awkward fold that a smooth rendering would conceal. Hold it and move around it. Ask which part is an effect of contact, which part comes from the triangulation, and which part depends on the solver's finite effort.[^effort] Those are invitations to further experiments, not conclusions available from a single silhouette.

The array is useful because it holds differences near each other. It becomes misleading if proximity is mistaken for a controlled comparison. The next hall turns that problem toward time: when we keep a shape, what have we selected from the event?

<!-- @ -->

[^effort]: Five passes over every spring, every physics tick, for every body in this sequence but one; the Caving Sphere asks for seven. The bench in Form Finding put that count on a dial and read the error it leaves: at one pass the worst spring in a cloth was a third off its length; at four, a tenth.
