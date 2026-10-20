# A doorway reads your approach

**Installed in Godot's Endless Museum → Shaders → Patterns.** After the sphere with overlapping fields, the next object responds to your own movement. Fourteen ribs open outward as you approach slowly and curl inward as you approach quickly. You can walk through either state.

![Slow approach: ribs open outward](museum/doorway-slow.png)

## From the hand to the body

The sphere asks where an object belongs. The doorway asks how a visitor is approaching. It measures distance and approach speed, gives each a degree, and combines three rules: near-and-slow opens, near-and-fast curls, far rests. At intermediate values, both responses contribute.

This adds a second input to the earlier field study and makes the visitor part of the experiment. The form changes while you approach it; stopping changes the reading again.

## The rule is a choice

Press **SWAP RULES** and the same fast input opens the ribs. Slow movement now curls them. Nothing about speed itself required the original response. Someone assigned it.

The doorway measures motion, not character, intent or identity. Its apparent welcome or hesitation comes from our choice of thresholds and transformations. Making the response gradual does not make that choice disappear.

![Fast approach with the original assignment](museum/doorway-fast.png)
![The same fast input after swapping the rules](museum/doorway-fast-reversed.png)

## Use the installation

Walk up, stop, pass through and return. **REACH** changes how close counts as near; **PACE** changes how speed is graded. The nearby console has native rectangular buttons and grip dials. The board opposite shows the three rule strengths.

**LIVE** follows the actual museum body on desktop or the active XR head. **DEMO SLOW / FAST** let you inspect a response while standing still. They supply fixed, labelled inputs at 1 metre, at 0.15 or 2.6 metres per second. **RESET** restores the default rules and LIVE input.

![Native controls beside the entrance](museum/doorway-console.png)
![Visible rule strengths](museum/doorway-rules.png)

The comparison photos use those declared demonstration inputs. They are saved Godot captures, not a live browser simulation. Separate tests drive the actual museum body through the LIVE response.

## Inside the hall

The new installation sits at map cell [8,53], behind the sphere at [8,40], in the existing rear gallery. Seven earlier artifacts and the onward passage remain. Fixed supports stay outside the walking lane; the changing ribs have no collision. The floor stays still.

![Inside the opening, looking toward the next passage](museum/doorway-inside.png)
![Sphere and doorway in the existing museum](museum/doorway-sequence.png)
![Actual arrangement from above](museum/doorway-above.png)

## What was verified

**142/142 native Godot checks passed.** This includes the 97 earlier model/sphere checks, explicit fuzzy arithmetic, source and topology retention, sampled geometry bounds, motion sensing, teleport discontinuities, native pointer buttons, and simulated XR input and dial grips. The actual museum CharacterBody crossed the doorway using its collision solver at scripted velocities. 203 supported capsule samples checked the route from the sphere to the controls, through the doorway and onward.

These are desktop Godot runtime tests with synthetic XR poses. Physical headset use, Quest performance and independent student learning have not been tested. Existing unrelated UID, registry and renderer warnings remain in the log; there were no script or parse errors in the successful run.

The artifact retains one source and 3,696 vertex entries. Rule inference and the small visual response delay are separate operations. [Read the exact method and controls](source/README.md).

[Test receipt](validation/report.json) · [Engine log](validation/engine.log) · [Placement](validation/placement.json) · [Godot implementation](source/fuzzy_doorway.gd) · [Museum entry scene](source/museum.tscn)

This continuation adds one research artifact. The canonical tutorial and reflective texts, and the spine order, remain as they were.
