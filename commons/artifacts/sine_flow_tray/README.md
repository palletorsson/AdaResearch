# Sine contact tray

First book encounter in `WaveFunctions_Sine_Space`, followed by the existing sine wall corridor. Placed at map cell (3,4), rotated 180 degrees, in a new six-row forecourt. The side console faces the central approach; transparent side guards and a tilted display keep the surface readable. Dimensions are metres; place at unit scale with its root on the floor.

RELEASE replaces the batch with 32 spheres. RELIEF cycles 0.12/0.30/0.55 m; SIZE cycles sphere radius 45/75/105 mm. Each parameter change clears the batch. RESET restores 0.30 m relief and 75 mm radius. RULE toggles the construction explanation. The tray is stationary, tilted 20 degrees. Spheres have mass 0.1 kg, zero initial velocities, explicit linear/angular damping 0.05, friction 0.45 and zero bounce. Their common local release grid is four columns by eight rows at height 1.1 m.

`sin(TAU*.9*x)*sin(TAU*.9*z)` fills 21x33 samples, min/max normalised to the selected height range. The same triangulated mesh supplies the visible surface and its collision shape. Transparent side guards retain their collision. At 12 seconds (720 declared ticks at 60 Hz), unresolved bodies freeze. A sphere fully beyond the downstream edge is counted as outlet; side/back/below exits are separate and checked first. Departed bodies become a noncolliding collection display. Still-in counts do not establish permanent trapping, shelter or entropy.

The code is adapted from `landscape_flow_bench` without modifying the article's recorded source. This is a separate one-tray museum arrangement; do not merge its outcomes into the article's predeclared series. Museum collision context and numerical contact histories may differ. The new control set deliberately fixes tilt, seed-independent sine geometry and observation duration.

Run `res://commons/testing/probe_sine_flow_hall.tscn` under project startup for the museum probe. It uses synthetic input through the project's real desktop interaction rig. The museum's own walker and tracked-hand controls are distinct lanes; headset verification remains pending. Evidence: `ada_run/sine-flow-hall/report.json` and `doc/research/possible-bodies/sine-contact.html`.
