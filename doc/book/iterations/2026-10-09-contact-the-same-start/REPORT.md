# Same fall, another encounter

Soft Bodies **5 of 9**. The previous hall distinguished a pressure command from a responding surface. This hall makes a smaller comparison: reuse that panel and PointBody, remove the pins, and change one coefficient. The next hall will examine what a selected reading retains.

|Part|Before|Now|
|---|---|---|
|Tutorial|Three setting assignments; no full construction|Complete host plus the two unchanged inherited classes|
|Comparison|Select two gallery cells, often unlike in several ways|Two matching drops; damping .1 and .6|
|Replay|Seed discussion|Reconstruct panels, retain points, clear readings and restart time|
|Hand interaction|Installed gallery controls|Holding a point interrupts the trial; trigger queues a replay until release|
|Transfer|Open observation|Set both damping values to .1; compare fresh trials|
|Reflection|Names, folds and the array|What a comparison can establish; the hand as an added condition; a kept number and a changing body|
|Room|Desk in centre arrival|Same desk at (11,5), clear entrance and supported route|
|HOLD control|Invalid pins and a surface that kept moving|Referenced mesh entries attached in place; original attachments restored on release|

## What the learner carries

`pressure_panel.gd` and `point_body.gd` are byte-identical to the previous hall. The host removes the panel's perimeter pins and turns it horizontal. Both copies retain the same mesh, mass, stiffness, pressure, material and solver setting. Two matching black points remain grabbable contact objects. They are instances of the carried class, not a claim that one object is literally in two places.

At the first physics step reaching 1.5 seconds, the host stores maximum minus minimum local vertex height. That is a vertical extent, not volume or a material diagnosis. The values remain while the surfaces continue. A held point cancels the measurement; a queued replay waits for both points to be released. Keyboard **1** follows the same path. R is avoided because the existing gallery uses it to reload the scene.

## Native evidence

**30 code/control checks and 33 museum checks passed.** The code test extracts all three visible blocks from tutorial.md, checks source parity, and runs them under Godot 4.6 with Jolt. It also runs the complete equal-damping edit. Behavioural checks reject three faulty hosts: clock-only reset, a hidden mass change and measuring through a hand interruption.

The tests verify real falling vertices, local/world conversion under a translated and rotated parent, retained point identity, replaced panel identity, original pin restoration and actual contact. Removing the point collider from an otherwise matching drop changed the sampled geometry by up to 1.177 m in the paired native fixture. The solver continues after a reading is kept.

|Run|A height (m)|B height (m)|Damping|
|---|---:|---:|---|
|Isolated printed program|0.3007|0.5767|.1 / .6|
|Isolated independent edit|0.4096|0.3130|.1 / .1|
|Inside the museum|0.4124|0.5491|.1 / .6|
|Museum independent edit|0.4124|0.4124|.1 / .1|

The equal settings did not produce equal heights in every fixture. These observations are retained, rather than replaced with a promise of deterministic replay. The tests establish the declared construction and operation; they do not establish that damping alone explains every resulting fold. Contact sensitivity and numerical conditions require further experiments if that stronger claim is wanted.

## A repair found through use

The first real pointer test found invalid Jolt pin indices when HOLD visited unused mesh entries. The first specimen also moved 1.012 m during the hold observation. The repaired control uses only indices referenced by the mesh and attaches the current points to a fixed anchor. RELEASE restores the original pin indices, attachment paths and offsets. Replaying or switching groups clears the old hold first. The repaired native hold drift measured 0.000000 m; regression checks also cover an existing attachment and repeated HOLD.

This follows the engine's distinction between mesh entries and physics vertices, and its spatial-attachment mechanism. [Godot 4.6 Jolt source](https://github.com/godotengine/godot/blob/4.6-stable/modules/jolt_physics/objects/jolt_soft_body_3d.cpp), [SoftBody3D attachment source](https://github.com/godotengine/godot/blob/4.6-stable/scene/3d/physics/soft_body_3d.cpp).

## Source precision

The installed part-two scene runs the shared `softbody_test_gallery.gd`; it has twelve cases, three columns and four-metre spacing. The lesson disables added coefficient jitter, respawning and the root callback that performs ongoing deflation. All twelve bodies report precision7. Vacuum's zero pressure repeats the default; Caving Sphere requests negative pressure but the engine reports zero. Names cannot establish a physical phenomenon by themselves.

## Space and review scope

The entrance obstruction was the existing desk. It is moved from (15,3) to (11,5). The native probe checks its reachable controls and 361 quarter-metre samples along an outer route with floor support and capsule clearance. The first proposed crossing intersected a stick's collision body; the final path passes ahead of it. This checks one route, not every possible path through moving specimens.

The learner pair is temporarily mounted at hall-local (23,0,26), yaw180, unit scale, in the actual museum. Screenshots include the encounter, trial, retained reading, hand interruption, independent edit and hall from above. The source gallery, exhibits and sequence order are retained; no permanent duplicate tutorial exhibit is registered.

The final runs contain no script, parse, missing-space or invalid-pin errors. Existing UID and compatibility-renderer warnings remain in the logs. Input uses the real desktop pointer and synthetic XRTools controllers; physical headset input, Quest performance and an independent student's understanding remain untested. The HTML's links and displayed code are checked; browser layout was not automated.

Next: **SoftBodies_Playground_of_Joy — the reading and the event.**
