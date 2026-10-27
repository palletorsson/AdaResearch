# Gravity matter logic

Three material logic lessons on Logic floors21–22, with their earlier sketches
retained beneath the raised crossings of floor14, `Trans_Introduction`.
The Cube-floor AND and wheel studies are separate.

These reuse construction timber, concrete building cubes and the original
white gravity-ball mesh. Working dimensions are twice the Cube-floor AND:
24 cm cubes and 6.72 cm balls, with 3.6 × 1.7 m platforms. The top remains
84 cm high so the input cubes and pink release grip are reachable.

The working row is brought toward the player-facing board edge:50 cm for AND
and NOT,24 cm for OR to retain its wider lane/target support. The title and
instructions share the rear binary-results board; no information plate stands
between the player and the mechanism. Controls and Readout remain separately
editable label/board groups at the same rear anchor.

Touch the actual X/Y cubes to alternate their starting state. Lift the pink
stop by hand, or drag it upward with the desktop/XR pointer, to release the
balls. There are no push buttons in the default object-controls mode. After
all test balls rest for ten continuous seconds, the take resets: inputs rise,
the target returns and the original white balls are replaced. Renewed motion,
a held ball or a held/dragged release grip restarts the rest timer. Observed
truth-table evidence remains. `reset_after_rest` configures the wait (zero
disables automatic reset). Input cubes fall into guided slots;
a Jolt SliderJoint3D constrains each falling input and supplies its lower stop.
The inputs stay dynamic after release; no script snaps them into their seats.
The original wooden wedge and plank make a 30 cm rise over a one-metre entry
ramp. A real stop holds the balls on the incline; lifting it lets gravity
supply their motion. Neither their velocity nor their route is assigned
from a truth-table value. The earlier contact-spring launcher is retained
in spring_launcher.gd as a sketch, not used by these rooms.

- AND has two missing supports in series. Both input cubes complete the run.
- OR releases two balls along independent parallel lanes. Either arrival
  hits the common end target.
- NOT has a continuous run and one lowered blocker. A real blocker impact
  records zero; the end target records one. The target is a lightweight Jolt
  rigid paddle on a motor-free upper hinge, so contact makes it swing.

Actual impacts and falls are recorded separately from expected results. A
stalled or hand-taken ball is inconclusive; it is not recorded as false. Observing the
whole correct table earns the corresponding assembly in the shared prefab
inventory, only from its designated main-tower occurrence. The catalogue,
workbench and live editor read the same definition.

The support, track sections, guided inputs, gravity ramp/release, impact target,
controls and readout are independently editable groups. Removing essential
parts makes a construction fragment rather than awarding progress. Editor
exports show the actual static construction pose, not a simulation of the
runtime physics. Move complete assemblies at unit scale for reliable physical
dimensions; the larger working size is baked into the geometry.
