# What holds a cube together?

<!-- @jelly_cube -->

The cube gives way. A small arm holds one point at its top; the rest of its surface can move. Yet it does not become a collection of loose triangles. Something continues to hold its parts in relation. Before looking at the settings, choose what you expect a softer cube to do: change further, return more slowly, or fail to return at all?

Try STIFFNESS, then change DAMPING separately. The first changes resistance to deformation; the second damps motion. A body that moves less is not necessarily a body that resists deformation more. RESET restores the opening coefficients. It does not put every vertex back where it was before you arrived.

Reach toward it. The cube can deform against your hand, but it cannot push the tracked hand out of position. In this room's VR rig, the virtual hand follows the controller directly.[^hand] One body must accommodate the meeting; the other has already been placed.

```gdscript
_soft_body.linear_stiffness = stiffness
_soft_body.damping_coefficient = damping
_soft_body.pressure_coefficient = pressure
```

These are parameters of Godot's soft-body solver. The program supplies a subdivided cube and lets its vertices respond under those rules. PRESSURE introduces another contribution. Watch what inflation can conceal: the same outer silhouette can be maintained by different balances of resistance and internal pressure.

There is no modeled flesh behind the green skin. The body is built from a closed surface whose points are linked to keep distances; pressure helps that surface hold a volume. Turn PRESSURE down to zero and wait. What can the linked surface keep when inflation no longer helps it?

The engine has a limited number of attempts to keep those distances at each step. The bench in Form Finding let us change that count; here the cube gets five passes.[^stiffness] What looks like a quality of the material also depends on how much work the simulation is allowed to do.

The last sequence made bodies by selecting, branching, carving, sampling and copying; before that we changed whole objects by translation, rotation and scale. Here, their constituent positions change relative to one another. The surface connectivity remains prescribed. Yielding is a new capability; tearing, growing a hole or exchanging a neighbour would require more code. A soft appearance does not announce every freedom a body possesses.

<!-- @ -->

<!-- @softmill -->

Turn toward the mill. The moving apparatus brings a repeated encounter to a soft sphere. Use MILL to hold the drive. The sphere's physics continues; stopping a mechanism is different from stopping everything it has set in motion.

The cube made its coefficients available on a desk. The mill makes the source of an encounter visible in the room. Follow the motion from the machinery to the surface, then consider the room around both: the collider, support and pinned points belong to this body's conditions as much as its stiffness does.

The nearby jelly variants remain useful comparisons, and radiolaria offers a different warning: intricate biological resemblance can be constructed without soft-body dynamics. Keep that distinction for later. Here we changed the response of a body while one point remained held. In the next room we change which points must stay.

<!-- @ -->

[^stiffness]: This cube sets Godot's `simulation_precision` to 5 and exposes `linear_stiffness` from 0 to 1. The count is local to this artifact. Godot Physics links triangle edges and also adds bending constraints between points two edges apart. See the [SoftBody3D reference](https://docs.godotengine.org/en/4.6/classes/class_softbody3d.html) and [Godot 4.6 solver source](https://github.com/godotengine/godot/blob/4.6-stable/modules/godot_physics_3d/godot_soft_body_3d.cpp).

[^hand]: The museum's base rig selects TELEPORT mode for both collision hands: their transforms follow the tracked controllers. The same hand component also supports a collision-following mode. This asymmetry is a choice made in this rig, not a necessary property of every virtual hand.
