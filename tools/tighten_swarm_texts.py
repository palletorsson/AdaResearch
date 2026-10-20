"""Apply the 11 October prose revision; preserve every printed code block."""
from pathlib import Path
import hashlib
import json
import re

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-11-swarm-tightened-readings'
seq = json.loads((R / 'commons/maps/sequences/swarmintelligence.json').read_text(encoding='utf-8'))['sequences']['swarmintelligence']['maps']
changes = {}


def source(hall, kind='tutorial'):
    return (O / 'before' / hall / (kind + '.md')).read_text(encoding='utf-8')


def replace(text, old, new):
    assert text.count(old) == 1, old[:100]
    return text.replace(old, new)


def save(hall, text, kind='tutorial'):
    old = source(hall, kind)
    blocks = lambda s: re.findall(r'```[^\n]*\n.*?```', s, re.S)
    assert blocks(old) == blocks(text), (hall, 'printed code changed')
    assert re.findall(r'<!-- student-code:.*?-->', old) == re.findall(r'<!-- student-code:.*?-->', text)
    path = R / 'commons/maps' / hall / (kind + '.md')
    assert path.read_text(encoding='utf-8') in [old, text], ('Unreviewed concurrent edit', path)
    path.write_bytes(text.encode('utf-8'))
    prose = lambda s: re.sub(r'```[^\n]*\n.*?```', '', s, flags=re.S)
    changes[path.relative_to(R).as_posix()] = {
        'before_sha256': hashlib.sha256((O / 'before' / hall / (kind + '.md')).read_bytes()).hexdigest(),
        'after_sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        'before_prose_words': len(prose(old).split()),
        'after_prose_words': len(prose(text).split()),
        'code_blocks_unchanged': True,
    }


h = seq[0]
s = source(h)
s = replace(s, '## Encounter', '## Start here in the museum')
s = replace(s, '## Where the code runs', '''At the live colony's drawing surface, take the black point. Hold its action trigger and move it above the surface; a cyan cursor marks where your hand adds trail. Keep the point's centre 8–70 cm above the surface. Release the trigger to stop writing. PAUSE stops the colony while your hand can still draw; resume to watch the agents read the mark. The wall, table and small surface show the same simulation. A dropped point returns after three seconds.

**Lesson focus:** leave a mark, move away, and see another point respond. The continuous brush is a supplied museum control. The complete six-point study below teaches the underlying read–fade–deposit operation with one deposit per trigger press. It has no diffusion or emitting anchors. Rebuild that focused study; use the live colony to compare what those extra mechanisms change.

## Where the code runs''')
save(h, s)

h = seq[1]
s = source(h)
s = replace(s, '## Encounter', '## Start here in the museum')
s = replace(s, '## Where the code runs', '''Take the black point at the live table's front-right dock. In DRAW mode, hold its action trigger and move it 8–65 cm above the small surface. Your movement writes a direction: gold arrows mark edited cells, cyan arrows retain the starting direction. Staying still writes nothing. Release the trigger and the directions remain. Dropping the point returns it after three seconds.

The nearby controls pause the agents, reset directions, or switch TOUR / DRAW. RESET DIRECTIONS restores a rightward field while keeping the bodies; returning from TOUR to DRAW clears your edits. Pause, draw a turn, then resume and follow one agent across it. **Lesson focus:** you supply a direction that passing agents read without changing. The complete study below isolates this relation with six points and single-cell trigger edits. The walk-in crowd and ant displays are further comparisons.

## Where the code runs''')
save(h, s)

h = seq[2]
old = source(h)
blocks = re.findall(r'<!-- student-code:([^>]+) -->\s*(```gdscript\n.*?\n```)', old, re.S)
assert len(blocks) == 3
code = {name: '<!-- student-code:' + name + ' -->\n' + block for name, block in blocks}
s = '''# Boids — who is near?

## Learning elements

- Select neighbours by distance; exclude yourself.
- Calculate separation, alignment and cohesion.
- Weight and combine steering requests.
- Read one snapshot; commit the next state together.
- Distinguish no request from a request to stop.

## Start here in the museum

Begin at the flocking table with the black hand point and coloured arrows. Pick up the point on the left. Move it left to narrow the perception radius or right to widen it. The gold circles and links show which bodies enter the first boid's neighbourhood. Press the held trigger, or the nearby right button, to pause. Keep the bodies still and change the radius: the neighbours can change without anyone moving.

The hand point controls radius; it is not a member of this flock. Dropping it returns it after 1.5 seconds, keeping the radius and playback state. The original sliders remain available. RESET makes a fresh random scatter.

**Lesson focus:** choose who contributes, then inspect the resulting requests. The aquarium, balcony flock, fish and drone displays are comparisons. Bring PointBody and bounded steering from FlowFields. Replace the supplied direction grid with observations of nearby points.

## Reconstruct the small study

Save `flock.gd`, `study.gd` and the unchanged `point_body.gd` together. Attach `study.gd` to an unscaled Node3D at floor level in a clear 2.7 m square study bay, with access from local +Z. The prepared museum supplies player, camera, lights, XRTools and `res://commons/interactables/push_button.tscn`. These three scripts create the study's six points and display.

The installed table keeps its original thirty-body, sequential, frame-driven model. Its hand control changes that model's radius. Our reconstruction uses six points, fixed steps and one shared snapshot. Here you pick up an actual study point to change its position. These two experiments expose the same neighbourhood question through different controls and declared update rules.

## Choose who counts

`neighbours(i)` returns other point indices less than `radius` cells away. At radius 3.5, point 0 sees points 1 and 2. It excludes itself. The sixteen-cell plane and scale of 0.16 metres per cell return from FlowFields; movement stays on local XZ.

Positions wrap at the edges, but neighbour distances are measured directly across the drawn plane. Two points beside opposite edges may be excluded from each other's calculation. Periodic movement does not automatically create periodic neighbourhoods.

## Three requests

**Separation:** within two cells, sum offsets pointing away, divided by squared distance. Closer neighbours contribute more. Normalise the sum and multiply by `SPEED`. Exact overlap has no away direction, so skip that division; separation does not guarantee collision avoidance.

**Alignment:** average neighbour velocities. Use the actual average as desired velocity, retaining its speed. A zero average requests braking.

**Cohesion:** average offsets to neighbours, then normalise and multiply by `SPEED`. This points towards their local centre. A zero offset contributes no request.

Each uses FlowFields' `(desired - current) / RESPONSE`, capped at `MAX_ACCEL`. Weight the requests, add them and cap again. Separation starts at 1.5; alignment and cohesion at 1. Coloured arrows show weighted requests; white shows the capped combination. Requests can cancel, and a cap can conceal further increases in a weight.

No neighbours means zero acceleration: coast. An alignment average of zero means brake. Keep that distinction from FlowFields' explicit stop direction.

Save `flock.gd`:

@@flock.gd@@

Initially point 0 moves at `(1,0)`. Point 1 is one cell to its right; point 2 is outside separation distance but inside the wider neighbourhood. Separation alone produces a capped acceleration of `(-6,0)`. One step leaves velocity `(0.7,0)`: still rightward, but slowing. A left-pointing correction does not instantly reverse movement.

Both neighbours move at `(0,2)`, so alignment produces `(-2,4)`. Cohesion uses their average offset `(1.5,0.5)`. These requests use different observations.

## Read one moment

`step()` fills next-position and next-velocity arrays before replacing the old state. This returns to Cellular Automata's old/next discipline. No later point reads an earlier point's future. Reversing list order should preserve the physical result apart from rounding.

The installed table and aquarium use other update and boundary choices. This small reconstruction teaches the three-rule relation; its exact trajectories do not predict those exhibits. Its steering is kinematic, not a rigid-body force.

## Move the same points

The study starts paused on separation. RUN advances fixed 0.05-second steps. NEXT RULE cycles separation → alignment → cohesion → all. RADIUS switches 2 / 3.5 cells. RESET BODIES restores positions, velocities and tick, pauses, and keeps the selected rule, radius and weights. Desktop keys are **1**, **2**, **3** and **R**.

Hold any study point to pause all six. Move it across the gold radius and trigger to select it. Release projects it onto the plane and clears its velocity; other velocities remain. Running resumes if it was active. Release all points before resetting. Cyan rings identify neighbours; red, blue and green arrows show the next requests. Their scale is 0.07 metres per cell/s², not a predicted travel distance.

Save `study.gd`:

@@study.gd@@

`record(to_local(...))` keeps coordinates in the study's frame while XRTools holds the sphere under a controller. Leave the root unscaled. The host caps stalled-frame catch-up at half a second. Circles and arrows are explanatory meshes.

## The carried body

Keep your `point_body.gd` from FlowFields. This complete copy is unchanged; the new work belongs to the relation between bodies.

<details><summary>point_body.gd — complete carried file</summary>

@@point_body.gd@@

</details>

## Predict, then check

For exact one-step tests, instantiate `flock.gd` in your test script, set `mode` and call `step()`. Modes 0, 1 and 2 select separation, alignment and cohesion. Start with a fresh instance for each comparison; the study's RUN button advances continuously.

1. Separation: predict velocity `(0.7,0)` after one step. Explain why movement has not reversed.
2. Alignment: predict `(0.9,0.2)`. Independently halve its weight to 0.5 and predict `(0.95,0.1)`. Execute both.
3. Change radius from 3.5 to 2 while paused. Point 0 loses point 2. Separation initially stays the same; the local centre changes. Move another point inside and check the neighbour list.
4. Compare a moving point alone with one beside stationary neighbours in alignment mode. One coasts; the other slows. Explain which input requests braking.

The printed-code checks also cover reversed list order, coincident points and deliberately broken variants. They test this implementation; learner experience and physical headset use need their own assessment.

## Return and carry onward

At the installed table, pause and use the hand point to change radius. Its gold links show the selected neighbours; its arrows preview the first body's next requests. Their lengths are compressed to fit, so read the magnitude labels for exact comparisons. Then observe the open flock from the balcony: its numerical boundary extends beyond the architecture.

Keep PointBody, bounded steering and the shared-snapshot discipline. **The next study sets the three flocking requests aside.** ABM returns to Physarum's trace and adds a searching/carrying state. Boids already is an agent-based model; the new lesson is a state that changes which information the body uses.

The three-behaviour lineage comes from Craig Reynolds's [Boids work](https://www.red3d.com/cwr/boids/). Each implementation makes its own choices about weights, updates and edges.
'''
for name, block in code.items():
    s = s.replace('@@' + name + '@@', block)
save(h, s)

h = seq[3]
s = source(h)
s = replace(s, 'Find the colony display. Watch a point reach food and turn towards the nest. Its position has changed, but something else has changed too: it now carries food. The display\'s ANTS control replaces the population while keeping its field. RESET clears the field as well. Try both after a trail has formed.', '''Begin at the six-point study table on the right near the entrance. Hold a sphere to pause all six; press its trigger to select it. Move it into FOOD, release it and press ONE TICK on the nearby rail. A green cube appears: the same point now carries food. Move it to HOME and step again. The cube disappears and the delivery count rises once.

**Lesson focus:** a stored state changes which information the point uses. The four nearby controls are RUN / PAUSE, ONE TICK, REPLACE AGENTS and CLEAR ALL. The installed table runs the complete lesson printed below. The larger colony, listening court and navigator are comparisons; return to them after testing the two state transitions.''')
save(h, s)

h = seq[4]
s = source(h)
s = replace(s, '## Keep the object; change its information', '''## Start here in the museum

Begin in the twelve-metre field with the blue and rose floor strips. Take the small black point beside the entrance controls: it carries a portable panel, not another colony agent. Its trigger toggles RUN / PAUSE. The four buttons run, step, replace points or clear all. The panel shows the selected agent's SEARCH / RETURN state, the channels it reads and leaves, and its three sensor values.

Hold a large sphere with the other hand and trigger to select it. Holding an agent pauses the colony; release it before stepping or resetting. Holding the panel alone lets movement continue. Drop the panel and it docks after five seconds; regrabbing cancels the return. Both original control banks still work.

**Lesson focus:** watch one state change switch both channels. The ant gallery is a comparison across appearances and scales. The portable panel is supplied museum equipment reading this lesson's model; the complete reconstruction below uses the original end controls.

## Keep the object; change its information''')
save(h, s)

h = seq[5]
s = source(h)
s = replace(s, '## Keep the point; move the memory', '''## Start here in the museum

Begin in the large sphere field. Take the small black grip beside the entrance bank and carry its score panel with you. Its trigger toggles RUN / PAUSE; the six buttons run, step, restart or choose CENTER, EDGE and RIDGE. Select a large sphere with its held trigger. The panel pairs its current coordinate and score with its blue personal-best record and the gold shared-best record.

Holding a candidate pauses the model and blocks stepping, restart and objective changes until release. Holding the panel alone does not pause it. Dropping the panel returns it after five seconds. Coordinates on the panel belong to the search plane, not its position in your hand.

**Lesson focus:** compare where the point is with where it remembers doing better. The smaller NOVELTY display is a later comparison. The supplied panel reads the same records as the original end controls; the complete code below reconstructs the lesson with those controls.

## Keep the point; move the memory''')
save(h, s)

h = seq[6]
s = source(h)
s = replace(s, '## Change the scale of the question', '''## Start here in the museum

Take the small black grip beside the entrance bank. Its portable account has separate PREY and PREDATORS columns: initial, born, lost, supplied, expected, actual and gap. Trigger the grip to run or pause; the four buttons also offer ONE STEP, RESTART and SUPPLY ROW. Select an organism with its held trigger to read its origin and health beside the account.

Holding an organism pauses the model; release it before stepping or restarting. Holding only the panel does not pause it. SUPPLY ROW remains available while a body is held. Omit it and inspect the gap without another update moving the bodies. Dropping the panel returns it after five seconds. The original end controls share the same account.

**Lesson focus:** reconcile the visible population with its recorded changes. The portable view is supplied museum equipment; the complete code below reconstructs the account, observer and original controls.

## Change the scale of the question''')
s = replace(s, 'Zero difference establishes consistency of this count, not a complete account of the ecosystem. Two recording mistakes could also cancel each other.', 'Zero difference establishes consistency of this count, not a complete account of the ecosystem. Two recording mistakes could also cancel each other. Supplied arrivals accumulate in the history, including bodies that later die. The omitted-row gap therefore need not equal the number of living gold-ringed spheres.')
save(h, s)

# Shorten the Boids reflection while retaining its encounters and source notes.
h = seq[2]
old = source(h, 'final')
notes = old[old.index('[^steps]:'):]
s = '''# Three ways to be near

<!-- @boid_manager -->

A flock passes through the wall before you enter. From the balcony you can follow bodies outside the museum. Their numerical boundary reaches beyond the architecture. Hold out your hand: the open flock has no rule that makes it turn towards you.[^containment]

Whatever holds it together, it is not the room and it is not your presence.

<!-- @flocking_controls -->

At the smaller table, take the black point on the left. Pause with its trigger. Move your hand left or right and watch the gold circle narrow or widen. Links disappear and return while the bodies remain still. The steering rules have not changed. Who can enter their calculation has.

Find the ringed boid. Red asks it to move away from bodies too close. Blue asks it to align with nearby movement. Green asks it to approach the local centre. Choose an instant when two disagree and say it plainly: too close here, group centre there, neighbours heading elsewhere.

Resume. Change one weight and follow its arrow before judging the whole flock. A local response can change while the population remains recognisably flock-like. The white arrow combines those requests; it does not promise that the body will immediately travel in that direction. Its movement already has a history.

Craig Reynolds named these three behaviours separation, alignment and cohesion.[^1] No boid receives a plan for the whole flock. Each responds to the neighbours its calculation includes.[^cost] A larger shape becomes visible where those local responses meet.

Move RADIUS again with the weights unchanged. Before asking what the flock wants, ask who each body can notice.

<!-- @boids_aquarium -->

The aquarium offers another edge. Its fish turn below the open rim: an invisible ceiling is written into their coordinates. At the small table, a body leaving one side reappears at the other, suddenly far from its former neighbours. Outside, the open flock passes through the museum walls. Separation, alignment and cohesion do not decide where a world should end. Someone supplied that boundary.

The black point gives your hand a particular authority at the table: change the radius for everyone. The hand has no equivalent place in the open flock. Being able to enter a room is different from being represented in its model.

Alignment is not consent, and cohesion is not a complete account of belonging. These bodies cannot refuse a relation, remember harm or ask for space. Their few geometrical relationships become legible through those omissions.

Let separation win for a while. What does the extra distance let you see? Compare a run without alignment and cohesion with one without separation. How much of the apparent agreement depended on keeping apart?

When you reset, notice what returns. The small table deals a fresh scatter; the tank repeats its seeded start. Even with the same start, timing matters. In a recorded comparison, identical steps kept two schools together; uneven steps sent corresponding fish apart.[^steps] A similar-looking beginning is not yet the same experiment.

![Two tank runs: identical steps agree; uneven steps diverge](/book-images/figures/swarmintelligence/tank-two-runs-part.png)

*Recorded comparison, 25 September. The probe and timing conditions are given in the notes.*

<!-- @ -->

In the next room, the familiar point carries food. The lesson sets flocking aside and asks how a stored state changes what the body attends to. Nearness has given us one relation; it does not have to explain them all.

''' + notes
save(h, s, 'final')

h = seq[0]
s = source(h, 'final')
s = replace(s, 'For a second observation, attend to the route that is fading rather than the route becoming strongest. How long does an abandoned possibility remain available? Imagine an anchor that could be moved by a visitor: the useful experiment would compare adaptation with the persistence of old traces. That control is a proposal for this room’s development.', '''Take the black point at the small drawing surface. Hold its trigger and leave a mark, then let go. The wall and table show the same field. Your hand has joined the agents and anchors as another writer. Pause the colony and draw again: the mark can be prepared while its readers wait. Resume and follow what they do with it.

Attend to a route that is fading rather than the strongest one. How long does an abandoned possibility remain available? Your mark can change what happens next, but the field's spreading and decay decide what remains of the gesture.''')
save(h, s, 'final')

h = seq[1]
s = source(h, 'final')
s = replace(s, 'On the live table, find a direction mark near an agent and predict which way that agent will turn. Follow the automatic tour as an open field gains obstacles, then compare those scenes with wind and noise.', 'On the live table, find a direction mark near an agent and predict which way that agent will turn. Choose TOUR beside the drawing surface. Follow it as an open field gains obstacles, then compare those scenes with wind and noise.')
s = replace(s, 'Physarum’s agents helped write the field they subsequently sensed. These agents receive a field prepared for them.', '''Return to DRAW. Take the black point and move it above the small surface with its trigger held. A direction follows your gesture. Release: the arrow remains for another body to encounter. You can hold the agents still while preparing their next turn. Your authority enters through the field.

Physarum’s agents helped write the field they subsequently sensed. These agents receive a field prepared for them.''')
save(h, s, 'final')

h = seq[6]
s = source(h, 'final')
s = replace(s, 'Read the numbers at the edge of the field. Born. Lost. Supplied.', 'Take the small black grip and carry its account beside a sphere. Read the columns. Born. Lost. Supplied.')
save(h, s, 'final')

(O / 'changes.json').write_text(json.dumps(changes, indent=2) + '\n', encoding='utf-8')
for path, data in changes.items():
    print(path, data['before_prose_words'], '->', data['after_prose_words'], 'words; code unchanged')
