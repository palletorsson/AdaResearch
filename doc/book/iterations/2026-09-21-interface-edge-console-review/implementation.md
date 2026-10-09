# Edge-of-chaos physical console

21 September 2026. Continues the fitness-console pass. The current QFEP_Edge_Of_Chaos placement uses `comparison_study:on`; both this paired experiment and the single-field variant are covered.

## Encounter

A single backed console sits in front of the field(s), with two physical faders and grouped physical buttons. Lambda is continuous. Speed retains the original eight settings, now represented by eight stops. The paired version includes RESTART, NEW SEED, DT .3 / .15 and HOLD / RUN. The smaller timestep and paused state have persistent button selection feedback.

All labels are flat textures or 2D Labels on viewport surfaces. Single-field title/subtitle and paired timestep captions have framed plates. Fields have frames and supports and remain visible above the console from the captured operating position. The readout shows the actual lambda, access restriction, speed, run/hold state, integrated model time, numbered seed and timestep; the paired experiment also retains its numerical B-field difference.

## Access remains part of the lesson

| Configuration | Lambda hardware | Visitor access |
|---|---|---|
| unlocked | Physical continuous fader | Grab or pointer drag |
| clamped | Fader with bolted bar across the cap | Value held |
| withheld | Riveted blank, labelled NOT FITTED | No lambda handle exists |
| frozen | Held fader at the low preset | Value held |
| chaos | Held fader at the high preset | Value held |

Speed and the applicable action buttons remain usable in every version. The preset names do not claim a measured dynamical regime. In the single-field clamped version, the sign deliberately still advertises UNLOCKED: the contradiction belongs to the original work. Withheld retains its changed title and now states its missing control directly on the console.

Previously a locked slider could move even when the callback ignored its value; the paired version also lacked the visible clamp/blank. These are now actual input restrictions in both variants. Configuration can still set lambda explicitly, matching the existing contract. The held cap and its bracket follow that authored value together.

## Shared components

`commons/ui/physical_parameter_console.gd` composes the existing ControlPanel/buttons with two physical sliders. Set two parameter dictionaries (`label`, normalized `value`, `continuous`, optional `steps`, and `access`: open/held/absent), a title and up to four action labels before tree entry. Owners receive `parameter_changed(index, value)` and `action_pressed(index)` and synchronize state through silent `set_parameter`, `set_action_selected` and `set_reading` calls. The owner supplies the stand and placement.

`physical_stepped_slider.gd` adds an opt-in `input_enabled` construction setting. Disabled handles refuse XR pickup and pointer input. Enabled remains the default, preserving grammar and fitness behaviour. Physics nodes stay at unit scale.

## Verification

`run.py`: 81 passing checks. Includes actual XR Tools grab-driver movement, rays to physics colliders, continuous lambda, stepped speed, pause, reproducible restart, new seed, timestep switching, state readouts, live rebuilds, and all ten combinations of five access states with single/paired mode.

The 64×64 before/after comparison produces identical seeded concentrations and identical coarse/fine fields and model time after 200 ticks. The Gray–Scott equations, boundary conditions, palette, timestep rule, bounded work per frame and pole preroll are preserved. Access-variant checks use a 24×24 field to keep repeated builds inexpensive. Variant screenshots therefore compare access at a common 24×24 resolution; the paired before/after images use 64×64.

`run_regressions.py` runs the grammar and fitness suites into separate folders here. Earlier evidence is preserved. Startup logs still contain unrelated UID/certificate/cache-write messages; the completed tests have no script errors.

## Capture limits

Godot 4.6, Mobile renderer, RTX 3070, desktop test scene. These are actual artifact renders, not museum-hall or headset captures. Before/after paired views share the same camera and state: lambda 0.4, numbered seed 0, model time 60, coarse dt 0.3 and fine dt 0.15.

The console is 84 cm wide, rooted 88 cm above the artifact floor, tilted 55 degrees, one metre in front of the display plane. The operating camera is at `(0, 1.65, 1.85)` with FOV 98. The two displayed fields sit at height 1.65 m. Comfort, tracked-hand reach, raised-furniture placements and standalone Quest performance remain untested.

The next useful step is to test these shared consoles in their actual hall placements, including scaled/raised exhibits, before applying them more widely. Those placement checks should distinguish a geometry problem from an input problem or an intentional restriction.
