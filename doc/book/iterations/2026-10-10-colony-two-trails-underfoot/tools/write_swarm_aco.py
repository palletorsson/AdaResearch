"""Build and print the carried two-channel lesson; save prior evidence once."""
from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1]
ID='SwarmIntelligence_Ant_Colony_Optimization'
O=R/'doc/book/iterations/2026-10-10-colony-two-trails-underfoot'
S=R/'doc/book/studies/swarm-through-the-hands'/ID
M=R/'commons/maps'/ID
def write(p,s):
 p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,indent=2,ensure_ascii=False)+'\n')
O.mkdir(parents=True,exist_ok=True);S.mkdir(parents=True,exist_ok=True)
before=O/'before';before.mkdir(exist_ok=True)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 if not (before/name).exists() and (M/name).exists():shutil.copy2(M/name,before/name)
for source,name in [('commons/data/museum/em_plan.json','em_plan.json'),('doc/book/course/execution-plan/plan.json','execution-plan.json'),('doc/book/course/storyboards/SWARM-HANDOFF.md','SWARM-HANDOFF.md')]:
 if not (before/name).exists():shutil.copy2(R/source,before/name)
shutil.copy2(R/'doc/book/studies/swarm-through-the-hands/SwarmIntelligence_Agent_Based_Modeling_ABM/point_body.gd',S/'point_body.gd')
write(S/'study.tscn','''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="study.gd" id="1"]

[node name="TwoTrails" type="Node3D"]
script = ExtResource("1")
''')
def block(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
tutorial='''# Ant Colony — two trails underfoot

The spheres now move through a twelve-metre field. Walk between them. The point from the previous hall still has position, velocity and a carrying flag. This time its journey leaves two kinds of trace.

## Learning elements

- Two separate fields: home trail and food trail.
- State chooses which field to read and which to write.
- Destination contact reverses direction and renews the trail strength.
- Reinforcement and evaporation; replacing bodies versus clearing their traces.

## Keep the object; change its information

In ABM a returning point knew the home coordinate. Here it finds its direction from three local samples. A searching point reads **food** and writes **home**. A carrying point reads **home** and writes **food**. The destination coordinates are used for contact and source emission, not as a steering target.

Each floor cell has two strips: blue on its left for home, rose on its right for food. These are two numbers at the same address, not two lanes the point must stay inside. A green cube above a sphere means it carries food. The ring around the selected sphere and its three small sensor marks let you follow one record among the others.

Hold any sphere to pause the colony. Move it beside FOOD, release it, then press ONE TICK. Its carry flag turns on. The next samples come from the other field. Carry that same point to HOME and step again: one delivery, the flag off. Holding does not collect or deliver by itself. The trigger selects a held point for the readout.

## The complete rule

Save `colony.gd` beside the carried `point_body.gd` and the host below. The model stays in a 16×16 periodic plane. One cell now occupies 0.75 m; 24 points replace the previous six, using the same rule. The large room changes the view and reach, not the definition of a cell.

`step()` first checks destination contacts. It then reads the previous fields for every point, commits all movement, fades both fields and deposits into the selected channel. The two destinations replenish only their own cells. A new mark cannot steer a later point during the same tick.

On contact we reverse the model velocity once. This is a declared ant-like turn, not a physical collision. Between contacts the bounded steering from Boids remains. Equal sensor readings keep the direction; a stationary searcher starts east and a stationary returner starts west. There is no hidden pathfinder.

'''+block('colony.gd')+'''
`read_home` selects one array in `sense()`. In `deposit()`, a carrying point writes food; a searching point writes home. The opposite channel is untouched by that deposit. Both still evaporate in the field update. Energy declines with time since a destination, so a point cannot lay an equally strong trail forever.

Food is inexhaustible. The field wraps at its edges; the home and food contact tests use direct distance. The spheres can overlap and do not push you. This is a small foraging model, not a simulation of ant biology or evidence that the shortest route has been found. The hall's historical ACO title includes optimization methods that require a stated cost and a comparison; this lesson isolates their shared-trace mechanism.

## Put the same point into the room

The prepared museum supplies its floor, player, camera, lights, XRTools and `commons/interactables/push_button.tscn`. Create a Node3D at the centre of a clear 12×12 m working area, with another metre at each end for the controls, and attach `study.gd`. Its local origin is floor level. The permanent exhibit in this hall runs this same host; when reconstructing it, use a working copy of the hall and replace the existing `ant_colony_walk` instance so you do not stack two displays.

The host creates every sphere and field strip in code. PointBody itself is unchanged. Its mesh and collision shape are both enlarged threefold for this room; its rigid-body root stays unscaled. The points travel at 0.8 m above the floor. Hold one to bring it closer. Two matching banks of controls let you pause and step from either end of the field. Keys 1, 2, 3 and R provide the same actions on desktop. The supplied host batches the 512 strips into two MultiMeshes; rendering this many cells does not require one draw per strip.

<details><summary>Carried point_body.gd — complete, unchanged</summary>

'''+block('point_body.gd')+'''
</details>

<details><summary>study.gd — complete room and interaction host</summary>

'''+block('study.gd')+'''
</details>

The host keeps painting while paused. Holding a point records its position in the host's local frame and zeros its velocity. Release projects it back onto the field plane. Its carrying flag and energy stay with it. REPLACE POINTS restores the starting population but keeps both fields, deliveries and tick count. CLEAR ALL resets those records too; it retains your retention and deposit settings. Reset actions wait until all points are released.

## Predict, then change something

Pause the room. Put a searching point at FOOD. Predict: it becomes a returner, reads blue and leaves rose. Move that carrying point to HOME. Predict the reverse, with one delivery. Now replace the points: the marks remain. Clear all: the fields are empty until the next tick replenishes the destination cells.

For an independent code change, set `deposit_amount` to 0.25 instead of 0.5. A point with energy 1 deposits 0.25 into an empty cell when you call `deposit()` directly. On a tick, energy falls first to 0.9975, so its new mark is 0.249375 before another point adds anything. Test a cell away from the two sources. The other channel must remain zero. Explain why fading alone would not establish which channel was written.

Carry this distinction onward: the trace is stored outside the point. In Particle Swarm Optimization, each point will also remember a best position of its own. We will have to ask what makes a position “best”.
'''
write(M/'tutorial.md',tutorial)
write(M/'final.md','''# Directions left for someone else

<!-- @ant_colony_walk -->

A blue mark passes beneath your feet. A rose mark runs beside it. The spheres move at the height of your hand. You can stand inside the field that they read.

Follow one without a green cube. It is looking for food. It reads the food trail while leaving a home trail behind. At the food ring the cube appears and the direction reverses. Now the same body reads home and leaves food. What it gives another traveller depends on where it has just been.

In the previous room, the returning point knew where home was. Here no steering instruction names that destination. Three nearby samples ask which way has the stronger trace. The point can miss a route. Its limited view has consequences even when its rule executes correctly.

Pick it up. The room pauses while your hand holds it. Release it elsewhere. You have moved one body without moving the marks that led it there. Its next decision joins a history made by other movements.

Replace the points. The floor keeps its traces. A new population starts among directions it did not make. Clear the field as well and that inheritance disappears. These two buttons make different beginnings.

The marks fade. Fresh passages strengthen them; a traveller's strength declines until it reaches a destination again. A route persists through repeated use and replenishment. A bright route is therefore evidence of this process. Brightness alone does not tell us that the route is shortest, fair or worth following.

We call this indirect coordination stigmergy. The word names the way an action changes a shared environment that can affect a later action. It does not give the spheres a common intention. Nor does their coordination explain a human society merely because we also inherit paths.

You may walk across the brightest trace without affecting it. This version gives your steps no weight in the field. Your hand can move a point; your foot cannot erase a mark. The room admits you through particular operations. Standing inside the model helps you notice which of your actions it has not learned to answer.

In the next room, a point keeps a remembered position. The question changes from what a place retains to what a body carries as its best encounter.
''')
print('Printed ACO tutorial and reflection; before sources preserved.')
