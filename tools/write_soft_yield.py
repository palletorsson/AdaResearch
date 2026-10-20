"""One opening lesson; full code follows the existing pinned museum cube."""
from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parents[1]
M=R/'commons/maps/SoftBodies_Soft_Body_Deformation'
S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Soft_Body_Deformation'
O=R/'doc/book/iterations/2026-10-09-soft-a-point-that-stays'
before=json.loads((O/'before/hashes.json').read_text())
for name in ['tutorial.md','final.md']:
    assert hashlib.sha256((M/name).read_bytes()).hexdigest()==before[(M/name).relative_to(R).as_posix()]
def block(name):return '\n<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
t='''# Soft Body Deformation — one point stays

## Learning elements

- Give a subdivided cube to `SoftBody3D`
- Select and pin a vertex from its reference coordinates
- Distinguish stiffness, damping and pressure
- Use the carried point to press a deforming surface
- Restore settings without confusing that with restarting a simulation

In Procedural Generation, we kept descriptions, samples and results separate. Here the cube's surface keeps its connections while its positions change. Translation, rotation and scale moved the whole cube. This lesson lets its parts move relative to one another.

## Begin with the museum's cube

The green jelly cube is already here, held at one upper point. Its desk changes STIFFNESS, DAMPING and PRESSURE. Change one setting and watch before touching another. RESET restores settings; it does not rewind the surface. The mill and other bodies remain comparisons in the room.

We reconstruct that small setup: a subdivided cube, one selected attachment and the three response settings. Godot supplies the solver. The prepared Endless Museum supplies the camera, floor, player and XRTools. We retain the black PointBody from Mirrored Patterns and use its existing collider as a probe.

Save these three files together. Attach `study.gd` to an empty Node3D at unit scale in an open museum bay. The review places it at hall-local (11.5, 0, 8.5), yaw 180 degrees, beside the installed cube. This is a learner reconstruction inside the existing hall; it does not replace the hall's artifact.

## A mesh that can yield

`yielding_cube.gd` extends `SoftBody3D`. Unlike our earlier rigid point, this node uses its mesh for both rendering and collision. A separate box collider would remain rigid and would not describe the changing surface.

The familiar `BoxMesh` supplies a closed surface. Four subdivisions on each axis add positions that can move; this is different from `simulation_precision`, which controls solver work. Keep both fixed for the first comparison. The cube uses the installed artifact's 0.3 metre edge, mass and opening response values. The current project selects **Jolt Physics**.

Read the undeformed vertex array before the simulation changes it. `crown_index()` first restricts the search to the top face, then chooses the point closest to its centre in x and z. It returns an array address, not a position. Ties keep the first candidate. We do not invent an unexplained vertex number or assume that every subdivision has an exact centre vertex.
'''
t+=block('yielding_cube.gd')
t+='''
The pin prevents that selected position from moving. The rest may respond to gravity and contact. The gold dot in the host marks the attachment; drawing the dot does not create the constraint. `set_point_pinned()` does that work.

`linear_stiffness` changes resistance to deformation. `damping_coefficient` reduces motion. `pressure_coefficient` adds inflation to this closed surface. These are different controls, not three names for softness. Begin with the given values; compare one change at a time rather than expecting a universal material from a slider number.

## The point becomes a probe

`study.gd` creates the cube and the same black point. The soft body's mask includes layer 4, where PointBody already lives, as well as the room and the museum hand layers. The inherited point itself needs no new geometry or grab implementation.

Grab it and move it slowly into the green surface. Its held position is prescribed by your hand. It can displace the soft surface, but the surface cannot move your tracked controller. Fast motion may pass through a small surface; begin with a slow press and observe contact.

The held trigger changes stiffness. On desktop, **1** changes stiffness, **2** damping, **3** pressure and **R** restores the settings. The paired values are a smaller comparison than the museum's sliders. Release parks the point clear of the cube, as it did in the earlier study.
'''
t+=block('study.gd')
t+='''
The host creates its label before calling `refresh()`. Every referenced object is created here or in the cube class. No pre-existing mesh node or scene-path lookup is required.

<details>
<summary>Carried file: point_body.gd — unchanged from Mirrored Patterns</summary>

Keep your existing file, or copy this identical version. Its sphere, collision boundary and XRTools pickup behaviour are inherited work.
'''
t+=block('point_body.gd')
t+='''
</details>

## Predict, then compare

Find the gold attachment before moving the point. Predict which part must remain fixed. Press slowly, move the probe away and watch the surface continue responding. The hand supplied a condition; it did not specify every later position.

Restore settings. Change stiffness alone, then restore and change damping alone. Do the two bodies of motion look different? Keep the mesh and attachment fixed. A smaller movement does not by itself prove a greater stiffness: the interaction and elapsed time also matter.

Press R while the surface is moving. The same simulated body continues with the original coefficients. For a comparison with matching initial positions and velocities, restart the learner instance. Resetting coefficients alone is not that experiment.

Try one code change: set `DIVISIONS` to 2 and restart. Predict that the selection function will still find a top-face point and that the mesh will have fewer vertices. Test both claims. Describe the changed surface without calling fewer vertices a softer material. The next room will change which positions are pinned, using a sheet instead of an enclosed cube.

## Keep, change, compare

Keep the reference mesh and its attachment. Change one response setting. Compare motion while remembering that the running body carries state. Carry forward a complete solver setup and a selection rule for its boundary.

Sources: `commons/artifacts/jelly_cube/jelly_cube.gd`, `_create_soft_body()`, `_configure_anchor()` and `_reset_physics()`; `commons/artifacts/timing_machines/soft_workshop.gd`. API: [Godot 4.6 SoftBody3D](https://docs.godotengine.org/en/4.6/classes/class_softbody3d.html) and [the mesh-based setup](https://docs.godotengine.org/en/4.6/tutorials/physics/soft_body.html). The solver is supplied; the tutorial reconstructs its visible setup and conditions.
'''
f='''# What holds a cube together?

<!-- @jelly_cube -->

The cube gives way. A small arm holds one point at its top; the rest of its green surface can move. Follow the indentation as it spreads beyond the place you touched. You have not told each point where to go.

In the last sequence, a body followed from a description, a field or a sample. Here the description also includes conditions under which a body may keep changing. Its surface retains its connections. The positions those connections join are no longer still.

Before changing a setting, decide what you mean by softer. A body that yields farther? One that settles slowly? One that no longer recovers the shape you expected? The room offers separate controls for stiffness, damping and pressure. Your word has gathered several possible observations into one.

Reach toward it. The cube can deform against your hand, but it cannot push your tracked hand out of position. This museum rig places the collision hand at the controller's position.[^hand] One body must accommodate the meeting; the other has already been placed.

The gold attachment remains. The visible arm makes that condition legible, but its appearance alone could not hold a simulated point. A particular vertex has been pinned. We have made a freedom to yield and a place where yielding stops.

There is no modeled flesh behind the skin. This is a closed surface responding through the engine's soft-body rules. Turn pressure down to zero and wait. What can the surface keep when inflation no longer helps it?

The mesh has a resolution; the simulation also has a work budget. We can change either. What feels like a quality of matter depends partly on these choices.[^solver] A convincing wobble does not tell us which calculation produced it, or how that calculation would change under another demand.

Restore the settings while the cube is moving. It continues from where it has arrived. The numbers return sooner than the body. If you want the beginning again, more must be restored than the control panel admits.

<!-- @ -->

<!-- @softmill -->

Turn toward the mill. Its moving apparatus brings a repeated encounter to a soft sphere. Stop the drive. The sphere's physics continues; something the mechanism has set in motion outlasts the mechanism's movement.

The cube exposes its coefficients. The mill exposes a source of disturbance. The room supplies further conditions: contact, support, gravity and the points required to stay. Which of these belongs to the object when we call the object soft?

Its changing outline can tempt us to call it free. Yet this surface cannot tear, grow an opening or choose new neighbours through these controls. The freedom is specific. In the next room, we move one of its edges: which points must stay?

<!-- @ -->

[^solver]: The placed cube requests simulation precision 5 and four BoxMesh subdivisions per axis. These are different controls. The project currently selects Jolt Physics; earlier notes describing GodotPhysics3D are historical. See the [Godot 4.6 SoftBody3D reference](https://docs.godotengine.org/en/4.6/classes/class_softbody3d.html).

[^hand]: Both collision hands in `commons/scenes/base.tscn` select TELEPORT mode. The component copies the tracked transform directly in that mode; COLLIDE is another supported choice. This is a property of the prepared rig, not a necessary asymmetry in every VR system. It is source evidence, not a completed physical-headset contact test.
'''
(M/'tutorial.md').write_bytes(t.encode('utf8'));(M/'final.md').write_bytes(f.encode('utf8'))
print('Wrote one full tutorial and its separate reflection.')
