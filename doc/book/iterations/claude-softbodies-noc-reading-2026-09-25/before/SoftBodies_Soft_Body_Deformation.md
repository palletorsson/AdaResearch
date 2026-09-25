# What holds a cube together?

<!-- @jelly_cube -->

The cube gives way. Yet it does not become a collection of loose triangles. Something continues to hold its parts in relation. Before looking at the settings, choose what you expect a softer cube to do: change further, return more slowly, or fail to return at all?

Try STIFFNESS, then change DAMPING separately. The first changes resistance to deformation; the second damps motion. A body that moves less is not necessarily a body that resists deformation more. RESET restores the opening coefficients. It does not put every vertex back where it was before you arrived.

```gdscript
_soft_body.linear_stiffness = stiffness
_soft_body.damping_coefficient = damping
_soft_body.pressure_coefficient = pressure
```

These are parameters of Godot's soft-body solver. The program supplies a subdivided cube and lets its vertices respond under those rules. PRESSURE introduces another contribution. Watch what inflation can conceal: the same outer silhouette can be maintained by different balances of resistance and internal pressure.

We have already changed whole objects by translation, rotation and scale. Here, their constituent positions change relative to one another. The surface connectivity remains prescribed. Yielding is a new capability; tearing, growing a hole or exchanging a neighbour would require more code. A soft appearance does not announce every freedom a body possesses.

<!-- @ -->

<!-- @softmill -->

Turn toward the mill. The moving apparatus brings a repeated encounter to a soft sphere. Use MILL to hold the drive. The sphere's physics continues; stopping a mechanism is different from stopping everything it has set in motion.

The cube made its coefficients available on a desk. The mill makes the source of an encounter visible in the room. Follow the motion from the machinery to the surface, then consider the room around both: the collider, support and pinned points belong to this body's conditions as much as its stiffness does.

The nearby jelly variants remain useful comparisons, and radiolaria offers a different warning: intricate biological resemblance can be constructed without soft-body dynamics. Keep that distinction for later. First we need to see how a surface changes when some of its points are required to stay.

<!-- @ -->
