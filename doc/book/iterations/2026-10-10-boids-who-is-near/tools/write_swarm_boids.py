"""Print the carried study verbatim, keeping one new subject: neighbours."""
from pathlib import Path
import shutil
R=Path(__file__).resolve().parents[1]
S=R/'doc/book/studies/swarm-through-the-hands/SwarmIntelligence_Boids_Algorithm'
M=R/'commons/maps/SwarmIntelligence_Boids_Algorithm'
O=R/'doc/book/iterations/2026-10-10-boids-who-is-near'
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf8')
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 p=O/'before'/name;p.parent.mkdir(parents=True,exist_ok=True)
 if not p.exists():shutil.copy2(M/name,p)
def code(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
write(M/'tutorial.md','''# Boids — who is near?

## Learning elements

- Selecting neighbours by distance; excluding yourself.
- Separation, alignment and cohesion.
- Averages and weighted steering requests.
- Reading one snapshot; committing the next state together.
- The difference between no request and a request to stop.

## Encounter

Find the ringed body in the museum's **flocking_controls** display. Its red, blue and green arrows can disagree. Move one slider and watch that body before judging the whole flock. Then change RADIUS. Which bodies can now contribute to its movement?

Bring the same PointBody from FlowFields. Keep its velocity, bounded steering and local coordinates. **Replace the supplied direction field with observations of nearby points.** We will make the three requests separately before combining them. The aquarium, open flock and film remain comparisons; this lesson does not reconstruct every exhibit.

## Where the code runs

Continue in the prepared Ada museum project, with its player, camera, lights and XR Tools. Save `flock.gd`, `study.gd` and the unchanged `point_body.gd` together. Attach `study.gd` to an unscaled Node3D at floor level in a clear study bay. Reserve 2.7 metres square, with space to approach its local +Z front. The supplied `res://commons/interactables/push_button.tscn` provides the four physical buttons. These three scripts create everything else in the study; no pre-made mesh node is required.

The full PointBody appears at the end for reconstruction. Read the new model first. The table, pickup and fixed-step host continue the preceding lesson.

## First choose who counts

`neighbours(i)` returns the indices of other points less than `radius` cells away. It excludes `i`, even though a point is always at zero distance from itself. At the initial radius of 3.5, point 0 sees points 1 and 2. The distant points do not enter its averages.

We retain the 16 × 16 plane and 0.16 metres per cell. This is still a three-dimensional museum object, but movement is restricted to local XZ so the calculation stays visible from above. The aquarium shows movement in all three dimensions.

The boundary remains periodic: a point crossing one edge reappears at the opposite edge. **Neighbour distances are measured directly across the drawn plane**, not across that seam. Two bodies near opposite edges may therefore be excluded from each other's calculations. This declared boundary choice matches the panel's visible seam; periodic motion does not automatically imply periodic neighbourhoods.

## Three requests, one familiar steering calculation

**Separation:** for neighbours closer than two cells, add vectors pointing away. `offset / d2` has a magnitude of one divided by distance, so closer neighbours contribute more. Normalising the sum chooses a direction; multiply by `SPEED` to request movement that way. Exact overlap has no away direction, so we skip that division. This does not invent a collision response or guarantee that overlapping points separate.

**Alignment:** average the neighbours' velocities. Use that actual average as the desired velocity. Here alignment can change speed as well as heading. If the average is zero, the request is to brake. We do not normalise this average back to full speed.

**Cohesion:** average the offsets to nearby points. That vector points towards their local centre. Normalise it and request movement at `SPEED`. There is no global flock centre in this calculation. A zero centre offset contributes no cohesion request.

Each request uses the FlowFields calculation: `(desired - current) / RESPONSE`, capped at `MAX_ACCEL`. Requests are accelerations in cells/s². Multiply them by their weights, add the active requests and cap the combined acceleration again. Separation starts at weight 1.5; the other weights start at 1. A coloured arrow shows a weighted request; the white arrow shows the capped combination. Large requests can cancel, and the final cap can hide further increases in a weight.

**No neighbours means zero acceleration and coasting.** It does not mean desired velocity zero. This distinction matters: in FlowFields an explicit zero direction requested braking. Here an empty neighbourhood requests nothing. Likewise, balanced separation or an already-centred position contributes no request; only an alignment average of zero explicitly asks this model to stop.

Save as `flock.gd`:

'''+code('flock.gd')+'''
At the initial point 0, current velocity is `(1,0)`. Point 1 is one cell to its right, within the separation distance. Point 2 is farther than two cells, so it contributes to alignment and cohesion but not separation. Separation requests movement left; the bounded request is `(-6,0)`. Its weighted value is `(-9,0)`, capped again to `(-6,0)` when it acts alone. After one step the point's velocity is `(0.7,0)`: it is still moving right, but slowing. An arrow is a correction, not an instantaneous direction of travel.

Both neighbours move at `(0,2)`, so alignment requests `(0,2)` and produces acceleration `(-2,4)`. The average offset for cohesion is `(1.5,0.5)`, towards the local group. These are different observations, not three names for the same attraction.

## Let everyone read the same moment

`step()` fills two new arrays while `positions` and `velocities` remain unchanged. Only after all six calculations does it replace the old state. This is the same old/next distinction used in Cellular Automata. No later point reads an earlier point's future. Reversing the list should give the same physical next state, apart from floating-point rounding.

The existing aquarium uses a spatial grid to find neighbours and updates its bodies in place. Its formulas and boundary response also differ. Our small model deliberately uses a full pairwise scan, a shared snapshot and the bounded steering already learned. It is a readable reconstruction of the three-rule idea, not a claim that the aquarium runs this exact script. Neither model is a mass-dependent rigid-body simulation.

## Use the same points to change the neighbourhood

The study begins paused, with separation selected. **Run/pause** advances the same fixed 0.05-second steps. **Next rule** cycles separation → alignment → cohesion → all three. **Radius** switches between 2 and 3.5 cells. **Reset bodies** restores the exact positions and velocities, resets the tick and pauses, while keeping the selected rule, radius and weights. This lets you compare different requests from the same starting arrangement. Desktop keys are **1**, **2**, **3** and **R**.

The gold ring marks the observed point's radius. Cyan rings mark its selected neighbours. Red means separation, blue alignment and green cohesion; white is the acceleration actually applied. Arrow length is 0.07 metres per cell/s², an enlarged diagram rather than a distance the body will travel. The arrows show the requests for the next step.

Hold any point to pause everyone. Move it into or out of a neighbourhood. Press its trigger to make it the observed point. Release it to place it back on the plane. The held point's velocity is cleared; other velocities remain. Movement resumes after release if Run was active. The hand changes a position, not a global flock command. Release held points before Reset bodies; an attached hand continues to supply its point's position.

Save as `study.gd`:

'''+code('study.gd')+'''
`record(to_local(...))` keeps the model in the study's frame while XR Tools holds the sphere under a controller. The familiar host limits a stalled frame to half a second of catch-up. The table has no collision wall: leaving it is handled by the model's wrap rule. Its circles and arrows are explanatory meshes, not forces from the physics engine.

## The body we brought

This file is byte-identical to FlowFields. Its mesh, collision shape, frozen release and pickup behaviour are already learned. The change in this hall belongs to the relation between points.

Save the carried `point_body.gd`:

'''+code('point_body.gd')+'''
## Make a prediction you can check

1. With separation selected, reset and run one step. Point 0 still moves right, but more slowly. Explain why the left-pointing arrow did not instantly reverse its velocity.
2. Reset, select alignment and predict its first velocity: `(0.9,0.2)`. Then select cohesion from the same reset start. Which observation changed?
3. While paused, change radius from 3.5 to 2. Point 0 loses point 2. Separation stays the same at this start; the local centre changes. Move a distant point inside the circle and check the neighbour list.
4. In the code, change alignment's weight from 1 to 0.5. In alignment mode, predict point 0's first velocity before running it: `(0.95,0.1)`. Reset and compare at the same step, rather than comparing two unrelated scatters.
5. Put a moving point alone. It should coast. Put it beside stationary neighbours in alignment mode. It should slow. Explain the difference between absent input and a request for zero velocity.

The automated reconstruction checks these values using the code printed here, reversed agent order, coincident points, a changed weight and deliberately broken variants. It also exercises the actual buttons and synthetic XR Tools pickup. A passing run verifies this implementation; it does not establish how an independent learner or a headset user experiences the room.

## What travels onward

The same point now responds to a local set of other bodies. A large pattern can follow without a leader knowing its shape. Keep the neighbour selector, velocity, weighted requests and shared snapshot. In Agent-Based Modeling, give the carried body an explicit internal state and ask when the same surroundings lead it to act differently.

The three-behaviour lineage comes from Craig Reynolds's [Boids work](https://www.red3d.com/cwr/boids/). The museum's implementation and this deliberately small study make their own choices about weights, updates and edges.
''')
print('Printed Boids model, host and carried PointBody into canonical tutorial.md.')
