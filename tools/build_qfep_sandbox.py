"""Print and reconstruct Sandbox's explicit sender/receiver lesson."""
import argparse
import hashlib
import json
from build_qfep_introduction import ROOT, STUDY, CARRIED, extract, code

OUT = ROOT/'doc/book/iterations/2026-10-12-qfep-where-the-value-arrives'
HALL = ROOT/'commons/maps/QFEP_Sandbox'
NEW = ['routed_receiver.gd','input_route.gd','sandbox_study.gd','route_checks.gd']

def tutorial():
    return '''# Where the value arrives

**Learning elements**

- A named receiver and an explicit signal route
- Offered values and received values as separate state
- Connecting, cutting and delivering the current value
- An input freeze versus an animation restart
- Testing cause by changing one input at a time

We are inside Endless Museum's Sandbox. Find the two handles, the reactor and CONNECT / CUT. Move LAMBDA while the route is cut. Its number changes; the reactor's used value does not. The orb still moves. Cut input is not stopped time.

Edge of Chaos asked what happened after an update reached a field. Here we step back: did the value reach the intended object at all? Carry the same PointBody, LineSkin and initialized Bench. Bring back the moving cube from Transformation as a small receiver. Its motion makes a held input visible without needing to rebuild the installed reactor's particles and jitter.

## What is carried and supplied

Work in `res://doc/book/studies/qfep-lineage/` in the prepared Ada project. Keep `point_body.gd`, `line_skin.gd` and `bench.gd` unchanged. Their complete printed sources are in [Euclid](../Euclid_Parallel/tutorial.md#carried-files-complete) and [Russell](../Russell_Paradox/tutorial.md). Bench creates the labels, sphere and buttons; its `block` helper makes a BoxMesh as before. The supplied museum provides the player, XRTools and `res://commons/interactables/push_button.tscn`.

The original reactor and its two rails remain. Our working copy reconstructs their delivery rule and two response mappings: lambda selects colour and a speed value; phi lightens or darkens that colour. In the installed reactor, the speed is the maximum launch speed of particles. In our miniature, the same number moves one cube along a one-metre track. This is a deliberately smaller receiver, not an identical particle simulation. It lets us see a connection, retained inputs and continuing motion separately.

## Give the receiver its own state

Create `routed_receiver.gd`:

''' + code('routed_receiver.gd') + '''
`values[0]` is received lambda, between zero and one. `values[1]` is received phi, between minus one and one. They belong to this receiver. The sphere will have another pair of values; those two pairs are the point of the lesson.

The colour branches reproduce this reactor's authored mapping. Lambda moves blue toward green below 0.3, keeps green until 0.5, then moves toward red. Phi changes lightness. These cutoffs are choices in the artwork, not measured boundaries of life or chaos. `speed` returns 0.1 + 0.4 × received lambda. At lambda 0.85 it is 0.44 metres per second. Phi leaves that speed alone.

`advance` applies the familiar distance = speed × elapsed-time relation. `fposmod` returns the cube to the start whenever its distance reaches one metre. That wrap is an authored display convention, not a collision or force. `repeat` clears time and distance but preserves the received inputs. Even lambda zero gives speed 0.1; zero is not a stop switch in this mapping.

## Make the route explicit

Create `input_route.gd`:

''' + code('input_route.gd') + '''
The constructor receives one particular Receiver instance. There is no global lookup and no search for a similarly named object. Creating another receiver elsewhere does not connect it.

`set_value` stores an offered value and emits `value_offered(term, value)`. The signal calls `_deliver`. Its `if connected` is the gate: while cut, the offered value still changes but the receiver gets no update. The signal subscription itself remains in place. CONNECT / CUT names delivery through this route, not whether the interface can hear its own input.

Connecting immediately delivers both current offered values. Otherwise, a control moved while cut would remain stale at the receiver until the next gesture. Cutting changes only the gate. It does not restore defaults, clear the received pair, stop the receiver's clock or replay missed gestures. Reconnecting sends the current pair, not a queue of earlier movements.

`reading` reads the receiver's actual state. It does not relabel the offered pair as “used”. `duplicate` gives KEEP independent copies of both arrays. This snapshot includes connection state, speed, colour, time and distance. It lasts for this run and is not a complete event history or a disk save.

## Put the same sphere at the source

Create `sandbox_study.gd`:

''' + code('sandbox_study.gd') + '''
The same hand-held sphere edits one offered value at a time. LAMBDA selects the unsigned range; PHI maps the same local height to a signed range. Release before selecting another term or pressing a button. The inherited bench returns the sphere to the selected value's height.

The readout separates OFFER from USED. The coloured strip is a diagram of the connection; the signal and conditional delivery implement it. The cube's material reads received values, and its position reads received distance. Neither reads the hand directly. Both the cube and sphere are built once and retained through the experiment.

`_process` first handles any offered input, then advances the receiver, then redraws. Notice that `receiver.advance(delta)` is outside the connection condition. The cube continues moving while cut. REPEAT resets its track clock using its last received speed; it leaves the route and both input pairs intact. No timer, global parameter manager or hidden scene node is required.

## Build and investigate

Open `res://doc/book/studies/qfep-lineage/sandbox.tscn` and press F6. The supplied `sandbox_museum.gd` adapter loads the existing hall and mounts this working bench in a checked location.

1. Start CUT. Select LAMBDA and lift the sphere to about 0.85. Select PHI and set about +0.70. OFFER changes, while USED remains 0.40 / 0.00. Predict the cube's speed: 0.26 m/s. KEEP this disagreement.
2. Press CONNECT / CUT once. USED immediately takes both current values. At lambda 0.85, expect 0.44 m/s. Choose a part of the track and watch the cube return through it.
3. Leave lambda steady. Change phi from +0.70 to −0.70. The cube darkens; speed stays the same. This isolates one mapping instead of assigning every visible difference to the whole pair.
4. CUT. Change the offered pair to 0.15 / +0.60. The cube keeps using its previous pair. Press REPEAT: the cube returns to the track's start, then continues at the held speed. A restart is not an undo of the earlier delivery.
5. CONNECT again. The present pair arrives immediately. Speed becomes 0.16 m/s. REPEAT and watch again. KEEP still holds the earlier offer/used disagreement until you explicitly replace it.
6. Independent task: leave OFFER at 0.90 / +0.50 while USED is 0.25 / −0.50. Do this through the controls, without changing an initializer. Predict speed 0.20 m/s, then explain which connection state makes this possible. What changes immediately if you reconnect?

Return to the installed reactor. Make the same connect/cut comparison with its real rails and read its actual particle maximum speed. REPEAT there restarts the CPU pulse and seeded jitter and restarts GPU emission; it does not promise identical histories for every GPU particle. The neighbouring particle field remains independent. Similar movement in one room is not evidence that both objects received your gesture.

The production study also has a discovery problem our small example avoids: it requires exactly one LambdaSlider and one PhiSlider under the same hall parent and refuses ambiguous or missing sources. Our constructor already names one receiver. These are two ways to make the intended route explicit; neither makes all controls global.

## Test the printed construction

Create `route_checks.gd`:

''' + code('route_checks.gd') + '''
Run `python tools/test_qfep_sandbox.py`. The supplied harness extracts the four new files above and the three carried files from their printed sources. It runs these assertions, synthetic sphere/button actions under a rotated and translated parent, and the independent task. It compares the colour and speed mappings against the installed reactor at several settings. Its controlled animation steps distinguish numerical agreement from screenshots taken at arbitrary wall-clock times.

A rendered probe loads the real hall, uses the actual rail/button signals, checks that the independent field retains its inputs, and mounts the freshly extracted working copy. These are author-operated synthetic tests, not evidence of independent learner understanding or headset comfort.

## Carry onward

We now have a control, a named receiver and an observable connection between them. Keep offered inputs, used inputs and running state distinguishable. In Synthesis the receiver will be a deformable body: inspect which values actually reach its mechanics before interpreting the resulting movement.

**Short instruction:** Carry PointBody + Bench + LineSkin; reuse BoxMesh receiver. Explicit Receiver reference; signal offers L/P; delivery gate starts CUT. Offered pair separate from received pair. Connect sends current pair; cut retains used values; motion continues. L maps colour/speed, P lightness; cube track is a reduced receiver, not particle reconstruction. REPEAT resets clock/distance only. KEEP copies both pairs. Assert isolation, immediate delivery, continued motion, snapshot independence, transformed hand mapping, and installed colour/speed agreement. Next: local controls reaching a deformable body.
'''

def prepare(write=False):
    OUT.mkdir(parents=True,exist_ok=True)
    for name,hall in CARRIED.items():
        content=extract((ROOT/'commons/maps'/hall/'tutorial.md').read_text(encoding='utf8'),name)
        assert (STUDY/name).read_text(encoding='utf8')==content,name
    if write:
        before=OUT/'before';before.mkdir(exist_ok=True)
        for name in ['tutorial.md','final.md']:
            if not (before/name).exists():(before/name).write_bytes((HALL/name).read_bytes())
        (HALL/'tutorial.md').write_text(tutorial(),encoding='utf8')
        baseline=OUT/'preserved-sources.json'
        if not baseline.exists():
            paths=[HALL/'map_data.json',ROOT/'commons/maps/sequences/qfeplaboratory.json']
            paths += [ROOT/'commons/interfaces/qfep'/name for name in ['qfep_reactor.gd','sandbox_wiring_study.gd','lambda_slider.gd','phi_slider.gd','reactive_particle_field.gd']]
            baseline.write_text(json.dumps({p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},indent=2),encoding='utf8')
    learner=OUT/'learner';learner.mkdir(exist_ok=True)
    manifest={'scope':'Fresh printed Sandbox lesson and three inherited files. Hashes use UTF-8 with LF newlines.','files':{}}
    for name in list(CARRIED)+NEW:
        source=ROOT/'commons/maps'/CARRIED[name]/'tutorial.md' if name in CARRIED else HALL/'tutorial.md'
        text=extract(source.read_text(encoding='utf8'),name)
        assert text==(STUDY/name).read_text(encoding='utf8'),name
        (learner/name).write_text(text,encoding='utf8')
        manifest['files'][name]={'source':source.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(text.encode()).hexdigest(),'carried':name in CARRIED}
    (OUT/'extraction.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
    return learner

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write-tutorial',action='store_true')
    print(prepare(parser.parse_args().write_tutorial))
