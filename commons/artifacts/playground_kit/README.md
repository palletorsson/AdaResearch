# The playground kit — the ball and the rod

Palle, 2026-10-29: *the 6 point attachment ball and the two point rod that can be put between them. The rod
can also be used as a hitting stick.* Built from the scaffold standard (steel rods, foam sleeves, a one-metre
unit) and the Lekland hub: the ball is the POINT of the inventory, the rod the LINE (`commons/data/inventory/
items.json`; `commons/player/INVENTORY.md`).

- **`playground_ball`** (`playground_ball.gd`): a foam hub, radius 0.06, with a steel socket boss on each of
  its six faces (+X −X +Y −Y +Z −Z). **It lives on the grid** (Palle: "the ball must be placed in a 1 m snap
  grid"): let go, it snaps to the nearest grid point — x and z at multiples of `grid`, y at a multiple plus the
  hub's half-height (radius + boss = 0.085) so row 0 stands on the floor — squared to the grid and frozen
  there, a node of the scaffold; picked up again it is a body until the next point. Config: `radius`, `boss`,
  `colour` (pale · pink · cyan · steel — construction-materials.json's foam before and after Colour),
  `socket_reach` (0.12 m), `grid` (1 m), `snap`. API: `socket_global(i)`, `socket_dir(i)`,
  `nearest_free_socket(p)`, `claim`, `release`, `grid_point(p)`, `settle()`. Group `playground_balls`.
- **`playground_rod`** (`playground_rod.gd`): a steel core (r 0.012) in a foam sleeve (r 0.03), bare for 8 cm
  at each end, along its +X. **Its length is in grid units**: one unit reaches from a grid ball's mouth to the
  next ball's, `units × grid − 2 × hub` = 0.83 m on the 1 m grid; `units` 0 keeps `length` as given. A rod
  holds only where a grid ball holds it; let go anywhere else, it falls. Config: `units`, `grid`, `hub`,
  `length`, `core`, `sleeve`, `colour`, `hit_speed`.
  - **Snap.** Let go (XR Tools `dropped` → `settle()`): each end looks for the nearest free socket within the
    ball's reach. One found: the rod turns to point out of that socket, its end in the mouth — and then the
    far end looks again, so a second ball a rod's length away (centre to centre: length + 2·(radius + boss))
    is taken too. Two found: the rod lies between the mouths. Each snap is a `Generic6DOFJoint3D` with every
    axis locked (a fixed joint) at the mouth, and the socket is claimed; the balls and rods are then one rigid
    thing to lift. `picked_up` → `unsnap()`: joints freed, sockets released.
  - **The stick.** `contact_monitor` on; a body met faster than `hit_speed` (1.2 m/s) is a `hit(what, speed)`
    with the foam thwop: an `AudioStreamWAV` made in code (140 ms of noise under a falling low-pass with a soft
    thump beneath, pitch and volume by speed). **`body_entered` arrives after the solver has spent the
    velocity**, so the rod remembers its speed from before the step (`_physics_process`) and reports the larger.

## The support graph

Palle: *balls need support too — build the support graph.* Nothing in the code knows a tower or a bridge;
a thing stands because of this walk, run by `PlaygroundBall.reevaluate(tree)` whenever a ball or rod is
placed, picked up or removed:

1. A ball is **grounded** when it was let go onto row 0 of the grid (its hub on the floor) and is not held.
2. From every grounded ball, out through its socketed rods to the balls at their other ends: those are
   **supported**, and on through theirs.
3. Supported balls hold frozen on their grid points. A ball on the grid that nothing supports becomes a
   body and falls — and so does whatever is jointed to it, since the joints are real. A ball let go in the
   air with nothing under it snaps to its row and drops at once.
4. A held ball supports nothing: lift the ground ball of a tower and the tower hangs from your hand; let it
   go off the grid and it all comes down.
5. The snap works from both sides: a rod let go takes a ball's mouth; a ball let go takes any loose rod
   end lying in one of its mouths (within 3 cm), so a tower can be built rod first, ball on top.

Taking a ball out of the world (`tree_exiting`) makes its rods let go of it (`release_ball`) and walks the
graph again without it: the collapse.

**Probe:** `godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_playground_kit.tscn`
— seven checks with numbers (rest height, snap axis and end-to-mouth distance, the bridge, the chain lifting
5 cm through the rod, unsnap, the hit at 6 m/s and the thwop's 3,087 samples, the inventory making a ball and a
2 m rod from its knob). `ada_run/playground_kit/{kit.png, report.json}`.

Not yet: the web prism draws the ball and rod but does not snap them; a rod held in VR hitting a ball with a
sleeve-on-sleeve thud (one sound for everything now); sockets at other than six faces; the triangle.
