"""Assemble the complete FlowFields lesson from its actual student source."""
from pathlib import Path
import shutil
R=Path(__file__).resolve().parents[1]
S=R/'doc/book/studies/swarm-through-the-hands/SwarmIntelligence_FlowFields'
O=R/'doc/book/iterations/2026-10-10-flow-directions-already-here'
M=R/'commons/maps/SwarmIntelligence_FlowFields'
def write(p,s):
 p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf8')
for rel in ['tutorial.md','final.md','technical.md','map_data.json']:
 p=M/rel;q=O/'before'/rel
 q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
def code(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
write(M/'tutorial.md','''# FlowFields — directions already here

## Learning elements

- A vector stored at a grid address.
- Desired velocity and current velocity.
- A bounded steering acceleration.
- Reading a field without writing into it.
- Zero direction as an explicit behaviour choice.

## Encounter

In the Endless Museum, find a moving body in **FlowFieldMain** and read the nearby direction mark. Predict its turn. The exhibit moves through route fields, wind and noise. Its live table contains the existing simulation; the small study below gives us a few points whose changes we can inspect.

Bring `point_body.gd` from Physarum unchanged. Bring the flat grid address and the conversion between cells and local metres. Replace the scalar trace with a **direction vector**. The point now carries velocity instead of a heading. It reads one cell, adjusts its movement and leaves that cell unchanged. No neighbour has to send it a message.

## Where the code runs

Continue in the prepared Ada project. The museum supplies the player, camera, light and installed XR Tools. Put `field.gd`, `study.gd` and the carried `point_body.gd` in one folder. Attach `study.gd` to a new unscaled Node3D at floor level in a clear study bay, facing the visitor along local +Z. Allow 2.7 metres square and an approach to the buttons. The complete carried file appears below for reconstruction; there is no new sphere or pickup lesson here.

The host also instantiates the supplied `res://commons/interactables/push_button.tscn` and connects its `pressed` signal. Everything else is created in these scripts. An empty project without that prepared environment is not the context of this lesson.

## A direction is not yet a movement

The 16 × 16 array stores `Vector2` values. The address remains `x + y * WIDTH`. Most cells contain `(1,0)`, pointing along local +X. The central patch contains `(0,1)`, pointing along local −Z. The display conversion is the same as Physarum: one cell is 0.16 metres; increasing model y goes away from the front of the table.

Normalise the sampled vector and multiply by `SPEED` to get the **desired velocity**, in cells per second. Subtract the point's current velocity. A point already moving as requested has no correction to make. One moving across the requested direction needs to turn.

Divide that difference by `RESPONSE`, measured in seconds, to get an acceleration in cells per second squared. Limit its magnitude to `MAX_ACCEL`. Each 0.05-second step adds acceleration × time to velocity, then velocity × time to position. This is our familiar velocity integration from Forces, now directed by a sampled field. It is a kinematic steering model, not a mass-dependent rigid-body force.

Save as `field.gd`:

'''+code('field.gd')+'''
Read `acceleration()` and `step()` first. The other functions prepare the field, convert an address or support an edit. `set_patch()` changes only the central rectangle. `edit_cell()` changes only one address. **Neither is called by the moving agents.** Movement cannot deposit, erase or learn a field.

For the default point 0, the first desired velocity is `(3,0)` and the current velocity is `(0,0)`. Their difference divided by 0.5 is `(6,0)`. After one 0.05-second step, velocity is `(0.3,0)` and position moves 0.015 cells. It approaches the requested speed over successive steps; it does not jump to it. On entering the turning patch, some eastward velocity remains while the northward component grows.

A zero vector produces zero desired velocity. Subtracting a nonzero current velocity then produces **braking**, limited in the same way. Zero does not mean “continue unchanged” in this model. The larger exhibit instead adds random wandering at zero vectors. Both are programmed decisions; an empty direction alone does not decide what a body should do.

We keep Physarum's periodic boundary: leaving one edge returns at the opposite edge. These edge crossings are wraps, not physical turns. The production exhibit uses a return rule near its boundary. We also omit collision avoidance, obstacle costs and route construction. Shared directions are the subject here; BFS, Dijkstra and A-star belong to Graph Theory later in the museum.

## Let the carried points show the difference

Six instances of the same PointBody move above the field. Point 0 is pink so you can follow its readout. The arrows are thin cylinders with cone tips. Dark cells without an arrow contain zero. Nothing is hidden behind a scene reference to a mesh.

**Run/pause** starts or stops the model. **Turn / stop / east** cycles the central patch through `(0,1)`, `(0,0)` and `(1,0)` without resetting positions or velocities. **Reset** restores the initial field, positions and zero velocities, clears all hand edits and pauses. Desktop keys are **1**, **2** and **R**.

Hold any point to pause the whole model. Move it to an address and press the trigger to cycle that cell from east to north to zero to east. This is **your edit to the supplied field**, not an agent leaving a trail. Release the point to return it to the field plane. A held point's velocity is cleared; the other velocities are retained. If the model was running, it resumes when all points are released. The first cell it reads is the one you chose.

Save as `study.gd`:

'''+code('study.gd')+'''
`to_local()` records the held point correctly when XRTools temporarily parents it to the controller. The model remains in cell coordinates even if the study is moved or rotated in the museum. Keep the study's scale at one. Frame time is accumulated into fixed model steps; very long frames contribute at most half a second, so this display does not promise exact wall-clock timing after a stall.

The display helpers build the same sort of table, labels and controls as the previous study. The new visual work is the direction at each address and the paired readout: **what this position requests / what the point is doing**.

## The carried file

This is `point_body.gd`, unchanged from Physarum. Its existing signal now calls `edit_under()` instead of depositing a scalar trace. Its mesh and grab behaviour remain the same.

'''+code('point_body.gd')+'''
## Check what you have learned

Reset and follow the pink point. Before it enters the turning patch, predict which velocity component will decrease and which will increase. Read the numbers at the boundary. The turn takes time because velocity has a previous value and the correction is bounded.

Run again with the patch set to stop. A point entering it should slow down, not choose a random escape direction. For a clean comparison, reset before each run and change the patch while paused. The same start lets you distinguish a changed field from a changed starting position.

Hold a point over an eastward cell and trigger once. Release it, then put another point there. Both should read the new northward direction. The first visitor did not consume it. Let the simulation run: the arrows themselves should stay unchanged.

For an independent edit, change the patch's first direction in `set_patch()` from `(0,1)` to `(0,-1)`. Predict the initial acceleration of a point at rest in that patch. Run it and check the sign of its y velocity. Reversing the field should reverse the requested turn without rebuilding the point.

## Carry onward

Keep PointBody, its velocity, and desired-minus-current steering. Boids will construct the desired movement from **nearby moving points**. The steering operation can stay while its source changes.

The [autonomous agents chapter of The Nature of Code](https://natureofcode.com/autonomous-agents/) provides a companion account of flow-field steering. Our response time, acceleration cap, zero-vector braking and periodic boundary are explicit choices for this museum study.
''')
# Retain the reflective argument; correct the encounter and avoid claiming a new lesson's policy is production behaviour.
f=(O/'before/final.md').read_text(encoding='utf8')
f=f.replace('<!-- @FlowFieldMain -->','<!-- @flow_field_table -->')
f=f.replace('Find an arrow near an agent', 'On the live table, find a direction mark near an agent')
f=f.replace("Reynolds's own wanderers keep most of yesterday's heading and add a little chance to it; the beads in the Randomness terrarium will show the difference between the two again.", 'Our small point study chooses to brake at a zero vector. Put the two behaviours beside one another: an absent direction is also a place where somebody has made a decision.')
f=f.replace('The field is a solved problem', 'The field is a prepared route')
f=f.replace('the field is a solved problem', 'the field is a prepared route')
f=f.replace('with no problem solved at all', 'without a destination to reach')
write(M/'final.md',f)
print('FlowFields: full carried-point lesson assembled; reflective encounter updated.')
