# What holds a cube together?

<!-- @jelly_cube -->

The cube gives way. Yet it does not become a collection of loose triangles. Something continues to hold its parts in relation. Before looking at the settings, choose what you expect a softer cube to do: change further, return more slowly, or fail to return at all?

Try STIFFNESS, then change DAMPING separately. The first changes resistance to deformation; the second damps motion. STIFFNESS is a number between nought and one: how much of each spring's disagreement the solver corrects each time it looks. It is not a property of a material. It is an instruction to a procedure that looks five times a tick, and the bench in Form Finding showed you that the count alone can stiffen a cloth. A soft body in this engine is a set of distances being corrected, never solved.[^stiffness] A body that moves less is not necessarily a body that resists deformation more. RESET restores the opening coefficients. It does not put every vertex back where it was before you arrived.

Your hand is the one body in this room the solver cannot argue with. Its position is written every frame from the tracking, and the cube meets it as a collider that never yields; the rounded body two halls on will meet it as a push within a hand's reach instead, and neither will ever move the hand. An engine that is handed a position instead of a force has to treat it as law, and every soft thing here is arranged around that law.

```gdscript
_soft_body.linear_stiffness = stiffness
_soft_body.damping_coefficient = damping
_soft_body.pressure_coefficient = pressure
```

These are parameters of Godot's soft-body solver. The program supplies a subdivided cube and lets its vertices respond under those rules. PRESSURE introduces another contribution. Watch what inflation can conceal: the same outer silhouette can be maintained by different balances of resistance and internal pressure.

What holds the cube together is the skin. Every edge of its surface is a spring asked to keep its length, and there is nothing across the inside. Take PRESSURE to nothing and the cube shows you: a bag of triangles with no interior drapes over its pedestal like cloth. Pressure is what this engine offers in place of the internal struts a soft body would otherwise need.

The last sequence made bodies by selecting, branching, carving, sampling and copying; before that we changed whole objects by translation, rotation and scale. Here, their constituent positions change relative to one another. The surface connectivity remains prescribed. Yielding is a new capability; tearing, growing a hole or exchanging a neighbour would require more code. A soft appearance does not announce every freedom a body possesses.

<!-- @ -->

<!-- @softmill -->

Turn toward the mill. The moving apparatus brings a repeated encounter to a soft sphere. Use MILL to hold the drive. The sphere's physics continues; stopping a mechanism is different from stopping everything it has set in motion.

The cube made its coefficients available on a desk. The mill makes the source of an encounter visible in the room. Follow the motion from the machinery to the surface, then consider the room around both: the collider, support and pinned points belong to this body's conditions as much as its stiffness does.

The nearby jelly variants remain useful comparisons, and radiolaria offers a different warning: intricate biological resemblance can be constructed without soft-body dynamics. Keep that distinction for later. First we need to see how a surface changes when some of its points are required to stay.

<!-- @ -->

[^stiffness]: Godot's SoftBody3D: `linear_stiffness` runs from 0 to 1, and `simulation_precision`, the passes the solver makes over its distances each physics tick, is 5 for every soft body in this sequence. The room did not write the solver; it hands it distances and a budget.
