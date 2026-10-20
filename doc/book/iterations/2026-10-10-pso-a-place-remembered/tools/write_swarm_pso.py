"""Print the sixth Swarm lesson and keep its before evidence once."""
from pathlib import Path
import shutil
R=Path(__file__).resolve().parents[1]
ID='SwarmIntelligence_Particle_Swarm_Optimization'
S=R/'doc/book/studies/swarm-through-the-hands'/ID
M=R/'commons/maps'/ID
O=R/'doc/book/iterations/2026-10-10-pso-a-place-remembered'
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
B=O/'before';B.mkdir(parents=True,exist_ok=True)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 if (M/name).exists() and not (B/name).exists():shutil.copy2(M/name,B/name)
for source,name in [('commons/data/museum/em_plan.json','em_plan.json'),('doc/book/course/execution-plan/plan.json','execution-plan.json'),('doc/book/course/storyboards/SWARM-HANDOFF.md','SWARM-HANDOFF.md')]:
 if not (B/name).exists():shutil.copy2(R/source,B/name)
shutil.copy2(S.parent/'SwarmIntelligence_Ant_Colony_Optimization/point_body.gd',S/'point_body.gd')
write(S/'study.tscn','''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="study.gd" id="1"]

[node name="RememberedPoint" type="Node3D"]
script = ExtResource("1")
''')
def block(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
write(M/'tutorial.md','''# Particle Swarm — a place remembered

Walk between the spheres. Hold one and move it away from the gathering. A blue ring stays behind: a position this point remembers. The gold ring marks the best position found by the group. Release the sphere and step the model. Its next movement combines where it was going, where it remembers doing well, and what the others have found.

## Learning elements

- A score is a number assigned to a position by an objective function.
- Store a personal best as both a position and its score.
- Combine inertia, personal attraction and shared attraction.
- Evaluate the starting population before moving; give every point the same shared record for one iteration.
- Changing the objective starts a new set of best records.

## Keep the point; move the memory

Ant Colony left information in the floor. Here we keep the same grabbable PointBody, but replace its carrying flag and trail sampling with a remembered position and score. The floor shows the scoring rule; it does not accumulate trails. Brighter tiles have a higher score under the current rule.

The room starts paused on CENTER, so you can meet the scattered points before they gather. Press RUN or ONE STEP when ready. The score is `-(x*x + y*y)`: the centre scores zero, and positions farther away score less. **Larger wins** throughout this lesson. The gold ring means best encountered so far, not a proven optimum. The points can coincide; they are candidate solutions, not birds avoiding a collision.

The host projects positions into a twelve-metre square. Model x runs across it; model y runs along local negative Z. These two numbers describe a search coordinate, not height. The floor stays flat.

## The complete search rule

Save `swarm.gd` beside the carried `point_body.gd` and the room host below. `reset_memories()` scores all starting positions before the first move. Each record keeps the position that earned its score. `remember()` replaces that pair only when the new score is strictly greater; ties retain the earlier record.

`terms()` returns three vectors: the previous displacement multiplied by inertia, a pull toward the point's own best, and a pull toward the group's best. Each pull gets a seeded random multiplier between zero and one. A fixed seed makes the experiment repeatable; it does not make its conclusions universal.

'''+block('swarm.gd')+'''
`step()` includes any hand-placed candidates first, then takes one copy of the shared best. Every point uses that same copy. Positions are committed together before the new best records are chosen. One point cannot silently use a discovery made halfway through another point's update.

Here `velocities` stores **displacement per algorithm iteration**, not metres per second. We cap a move at 0.35 model units and stop an outward component at the square's boundary. The host plays ten iterations per second. This is a discrete optimizer, not a force simulation; changing playback speed changes how quickly you watch it.

## Try another meaning of better

Pause and press EDGE. The positions and velocities remain. Every remembered position becomes its point's current position, and every score is recalculated as `x*x + y*y`. The four corners score highest. This rewards distance from the centre; it does not reward separation between points. All points may choose the same corner.

RIDGE uses `-(x-y)^2 / 2`: minus squared perpendicular distance to the diagonal x=y. Every position along that diagonal has the same best score. A line of equally good answers is different from one preferred destination. Switching objectives pauses the model, so you can inspect the new records before resuming. RESTART scatters the same starting population and resets the random stream under the selected objective; it keeps your three coefficients.

The smaller existing display at the back adds NOVELTY. Its score depends on a changing archive, so it must rescore memories when that archive changes. It is a comparison with an additional mechanism, not hidden work required by this first reconstruction. That display also uses different score units: ordinary distance rather than the squared distance used here.

## Put it in the existing museum

Use a working copy of this hall. Replace its `particle_swarm_walk` instance with a Node3D carrying `study.gd`; do not overlay two installations. Set the origin at floor level, leaving 12×12 m for the field and another metre at each end for controls. The museum already supplies the floor, player, camera, light, XRTools and `commons/interactables/push_button.tscn`.

The unchanged PointBody is printed below. The host enlarges its mesh and grab shape together to 0.51 m diameter while leaving the rigid-body root unscaled. These frozen, model-driven pickables move at 0.8 m height, overlap freely and do not push the player.

<details><summary>point_body.gd — carried unchanged from Ant Colony</summary>

'''+block('point_body.gd')+'''
</details>

<details><summary>study.gd — complete display and interaction host</summary>

'''+block('study.gd')+'''
</details>

Hold a point to pause all motion and change its position. Its previous best remains visible; moving it by hand is not yet an evaluated iteration. Release and step: the new position is scored before movement. A worse placement leaves its remembered best intact. Holding zeros velocity. A held trigger selects that point for the readout. Reset and objective changes wait until all points are released.

The white ring follows the selected body; blue marks its own best; gold marks the group's. Thin cylinders join the current position to these remembered destinations. They show position differences, not the weighted random terms or a predicted path. Two control banks operate the same model. Desktop keys 1/2 run and step, R restarts, and 3/4/5 select CENTER/EDGE/RIDGE.

## Predict one movement

Use `terms()` with a controlled example: position (0.2, 0.1), velocity (0.1, 0), own best (0.1, 0.1), shared best (0, 0), and multipliers 0.5 and 0.25. With the supplied coefficients the three contributions are (0.06, 0), (-0.075, 0), and (-0.075, -0.0375). Their sum is (-0.09, -0.0375), below the cap. The next position is (0.11, 0.0625).

Now independently set `social_pull` to 0.0. For the same inputs, the sum is (-0.015, 0) and the next position is (0.185, 0.1). Predict the change before running it. In the room, restart and compare: removing the shared pull changes what can coordinate the points, without deleting their personal memory.

The last Swarm hall will let us compare what a body reads and what it leaves. Carry this distinction: a common destination here comes from a shared score and record. It is not the same relationship as a neighbour's heading or a trail underfoot.
''')
write(M/'final.md','''# Better according to which score?

<!-- @particle_swarm_walk -->

You carry a sphere away from the others. A blue ring remains where it once did better. The body is here; the remembered answer is there. Release it and the distance between them enters its next movement.

In the previous room, a trace could guide a body that had never made it. Here each point keeps a place of its own. A second record belongs to the group. The gold ring gathers their discoveries into one answer that every point can use. It need not be where most of them are standing.

Stand in the warm centre of the floor. Under CENTER, moving farther from you receives a lower score. Press EDGE. The same floor becomes bright at its corners. Nothing about the points has made the centre undesirable. We changed the question asked of each position.

They retain their movement, but the old best records are set aside. A score was earned under a rule. Keeping the number while changing that rule would make the memory look more certain than it is.

Watch them move outward. This may look like an invitation to difference. Yet EDGE measures distance from the centre, not distance from one another. Every sphere can succeed by gathering at the same corner. A field that rewards departure does not necessarily sustain plurality.

Press RIDGE. Now a diagonal has many equally valued positions. The bodies may still gather at one of them. The rule permits a line of answers; their shared history can narrow it. Permission and what happens within it are different things.

The cylinders on the floor make two remembered destinations visible. They are not ropes. The points do not have to stay apart, and no body must carry the weight of another. This is the particular freedom of this model, and one of its omissions.

<!-- @fitness_landscape_politics -->

At the smaller display beyond the field, NOVELTY rewards distance from remembered examples. As the archive changes, a position's novelty can change without that position moving. The machine has to revisit its evaluations. Even here, the past that matters has been given a size and a rule for forgetting.

The display's Corporate, Ecological, Artistic and Meritocratic names are provocations attached to numerical objectives. A caption does not establish that a landscape models any of those systems. We can ask what the comparison reveals without letting the name do the work of evidence.

<!-- @self_organizing_patterns -->

Beyond it, a pattern gathers around another set of controls. Self-organization still has supplied conditions: a space, an update, a way of noticing others. In the next room we can place these supports beside one another.

For now, follow the gold ring. It says: best found under this rule. How much more did you hear in the word?
''')
print('Printed complete PSO lesson and separate reflection; before evidence retained.')
