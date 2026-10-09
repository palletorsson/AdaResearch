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

## Return: A second together

Halve the rate difference; compare the growing gap with an unchanged phase offset. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses loop, rate, transform. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`paired_time`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-02-gonzalez-torres-a-second-together/index.html). These controls change only the dial state. RESET restores this pair without restarting the hall.

<!-- study-edit:paired_time -->

### One source change: A second together

Change DRIFT_RATIO from 1.04 to 1.02 in paired_time_score.gd. After RESET and DRIFT RIGHT, predict the gap after 30 seconds: 18° instead of 36°. Keep the 12-second base period. Then choose SAME RATE and observe that the gap stops growing without closing.

```gdscript
const DRIFT_RATIO := 1.02
```

Source: `commons/artifacts/spine_studies/paired_time_score.gd`. Use the prepared scene to run and compare.

<!-- paired-time-reference -->

### Compare a rate with an offset

This encounter follows the phase rods and the conveyor in **Forces → Choreography**. The map ID retains the name `Change_Choreography`. Day Zero supplied the repeating update; Change supplied a rate and its accumulation; Oscillation and this hall supplied returning movement and phase. The two dials are an application of that existing toolbox.

Begin with RESET. Each hand makes one turn in twelve seconds. Use DRIFT RIGHT, wait thirty seconds and then reveal READING: the right hand has gained 36°. SAME RATE gives the right hand the left hand's speed while preserving both current positions. The gap stops growing. OFFSET +45° changes only the right position, immediately. ALIGN copies the left position to the right without changing either rate. If their rates still differ, alignment lasts only an instant.

HOLD / RUN pauses these two stored angles, not the player or the museum. READING reveals the current ratio and clockwise phase gap. RESET restores the original angles, equal rates, running state and hidden readout. No controls move the wall or its collider.

The one-line edit above halves the rate difference. Before running it, predict the gap after the same thirty seconds. The relative rate is `(1.02 - 1.0) / 12` turns per second. It gains 0.05 turns, or 18°. At a 4% difference the dials align every 300 seconds; at 2%, every 600 seconds. This is visual alignment modulo a turn, not recovery of a lost history.

### What the program keeps

The production score stores two angles. Each update adds its chosen rate multiplied by the same `delta`:

```gdscript
left_angle = fposmod(left_angle + TAU / PERIOD_SECONDS * delta, TAU)
right_angle = fposmod(right_angle + TAU / PERIOD_SECONDS * right_ratio * delta, TAU)
```

Changing `right_ratio` does not replace either angle. That is why changing speed has no immediate jump. `align()` assigns `right_angle = left_angle`; it has a different job. `fposmod` keeps the displayed angles within one turn. The code discards whole-turn counts, so its readout cannot tell you how many times one dial has lapped the other.

The renderer maps those angles onto identical single-hand dials; all fabrication, pointer controls and the museum player are supplied. Neither dial is a wall clock. They have no independent oscillator, battery or ageing mechanism. Engine stalls advance both through the same elapsed delta; the rate difference is authored explicitly. Full hardware clock synchronization, audio, independent oscillators and lifetime simulation are outside this first edit.


### References and model limits

[Whitney: Felix Gonzalez-Torres](https://whitney.org/artists/3454). The Whitney research led to this artist. This particular paired-clock reference is not presented as a Whitney collection work.

[Foundation: “Untitled” (Perfect Lovers), 1991](https://www.felixgonzalez-torresfoundation.org/works/untitled-perfect-lovers2). The Foundation records two wall clocks and wall paint, ideally installed above head height. Ada uses enlarged single-hand dials and explicit rate controls; it is an original application, not an authorized installation or reconstruction of that work.

[MoMA: “Untitled” (Perfect Lovers), 1991](https://www.moma.org/collection/works/81074). MoMA describes initially synchronized battery-powered clocks, possible drift or stoppage, resetting, and the context of the artist’s partner being diagnosed with AIDS. The digital study models none of that bodily or material vulnerability.

<!-- /paired-time-reference -->
