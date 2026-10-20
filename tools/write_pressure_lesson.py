from pathlib import Path
R=Path(__file__).resolve().parents[1]
M=R/'commons/maps/SoftBodies_Obsticals'
S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Obsticals'
O=R/'doc/book/iterations/2026-10-09-pressure-a-drive-and-a-room'
def write(p,s):p.write_bytes(s.encode('utf8'))
def block(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```'
t='''# Pressure — a drive and a room

## Learning elements

- A closed surface receives internal pressure
- Map a sine wave to a nonnegative pressure coefficient
- Separate amplitude, rate and material response
- Hold a drive without freezing its recipient

Carusell moved the attachments of your sheet. Here the attachments stay and a pressure coefficient changes. Keep the same black PointBody. Return to the closed box from the first Soft Bodies lesson: flatten it into a small panel, then place two copies opposite each other.

## Meet the existing walls

The museum's pink slabs already receive a periodic pressure command. Watch one fixed point and one free part of a surface. Use AMPLITUDE, RATE and HOLD DRIVE on the nearby desk. Holding the drive retains its last pressure; the physics simulation continues. RESET PHASE changes the drive's clock, not the body's history.

The installed walls are not identical samples. Their authored stiffness, shrinking settings and selected pins differ. A shared pressure command does not make their responses a controlled comparison of one parameter. The small learner model below deliberately starts its two panels with matching settings.

## Close the surface

An open cloth sheet does not enclose an interior. A thin BoxMesh does. Its six sides remain a closed surface even when the object looks almost flat. We reuse the coordinate test from Cloth Physics to pin the top, bottom and ends; the broad faces can deform between those boundaries.

Save `pressure_panel.gd` beside the unchanged `point_body.gd`. This is the same construction pattern as the yielding cube, with dimensions and a perimeter pin rule chosen for a wall. Mesh and pins are prepared before the body enters the physics world.

<!-- PANEL -->

## Drive pressure

Save `study.gd` beside those files and attach it to a unit-scale Node3D in an open area of the prepared Endless Museum. Player, camera, floor, XRTools and Jolt are already supplied. This is a small two-panel study you can reach around; it does not replace the installed architecture. The inherited point file is printed below.

`sin(phase)` runs from −1 to 1. Adding one and halving gives 0 to 1. Multiplying by `amplitude` gives 0 to that chosen maximum. At phase zero the pressure is half the maximum. The coefficient is an engine control, not a calibrated value in pascals.

`rate * delta` advances phase in radians. Rate controls the period; amplitude controls the input range. Neither number specifies how far the surface must move. This host updates the command on physics steps; the installed scene uses its frame callback. Both leave vertex motion to the solver.

<!-- HOST -->

## Hold the command

Grip the familiar black point. Its held trigger toggles HOLD DRIVE. You can still move the point and press it slowly against a panel. Releasing parks it at the opening. The point is a contact probe and a switch; its position is not mapped to pressure.

Desktop controls: **1** changes amplitude; **2** halves/restores the base rate; **3** holds/resumes the phase; **4** changes stiffness on both panels; **R** sets phase to zero. The installed desk uses its own presets. Read the value before comparing.

Hold near the pressure peak and watch. A constant pressure can still produce motion while the body responds. The program never pins all vertices or disables physics to make HOLD appear successful. Changing amplitude while held immediately changes the pressure at that same phase; holding the clock does not lock every control.

Use RESET PHASE while held. Pressure returns to half the current amplitude. The same panel objects and their current shapes remain. Resetting the signal is different from rebuilding its recipient.

## One independent change

Change `AMPLITUDE` from 0.5 to 0.25 and restart. Predict the pressure at phase zero, π/2 and 3π/2: 0.125, 0.25 and zero. The period remains `TAU / RATE`, about 6.28 seconds with RATE 1.0. Keep geometry, pins, stiffness and damping unchanged.

You halved the commanded pressure. Does the gap between the panels halve? Measure or watch before answering: their response also involves geometry, constraints, material settings and accumulated motion. A pressure value is not a clearance measurement.

The contact gallery and flag dancer remain further encounters in this hall. The tutorial follows one drive into two known bodies. In the next hall, we will control the starting conditions of a contact experiment so that a comparison can be repeated.

<details>
<summary>Inherited grabbable PointBody — unchanged</summary>

<!-- POINT -->

</details>

Source: the installed `breathing_room.tscn` uses `breathing_room_scene.gd`; the sibling `breathing_room.gd` builds a different, unused room. See [Godot's SoftBody3D pressure property](https://docs.godotengine.org/en/4.6/classes/class_softbody3d.html#class-softbody3d-property-pressure-coefficient) and [BoxMesh](https://docs.godotengine.org/en/4.6/classes/class_boxmesh.html). Jolt supplies the simulation; the complete construction and pressure command are printed here.
'''
write(M/'tutorial.md',t.replace('<!-- PANEL -->',block('pressure_panel.gd')).replace('<!-- HOST -->',block('study.gd')).replace('<!-- POINT -->',block('point_body.gd')))
old=(O/'before/commons/maps/SoftBodies_Obsticals/final.md').read_text(encoding='utf8')
tail=old[old.index('<!-- @softbody_gallery_part2 -->'):]
f='''# The room has a body

<!-- @breathing_room -->

Two pink slabs make a passage. Stand where their fixed points and moving surfaces remain visible together. The walls receive the same rising and falling pressure, but they do not meet it as identical bodies. Their attachments and material settings were chosen differently. Before entering, watch a complete cycle.

AMPLITUDE changes the range of pressure. RATE changes the pace of its repetition. HOLD DRIVE keeps the last command in place while the surfaces continue responding. A held instruction can have consequences that are still moving. RESET PHASE takes the clock back to the beginning; it cannot take the encounter back with it.

The earlier sine spaces gave a position to each part. Here the wave supplies a condition. The place the surface reaches is produced through that condition, its attachments, gravity, contact and what the preceding movement has left behind. The shape is not waiting inside the sine to be revealed.

Calling this breathing invites a bodily recognition. Nothing here needs air, and no sensor decides when the room should inhale. Yet a change in the space around you can make your own breathing noticeable. The resemblance can affect you without explaining the mechanism.

Change STIFFNESS and return to the same pressure. The command is familiar; its reception has changed. How much room remains is not written on the amplitude control. We have to look at the surface and at the body trying to pass it. What a container permits depends on more than its outline at rest.

<!-- @ -->

'''
write(M/'final.md',f+tail)
write(M/'technical.md','''# Pressure — source and learner implementation

Registry scene `algorithms/softbodies/advanced_concepts/breathing_room.tscn` runs `breathing_room_scene.gd`. With `#lesson:true`, `_process` advances `_time` by `breath_speed * delta` and sets both walls' pressure to `(sin(_time)+1)*.5*breath_amplitude`. The separate `breathing_room.gd` generator is not the script on the placed scene.

The authored BoxMesh is 1 × 4 × 7 m, subdivided 2/6/6. Centres are x −2.3185759 and 3.5541987; y 1.9500841 and 1.9902142. There are 19 and 16 explicitly listed pinned indices, rather than every perimeter vertex. Default/second stiffness .5/.02; shrinking factors −.2/.02. The lesson pressure driver overwrites their initial .08/.105 coefficients. The map selects flesh material. These unequal starting settings prevent treating the pair as an identical-material comparison.

Desk: AMPLITUDE .5/.15/.9, RATE 1/.4/1.8; HOLD DRIVE disables only the root frame callback; STIFFNESS writes .5/.2/.8 to both walls; RESET PHASE writes zero then applies the command at that phase. Neither operation rebuilds the walls. The first click advances each preset index.

Learner files: `doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Obsticals/`. The closed panel is a BoxMesh .16 × 1.2 × 1.8 with perimeter pins prepared in `_init`. Two matching instances receive one pressure command at physics cadence. Same PointBody as Carusell; trigger holds/resumes phase. No scene-path mesh dependencies. Full code is printed in tutorial.md. Independent amplitude edit .5→.25 changes input range, not rate or geometry. The model is temporarily mounted for captures, not a new permanent exhibit.

API: https://docs.godotengine.org/en/4.6/classes/class_softbody3d.html . Test receipts and actual museum captures are in the matching pressure review. Physical headset/Quest and independent student understanding remain untested.
''')
print('Authored pressure lesson and corrected installed-scene account.')
