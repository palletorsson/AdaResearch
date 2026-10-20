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

The mill's sphere runs `algorithms/physicssimulation/softbody3d/softbody3d.gd`, whose `_setup_physics()` explicitly sets collision layer 1 and mask 1. The rotating arm sets layer 2 and mask 0. Neither mask admits the other's layer. The hall desk does not change these filters, so the current setup cannot support the claim that the arm repeatedly strikes the sphere.

MILL disables the apparatus's scripted drive while leaving the SoftBody3D and its script active. The sphere retains its own pressure cycle and simulation; continued motion is not evidence of an earlier strike by the arm. This correction follows the placed scene and scripts, not a new runtime contact test.

The nearby jelly variants remain useful comparisons, and radiolaria offers a different warning: intricate biological resemblance can be constructed without soft-body dynamics. Keep that distinction for later. First we need to see how a surface changes when some of its points are required to stay.

The placed cube sets simulation precision to 5. This count does not apply to every artifact in the sequence: rounded_softbody, for example, uses 10. The current project selects Jolt Physics in `project.godot`. Earlier notes described GodotPhysics3D and its constraint construction; they must not be used as a description of the current solver. Stiffness is a solver parameter, not a portable fraction of distance error corrected per pass.

Both collision hands in commons/scenes/base.tscn select mode 1, TELEPORT. In addons/godot-xr-tools/hands/collision_hand.gd that mode copies the target transform directly; COLLIDE is another available mode. This is source evidence for the manuscript's hand asymmetry, not a completed headset contact test.

The opening hall opts into `jelly_cube:180:1.0#anchor:crown`. One vertex nearest the centre of the top face is pinned. A small brass stem and open stand expose that attachment; there is no plate underneath the deforming surface. The local control rack is lowered and brought forward to keep it clear of the body. The default `anchor:free` retains the original pedestal and unpinned body in other placements. Anchor is a placement setting, read before construction, not a new live control. Changing the existing coefficients does not rebuild the body or release the pin.

The unpinned cube left its original support during a native control sequence. Several tray trials also failed to retain it; those diagnostics are preserved in the opening review. The crown attachment establishes an explicit boundary condition for this lesson. It does not certify free soft-body contact with a tray or solve that separate collision problem.

Floor provenance: earlier structure cells remain behind the front court. Raw zeros receive explicit covers after relocation; this does not redefine zero globally. See `doc/space/soft-sequence-2026-09-15/floor-audit.json`. Headset reach and comfort require a human pass; runtime receipts separately record tested desktop operations.

## Runnable reconstruction · 9 October 2026

`tutorial.md` prints the complete `yielding_cube.gd` and host plus the unchanged carried `point_body.gd`. The student supplies the subdivided mesh in `_init()`, before adding the SoftBody3D to the scene tree; creating it only in `_ready()` failed to create an active Jolt soft body in the native test. The selected crown index comes from the undeformed mesh. The host adds the point collider to the soft-body mask (value 4, layer 3). This is a deliberate learner extension; the installed cube keeps its original mask.

The code test extracts these printed files, checks their bytes against the study, and runs the entire host. It tests the pinned world position under a transformed parent, native deformation, reset preserving state, supplied XRTools pickup/action/release, the subdivision edit, and point contact against a disabled-contact control. Removing the pin is a negative control. See `tools/test_soft_yield.py` and the dated review receipt for results and scope.

The October 9 native pass traced the blocked authored arrival to the desk's colliders. Only the desk moves, from map cell (15,3) to (11,5), mirrored in the runtime museum plan. The revised standing approach and 273 sampled route positions have support and capsule clearance; six pointer actions still work. The mill's surface stretches into spikes under the current native run and needs a separate stability review. This does not invalidate the bounded learner cube but limits claims about the entire room.
