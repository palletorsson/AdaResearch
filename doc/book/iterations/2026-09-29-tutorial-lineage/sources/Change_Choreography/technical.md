# Timing machines: period, phase and throughput

This hall follows Vectors_Act4b_Oscillation in Forces. It returns to the rate and accumulation ideas from Change. Its primary order is phase_rod_array then conveyor_backlog; the later gravity hall retains its position.

## Twenty rotors

A four-by-five indexed array uses `angle = TAU * frequency * elapsed + phase`. Base frequency is 1/6 Hz. ONE + changes index 9 by PI/4 modulo TAU. WAVE sets phase `(index % 5) * TAU/5`. DRIFT sets indices 10..19 to 1.04 times the base frequency. Relative frequency is 1/150 Hz, so the two groups align every 150 seconds. Controls switch configurations immediately; elapsed time remains continuous. RESET restores equal phases and frequencies, not elapsed zero. RULE toggles the displayed equation. Rotation is prescribed, not simulated by torque. The light rods are visual moving parts above collidable bases.

## The receiver

The existing conveyor_belt scene supplies the visual deck. A new StaticBody3D provides a moving surface, with world-oriented `constant_linear_velocity` of 0.9 m/s. Spawned RigidBody3D parcels have mass 0.5, side 0.44 m, friction 0.75 and bounce 0.05. Continuous collision detection is enabled. Parcel sleeping is disabled so a queue released on a moving static surface resumes contact-driven motion. The belt surface is 1.2 m above the floor; the narrow receiving tray has its floor at 0.45 m. Belt, side rails and receiving tray have colliders. Finite contacts and the physics timestep govern the resulting arrangement.

Feed attempts occur every 1.2 seconds. Each collection pulse removes at most the oldest live parcel whose local x is at least 2.9 m and whose centre has dropped below 1.12 m into the tray. The receiver intervals are MATCHED 1.2 s, BACKLOG 3.0 s, RECOVERING 0.6 s. A pulse with no arrived parcel does nothing. Entering a receiver mode restarts its interval timer; it does not reset the feed timer or existing parcels. RESET clears parcel bodies and local counts, restores matched operation and preserves elapsed time.

`admitted - collected == boxes.size()` is the accounting invariant. Admission pauses if the inlet is occupied or the 48-body cap is reached. Capacity is shown on the console. The experiment is bounded; it is not an unlimited source of physics bodies. Parcels are rigid bodies, not XR pickables, and the pile is not a certified climbing route.

## Review

Compare one phase offset before a phase wave, then frequency drift. Compare actual transport under matched intervals, backlog and recovery. Desktop scripted-pointer and physics tests accompany the first implementation. Headset reach, hand interaction, label comfort and live performance remain to be walked.


<!-- study-spine:paired_time -->

## Installed application: A second together

`paired_time` occupies a new adjoining bay, after the existing encounters. Cell [12, 36], rotation 180°, museum adapter `res://commons/artifacts/spine_studies/paired_time.tscn`. Original response to Felix Gonzalez-Torres; no claim of exact reconstruction.

Halve the rate difference; compare the growing gap with an unchanged phase offset. Reuses loop, rate, transform; adds no prerequisite node. The display and main-player controls are supplied.

<!-- paired-time-reference -->

### Paired-time implementation

`paired_time_score.gd` is the state model: two scalar angles, a 12-second base period, a right-rate ratio, and a local pause flag. `advance(delta)` accepts finite positive elapsed seconds and wraps each accumulated angle within TAU. Both dials share the engine delta; no random hardware drift is claimed. `paired_time.gd` constructs two matching 1.94-metre dials with 60 marks each, above a solid display wall, and rotates only their hand nodes. Readout updates reuse the labels and meshes. The station supplies seven pointer controls; it adds no player or camera.

Tests exercise no-jump rate changes, retained phase at equal rates, alignment without rate changes, deliberate phase offset, local hold/resume, reset, equal elapsed time at 30 and 144 updates per second, invalid elapsed inputs, bounded long updates, native museum captures and side-route support. Pointer dispatch is tested; physical XR comfort and Quest frame time remain unverified.


### References and model limits

[Whitney: Felix Gonzalez-Torres](https://whitney.org/artists/3454). The Whitney research led to this artist. This particular paired-clock reference is not presented as a Whitney collection work.

[Foundation: “Untitled” (Perfect Lovers), 1991](https://www.felixgonzalez-torresfoundation.org/works/untitled-perfect-lovers2). The Foundation records two wall clocks and wall paint, ideally installed above head height. Ada uses enlarged single-hand dials and explicit rate controls; it is an original application, not an authorized installation or reconstruction of that work.

[MoMA: “Untitled” (Perfect Lovers), 1991](https://www.moma.org/collection/works/81074). MoMA describes initially synchronized battery-powered clocks, possible drift or stoppage, resetting, and the context of the artist’s partner being diagnosed with AIDS. The digital study models none of that bodily or material vulnerability.

<!-- /paired-time-reference -->
