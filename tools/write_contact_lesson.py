"""One-time authoring of the contact lesson. Do not rerun over later edits."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
M=R/'commons/maps/SoftBodies_Obsticals_Part2'
S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Obsticals_Part2'
def block(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf-8').rstrip()+'\n```'
t='''# Same fall, another encounter

## Learning elements

- Describe a comparison as two cases
- Change one coefficient while retaining the shared construction
- Rebuild starting conditions instead of resetting only the clock
- Keep a timed observation while the bodies continue

The last hall gave matching panels a pressure command. Keep those panel and PointBody classes. Here we remove the panels' pins, turn them flat and let them fall onto two copies of the black point. Both drops begin alike. Only their damping coefficients differ.

## Find a comparison in the museum

<!-- @softbody_gallery_part2 -->

The existing gallery contains twelve named encounters. High Drag gives a sphere more damping; Corner Strike changes where it meets a collider. Other cells change shape, stiffness or pressure together. Looking across the array can suggest a question, but it does not isolate its cause.

The desk's REPLAY reconstructs the group with seed 1337. VARIATION toggles additional changes to stiffness and pressure; GROUP selects another set. A seed repeats the chosen inputs to the random generator. It does not rewind a body or guarantee identical physical trajectories on every machine.

For our smaller comparison, there is no random input to seed. We can state the two cases directly.

## Two cases, one construction

Continue in the prepared Endless Museum: player, floor, camera, XRTools and Jolt already exist. Keep the previous `pressure_panel.gd` and `point_body.gd` beside the new `study.gd`. Attach the host to a unit-scale Node3D in a clear area. The complete inherited files are below.

`CASES` is a list of two dictionaries. Each dictionary names a case and supplies its damping coefficient. Everything else comes from the same panel constructor: mesh, mass, stiffness, pressure, solver setting and material. The two bays are simply separated so their bodies cannot collide with each other.

The old perimeter pins would prevent a fall. The host unpins them on both new panels, then rotates each panel by a quarter turn. Pressure remains zero; there is no sine driver in this experiment. Both black points have the same sphere mesh and collision shape. Their small offset places each point beneath a vertex in the panel's existing grid; it is part of the shared contact setup.

<!-- HOST -->

## Run and touch

The first pair drops when the study starts. Watch it from the side. Use **1** to repeat. In VR, grip either black point, press its trigger, then release it. The trigger requests a replay; releasing returns both points to their declared places before the new drop begins.

You can still move a point against a panel. Doing so interrupts the measured comparison and clears its readings: your hand has added another changing condition. Trigger and release when you want a fresh trial. A queued replay waits until neither point is held. The program never drags a held point back to its parking place.

`replay()` removes the two old panels from the world and constructs fresh ones. It clears the recorded results and starts the clock again. The PointBody instances remain. Resetting only `elapsed` would leave the existing folds and motion in place, giving the second attempt a different beginning.

## Keep one observation

At the first physics step reaching 1.5 seconds, the host reads each panel's vertex positions. It records the highest minus the lowest height in the study's coordinate frame. This is a vertical extent in metres, not volume, material quality or distance travelled. Keep the host upright and at unit scale.

`get_point_transform()` supplies world positions. `to_local()` brings them into the same reference frame before comparison. The value stays on the caption while the panels continue moving. Sampling does not freeze their physics.

Compare several fresh trials. More damping is expected to reduce motion, but contact, gravity and folding also affect the height at one chosen time. A different height is an observation to investigate; it is not a direct reading of damping. Keep other moving objects and your hands clear during the measured run.

## One independent change

Change B's damping from **0.6 to 0.1** and restart. Before running, predict what now matches: both recipes, contact shapes, initial orientations and release heights. Predict similar readings under the same conditions, rather than promising exact equality across all computers. If a difference persists, check the starting construction, environment and timing before adding another explanation.

You have a repeatable procedure and a small record of its outcome. In the next hall, we will ask what happens when a selected reading or a stopped surface comes to stand for the whole event.

<details>
<summary>Inherited pressure panel — unchanged; this host releases its pins</summary>

<!-- PANEL -->

</details>

<details>
<summary>Inherited grabbable PointBody — unchanged</summary>

<!-- POINT -->

</details>

The installed gallery remains a larger collection of possibilities. This learner study isolates one comparison using the objects you already constructed; it does not rebuild all twelve exhibits.
'''
(M/'tutorial.md').write_text(t.replace('<!-- HOST -->',block('study.gd')).replace('<!-- PANEL -->',block('pressure_panel.gd')).replace('<!-- POINT -->',block('point_body.gd')),encoding='utf-8')
f='''# Same fall, another encounter

<!-- @softbody_gallery_part2 -->

Twelve encounters wait in an array. A sphere meets a cube; another body catches a corner. One folds around its support, another falls beside it. The regular spacing makes them look ready to compare. What has actually been kept the same?

Names arrive before contact. High Drag invites us to expect resistance. Vacuum begins with the same zero pressure used as the gallery's default: its name supplies an event the setting has not specified. A familiar word can organise what we see before we have looked at what the body does.

Choose two cells. Their surfaces may differ because of material settings, contact geometry, starting position, or several of these together. The array gives these differences equal places without giving them equal explanations. We can enjoy their abundance and still be precise about the claim a comparison can support.

REPLAY makes another beginning from the declared recipe. It replaces the bodies that fell; it does not persuade their folds to become innocent again. Move a point into the next fall and your hand enters the conditions. What seemed like an inconsistency may be evidence that something else participated.

An awkward fold can hold attention longer than the intended demonstration. There is no need to make it prove a defect in the body. Walk around it. Notice the support, the mesh and the moment at which you started looking. A body can exceed the name we gave its cell while remaining entirely consequential.

To isolate one difference, we temporarily narrow the encounter. That choice makes a question answerable, and leaves other questions outside the experiment. The limit belongs to the comparison. It need not become a demand that every body meet the same conditions or yield the same result.

A number taken at one moment can remain while its subject continues changing. In the next room, the kept result begins to look like the object itself.

<!-- @ -->
'''
(M/'final.md').write_text(f,encoding='utf-8')
(M/'technical.md').write_text('''# Contact — source and learner implementation

The placed `algorithms/softbodies/softbody_gallery_part2.tscn` runs `softbody_test_gallery.gd` with gallery_part=2, selecting cases 13–24 of the shared list. `#lesson:true` selects 3 columns at 4 m spacing, seed1337, no respawn and no coefficient jitter. The contact desk disables the root frame callback, so ongoing deflation and label following are also disabled. Physics continues.

Current defaults are mass1, stiffness.5, damping.01, precision7, pressure0. Named cell overrides follow; optional lesson_variation adds seeded stiffness/pressure jitter, then a random hue. High Drag overrides damping to.8. Vacuum's pressure0 repeats the default. Caving Sphere requests stiffness.2 and pressure−.5, but the native engine reports pressure0. Its precision7 is the same as the default. The old final.md claim that only that cell used seven passes was stale. No calibrated fluid or material behaviour follows from these names alone.

The shared desk supplies REPLAY, VARIATION, GROUP, HOLD, RELEASE and RULE. HOLD asks every mesh entry to be pinned; RELEASE restores saved selections. These are existing gallery controls, not the learner's replay mechanism. Consult the native receipt for measured motion rather than interpreting the button name as proof that the surface froze.

Learner files: `doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Obsticals_Part2/`. pressure_panel.gd and point_body.gd are unchanged from the pressure lesson. The new host releases every panel pin before entering the tree, rotates each panel90deg aboutZ and drops both fromy2.1 onto matching PointBody spheres aty1.1. Sphere offsetsx=.6/7,z=.1 align with the inherited grid. Cases differ only in damping .1/.6. A timed sample keeps local vertical extent, using all world vertex positions transformed into host coordinates. This is an axis-aligned extent, not volume. Body samples continue simulating after measurement.

Key1 or grip/trigger/release queues replay. Held points interrupt and clear the comparison; replay waits for both hands to release. Rebuild detaches old panels before adding new ones, retaining point instances and restarting time. Independent edit sets B damping to.1. Complete code is printed in tutorial.md; no hidden scene mesh references. The learner study is temporarily mounted for review, not registered as an extra museum artifact.

Use unit-scale upright hosts and keep other bodies clear during comparison. A declared setup is reproducible; cross-machine bitwise solver replay and physical headset/Quest performance are not claimed.
''',encoding='utf-8')
print('Contact tutorial, reflection and technical account written.')
