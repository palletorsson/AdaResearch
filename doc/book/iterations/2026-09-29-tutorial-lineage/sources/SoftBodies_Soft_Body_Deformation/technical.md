# What holds a cube together? — implementation

Primary source scenes:

- `res://commons/artifacts/jelly_cube/jelly_cube.tscn`
- `res://algorithms/physicssimulation/softbodies/softmill/softmill.tscn`

The hall desk is implemented in `commons/artifacts/timing_machines/soft_workshop.gd`. It binds models inside this map, offers STIFFNESS, DAMPING, PRESSURE, RESET, MILL, RULE, and blocks repeated activation during rebuilds. The six controls fit a 3×2 desk with a small inclined transparent readout.

The cube gives way. A small arm holds one point at its top; the rest of its surface can move. Yet it does not become a collection of loose triangles. Something continues to hold its parts in relation. Before looking at the settings, choose what you expect a softer cube to do: change further, return more slowly, or fail to return at all?

Try STIFFNESS, then change DAMPING separately. The first changes resistance to deformation; the second damps motion. A body that moves less is not necessarily a body that resists deformation more. RESET restores the opening coefficients. It does not put every vertex back where it was before you arrived.

```gdscript
_soft_body.linear_stiffness = stiffness
_soft_body.damping_coefficient = damping
_soft_body.pressure_coefficient = pressure
```

These are parameters of Godot's soft-body solver. The program supplies a subdivided cube and lets its vertices respond under those rules. PRESSURE introduces another contribution. Watch what inflation can conceal: the same outer silhouette can be maintained by different balances of resistance and internal pressure.

We have already changed whole objects by translation, rotation and scale. Here, their constituent positions change relative to one another. The surface connectivity remains prescribed. Yielding is a new capability; tearing, growing a hole or exchanging a neighbour would require more code. A soft appearance does not announce every freedom a body possesses.

Turn toward the mill. The moving apparatus brings a repeated encounter to a soft sphere. Use MILL to hold the drive. The sphere's physics continues; stopping a mechanism is different from stopping everything it has set in motion.

The cube made its coefficients available on a desk. The mill makes the source of an encounter visible in the room. Follow the motion from the machinery to the surface, then consider the room around both: the collider, support and pinned points belong to this body's conditions as much as its stiffness does.

The nearby jelly variants remain useful comparisons, and radiolaria offers a different warning: intricate biological resemblance can be constructed without soft-body dynamics. Keep that distinction for later. First we need to see how a surface changes when some of its points are required to stay.

The placed cube sets simulation precision to 5. This count does not apply to every artifact in the sequence: rounded_softbody, for example, uses 10. The engine is GodotPhysics3D. Its links include triangle edges and bending constraints between points two edges apart; the surface is not a volumetric lattice, but saying it has only edge links is inaccurate. Stiffness is not simply a fraction of each distance error corrected per pass.

Both collision hands in commons/scenes/base.tscn select mode 1, TELEPORT. In addons/godot-xr-tools/hands/collision_hand.gd that mode copies the target transform directly; COLLIDE is another available mode. This is source evidence for the manuscript's hand asymmetry, not a completed headset contact test.

The opening hall opts into `jelly_cube:180:1.0#anchor:crown`. One vertex nearest the centre of the top face is pinned. A small brass stem and open stand expose that attachment; there is no plate underneath the deforming surface. The local control rack is lowered and brought forward to keep it clear of the body. The default `anchor:free` retains the original pedestal and unpinned body in other placements. Anchor is a placement setting, read before construction, not a new live control. Changing the existing coefficients does not rebuild the body or release the pin.

The unpinned cube left its original support during a native control sequence. Several tray trials also failed to retain it; those diagnostics are preserved in the opening review. The crown attachment establishes an explicit boundary condition for this lesson. It does not certify free soft-body contact with a tray or solve that separate collision problem.

Floor provenance: earlier structure cells remain behind the front court. Raw zeros receive explicit covers after relocation; this does not redefine zero globally. See `doc/space/soft-sequence-2026-09-15/floor-audit.json`. Headset reach and comfort require a human pass; runtime receipts separately record tested desktop operations.
