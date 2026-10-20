from pathlib import Path
R=Path(__file__).resolve().parents[1]; A=R/'commons/artifacts/navigator_noise'; M=R/'commons/maps/SwarmIntelligence_Agent_Based_Modeling_ABM'
O=R/'doc/book/iterations/2026-10-09-navigator-an-imperfect-observation'
files=[A/'navigation_pair.gd',R/'doc/book/studies/forces-point-lineage/point_body.gd',A/'start_point.gd',A/'NavigatorNoise.gd',A/'NavigatorNoise.tscn']
intro='''# The obstacle, the reading, the command

**Optional study inside Agent-Based Modeling · Endless Museum · G2**

**Learning elements**

- True state and observed state
- A decision threshold
- A missing value
- Stop or retain the previous command
- Replay and a defined outcome

The black point returns. Its position, trace and goal-directed movement are familiar. In the lower course it receives an accurate distance to the obstacle. In the upper course we alter that reading. The obstacles stay where they are. Press RUN and follow the point, then read the command beside its path.

Carry the point class, vectors, arrays, conditions and the saved-input comparison from earlier studies. This study adds a small decision boundary between **what is there, what is reported and what is done**. The existing colony remains this hall's primary encounter. The comparison does not reconstruct the colony, teach all of navigation or replace the earlier unfinished ABM tutorial.

## Keep the world; change the reading

Each course has a starting point at x = −1.65 m, a fixed circular obstacle of radius 0.25 m and a goal at (1.65, 0). The sphere radius is 0.14 m. Their surface clearance is the distance from the sphere centre to the obstacle centre, minus both radii. The lower and upper panels display identical model coordinates at different heights; height has no effect on the calculation.

The point initially moves towards the goal at 0.6 m/s. If its reported clearance is at most 0.5 m, it switches to three supplied waypoints around the obstacle. The green squares show the first two; the ring is the goal. These are authored waypoints, not a discovered route. Position and goal direction are known exactly. Only obstacle range is disturbed. The controller turns instantly; it is a kinematic example, not a force or inertia simulation.

In NOISE mode the upper reading is `truth + sigma_m * saved_error`. Forty independent Gaussian draws are saved once, each used for half a second. The sensor is evaluated every 0.05 s, so the **error**, not the true distance, stays constant within a block. A slider changes its scale in metres without drawing new values. Negative readings remain visible. A Gaussian marginal does not make this temporally held process white noise.

In MISSING mode a separate saved uniform draw decides whether each half-second block is absent. The slider now selects a fraction from 0 to 1. This is a probability per block, not a guarantee that precisely that fraction of one run is missing. An available reading is exact; Gaussian error is not mixed into this mode.

Missing is `null`. Zero would mean the surfaces are touching. With STOP, a missing reading produces a zero command. With HOLD, the previous velocity command continues unchanged, including its direction. Neither rule advances the waypoint state while the reading is absent. A point can therefore stop short of the deadline, hit the obstacle, or continue past a turn and leave the course. Those are distinct outcomes.

## Operate the existing study

Press RUN / PAUSE or pull the **lower** point slightly up/down and release. This chooses one common start height, limited to ±0.15 m. Its horizontal and depth movement are constrained; throwing speed is not part of the experiment. The upper point cannot be grabbed separately. All comparisons begin at rest with the same coordinates.

REPLAY restores both agents while retaining the input record. MODE separates range noise from missing readings. FALLBACK chooses STOP/HOLD and explicitly selects missing mode. NEXT SEED creates another record. RESET restores seed1847, sigma0.5 m, missing fraction0.65, STOP and the original release. Changing a setting pauses and resets the paths so the next comparison has a clear beginning.

The readout records the last decision: true clearance before that step, reported clearance, command in m/s, elapsed simulation time and path length. At a terminal state the command is the last requested command; the point has stopped. A green arrow shows an active command. Blue/rose traces contain the actual travelled positions.

Success means reaching the goal within20 simulated seconds without contact or leaving the outlined course. Collision checks the whole movement segment against the obstacle expanded by the sphere radius. This can detect a crossing between endpoints; it is an analytic disc test, not an invisible physics wall. Contact and exit stop at their first boundary. Time is reported at the end of the 0.05 s decision step, so a contact time is quantised to that clock. The experiment stops when both points finish, or at20s. An engine stall can slow the experiment: each callback accepts at most0.1 simulated seconds and reports omitted wall time. It never accelerates the player or alters headset timing.

## Reconstruct inside the museum

Use the prepared Ada project and the declared paths below. The museum supplies the player, camera, lighting, XR Tools and `commons/ui/control_console.gd`. These are the Day Zero host, not new tasks. The point class is carried unchanged; it is printed for completeness. The model, constrained handle, stage and tiny scene wrapper are new. The stage creates its meshes, labels and controls. It has no reference to an unexplained prepared mesh.

Run the wrapper under that host, or attach the stage script to an empty Node3D in a clear museum work area. Do not duplicate the placed exhibit on top of itself. To transplant the code outside Ada, those named host dependencies must also be supplied.

The model separates three functions to read closely: `distance_at` defines the measured variable, `reading` intervenes on it, and `decision` chooses an action. The state list stores where each agent is in the detour. History stores new dictionaries with value-type vectors, so a later update cannot rewrite an earlier step.

'''
parts=[intro]
for p in files:
 lang='ini' if p.suffix=='.tscn' else 'gdscript'
 parts.append('## '+p.name+'\n\nSave as `res://'+p.relative_to(R).as_posix()+'`.\n\n```'+lang+'\n'+p.read_text(encoding='utf-8').rstrip()+'\n```\n\n')
parts.append('''## Predict a different case

Set noise strength to zero. Both full histories should match, not merely their final pictures. Set missing fraction to zero and expect the same result. Set it to one with STOP: the upper point should remain at the start and time out, while the lower reaches the goal. Now raise the shared start by0.15m, replay and check whether your account of clearance still holds.

For a code experiment, retain one correct reading at the start and then make every subsequent block missing. Predict the difference between STOP and HOLD before running. The native tests perform this independent input case: HOLD makes contact, STOP times out without contact. They also test a deliberately overestimated range, a negative reading, a swept crossing and a course exit. A separate mutation check rejects replacing missing with zero.

Do not infer that noise is helpful or harmful from one seed. In the ten recorded seeds1847–1856 at sigma0.5 m, all upper agents reach the goal; some take a shorter path than the conservative accurate-distance route. That does not establish optimality or robustness. Under the same numbered dropout records with HOLD, some make contact, some leave the course and one reaches the goal. This is a small declared fixture set, not an estimated population failure rate.

You leave with a point, a record and a distinction: a changed action can follow from changed information while geometry and policy remain unchanged. A later Machine Learning lesson can change a policy explicitly. Nothing in this study trains, learns or adapts its rule.

The record can be replayed on this engine build. For durable replay across versions, preserve the actual saved noise and uniform arrays as well as the seed, settings and source revision. The review exports both arrays; it does not promise identical RNG output across Godot versions.
''')
(A/'tutorial.md').write_text(''.join(parts),encoding='utf-8')
reflection='''# What reaches the point

The obstacle stays still. The two points leave together. One turns before the other. Look at the number beside the turn: the point acts on a distance it has received. From here you can see the obstacle and the reading at once. The moving point is given only one of them.

Replay the path, then let a reading disappear. The point stops. Choose HOLD and replay the same missing record: now an earlier command continues into a changed situation. The absence has not told it to stop or to continue. We supplied that response. A previous instruction can keep its authority after the conditions that made it useful have gone.

The trace makes these choices remain in the room. A late turn, an early turn and a missed turn leave different lines. Some still reach the same ring. The score asks for an arrival within twenty seconds; it says nothing about whether that was the journey worth making. Even this small claim of success needs a destination, a boundary and someone willing to call time.
'''
(O/'reflection.md').write_text(reflection,encoding='utf-8')
marker='<!-- @navigator_noise -->'
p=M/'tutorial.md'; s=p.read_text(encoding='utf-8')
if marker not in s:
 s+='\n\n'+marker+'\n\n## Optional study — what reaches the point\n\n- True and observed obstacle distance\n- Threshold and waypoint state\n- Missing observation; stop or retain a command\n- Replayed input and measured outcome\n\nThe inherited sphere follows a known course beside the existing colony. Hold the world and starting state fixed; change its range reading, then compare two responses to missing information. The [complete tested companion](../../artifacts/navigator_noise/tutorial.md) prints the model, carried point, constrained handle, stage and scene. This focused addition does not certify the earlier ABM fragments as a complete working program.\n'
 p.write_text(s,encoding='utf-8')
p=M/'final.md'; s=p.read_text(encoding='utf-8')
if marker not in s:
 anchor='The next colony makes one relation particularly clear:'
 assert anchor in s
 addition=marker+'\n\n'+reflection.split('\n\n',1)[1]+'\n<!-- @ -->\n\n'
 s=s.replace(anchor,addition+anchor);p.write_text(s,encoding='utf-8')
(A/'README.md').write_text('''# Navigator Noise — G2

Installed optional comparison in `SwarmIntelligence_Agent_Based_Modeling_ABM`, cell(3,8),180°. Full code and lesson: [tutorial.md](tutorial.md). Review: [museum, images and tests](../../../doc/book/iterations/2026-10-09-navigator-an-imperfect-observation/index.html).

Carry: unchanged `doc/book/studies/forces-point-lineage/point_body.gd`, saved inputs, vector movement, trace. New: true state → observed range or null → chosen command. Same fixed course, goal and authored detour for both agents. No navmesh, raycast sensor, contact solver, inertia, training or adaptive policy is claimed.

The lower point sets both starting heights; release runs. A physical slider and six nearby buttons control replay, range noise/dropout, strength, STOP/HOLD fallback, seed and reset. Sphere geometry/collider inherited; only lower point is a handle. Course collision is a swept 2D disc test using the same radii shown. Agent centre leaving x[−1.85,1.85],y[−.18,.8] ends LEFT COURSE; this is an explicit terminal outcome, not a silent clamp.

20Hz state/sensor updates;40 saved half-second blocks; Gaussian range error in metres OR missing uniform threshold. sigma0–.8m,missing fraction0–1; simulation20s maximum;400 trace records per pair. Gaussian values are not clipped. Missing is null. Last decision values remain after a terminal result. Point radius.14m,obstacle.25m,speed.6m/s;instant turns. Exact positions/directions and detour are supplied knowledge. Rendering panes translate identical model coordinates to two heights; this is a comparison instrument inside the museum.

Native runner: `python -X utf8 tools/test_navigator_noise.py`. Museum runner: `python -X utf8 tools/run_encounter_probe.py SwarmIntelligence_Agent_Based_Modeling_ABM --sequence swarmintelligence --render --probe tools/probes/navigator_noise_room.gd`. Evidence distinguishes core assertions, printed-code reconstruction and native supplied hand poses from physical VR/Quest/student checks, which remain open. Existing room UID/viewport diagnostics are retained in before and after logs.
''',encoding='utf-8')
print('Five full source blocks printed; optional canonical additions written.')
