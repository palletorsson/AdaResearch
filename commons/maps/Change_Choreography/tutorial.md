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
