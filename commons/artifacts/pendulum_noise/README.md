# The same release / a recorded push

An optional comparison in **Vectors_Act4b_Oscillation**, between the existing spring row and swings. Pull either black point, then let go. Both pendulums start from the same angle with zero angular velocity. They remain attached. Sideways depth and throwing speed are deliberately excluded from this release control.

## Two comparisons

**OFF / ON:** A receives no external push; B receives the saved horizontal force. Both have tangential drag coefficient 0.35 kg/s. The input lasts four seconds; the motion continues to twenty.

**SAME INPUT / DIFFERENT DRAG:** Both receive exactly the same force record. A retains 0.35 kg/s; the B DRAG slider changes B. Moving that slider selects this mode explicitly and resets the comparison. MODE switches between the two comparisons. Each control change pauses at a common release; REPLAY starts again.

The other controls are force strength, RUN / PAUSE, NEXT SEED and RESET. RESET restores seed1847, force standard deviation2N, B drag1.2kg/s, release0.6rad and OFF/ON. One hand controls the release at a time. The controls are nearby; they do not modify the player or camera.

## The model and its lineage

The point inherits the unchanged sphere/collider/pickup class from `doc/book/studies/forces-point-lineage/point_body.gd`. The constraint follows the museum's existing late-physics projection pattern in the mower and spring handle. The angular update follows the velocity-first pendulum already used by PendulumWave; it is a small separate model, not an alteration of that artifact.

This is a planar point-mass pendulum with a massless rigid rod: mass1kg, length1.1m, gravity9.8m/s². Angle is measured from vertically downward; the external force acts horizontally in the apparatus's local X direction. Tangential linear drag is `-b * speed`. Dividing the tangential force by mass and length gives:

`angular_acceleration = -(g/L)*sin(angle) - (b/m)*angular_velocity + F*cos(angle)/(m*L)`

The cosine matters: a horizontal push is not always tangent to the swing. Each 1/120s step updates angular velocity before angle. This is numerical integration, not an exact trajectory. The rod's length is an analytic constraint; it is **not a Jolt joint or a contact simulation**. The frozen pickable provides the hand interface, not the dynamics. The surrounding force hall still contains its existing physical joints and springs.

## What is recorded

A local generator draws forty independent Gaussian values once. Each is held for0.1s and scaled by the force standard deviation in newtons. After four seconds the force is zero. Holding a sampled value gives temporal structure; this is not continuous ideal white noise. Gaussian samples are not clipped and are not bounded by their standard deviation. Changing strength preserves the record; changing seed replaces it.

Replay restores angle, angular velocity, model clock, accumulator, history and metrics. Reproduction requires the same code, numerical configuration and generator version. Retain the actual force array for a durable record across engine changes; Godot identifies its generator algorithm as an implementation detail. [Godot4.6 RNG documentation](https://docs.godotengine.org/en/4.6/classes/class_randomnumbergenerator.html)

The trace stores601 snapshots, including the initial state, at30Hz during twenty model seconds. Measurements inspect every120Hz update. The blue/rose floor plot shows angle against time; gold shows the forty input values over four seconds. Plot ranges are explicitly clipped at±π radians and±12N; the simulation and metrics remain unclipped. Nearby arrows show the current applied force, with0.12m of drawn arrow per newton; those arrows do not show net force.

**Peak** is the largest absolute angle since release. **Settled at** is the first sampled time after the last observed tolerance violation following force cutoff, reported only after completion and at least one final second inside both limits: absolute angle≤2° and angular speed≤0.05rad/s. It concerns this observed window. It does not predict the response to another push. A dash/pending state during the run is not a failed calculation.

At most0.1 model seconds advance per engine callback. Longer stalls omit wall time and report the amount. The experiment does not change physics tick settings, slow the headset or hide a jump by clipping the state. There are at most64 in-memory event receipts; nothing automatically saves a visitor's gestures permanently.

## Evidence and limits

Native core and installed-room receipts accompany the [museum report](../../../doc/book/iterations/2026-10-09-pendulum-a-recorded-push/index.html). Tests include known force projections, replay equality, zero-input identity, same-input identity, independent measurements, extreme controls across three seeds, a small-angle period reference, controls and supplied XR pickup/release poses. Physical headset use, Quest performance and an independent student remain untested.

Default OFF/ON peaks are0.6 and0.7412484rad. Neither is settled by the defined criterion within20s. With the same input and B drag1.2kg/s, B meets the terminal-window criterion at5.05s; A does not within20s. This is one recorded experiment, not a general claim that increased damping always settles faster. In the separate undamped, tiny-angle check, maximum relative energy discrepancy is about1.26% over20s: the finite integration step remains visible.

Run `python -X utf8 tools/test_pendulum_noise.py` and `python -X utf8 tools/run_encounter_probe.py Vectors_Act4b_Oscillation --sequence forces --render --probe tools/probes/pendulum_noise_room.gd`. The companion [tutorial](tutorial.md) prints the exact implementation and inherited point class. The existing museum supplies XR Tools, ControlConsole, environment, camera and player.

Next: retain the comparison contract when an agent receives an imperfect observation. A changed physical response here does not establish feedback control, learning, fuzzy inference or stochastic resonance.
