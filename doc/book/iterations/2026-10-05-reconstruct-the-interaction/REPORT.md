# A tutorial should leave a capability

5 October 2026. One writing pilot, using the grabbable point.

The current Coordinates lesson explains the existing object and offers small edits. It does not supply the complete construction of its pickable sphere. We were testing source fidelity and parameter changes while asking the lesson to build a more substantial capability.

The new pilot makes that capability explicit: **construct a sphere the prepared hand can grab, carry and release in place.** It prints the complete 34-line construction and declares its support. The XR toolkit remains supplied; creating the body, mesh, collider and their relation is the learner's work.

## Compact instruction for a future writer

```text
MAKE: Black sphere; grab, carry, release in place.
BRING: _ready; variables; mesh/node; collider; local position.
GIVEN: Museum; configured XR hand; XRToolsPickable; collision settings; black material settings.
BUILD: Body; matching mesh/shape; direct refs; frozen release.
CHECK: Hold moves both; release stays; disabled refuses; new radius matches.
LATER: Grip pose; trigger action; labels; coordinate readouts.
```

This is the first part of Coordinates, not a removal of its local/world teaching. The frame and readout need their own explicit construction or declared connection when that part is revised. No full lesson replacement is promoted by this pilot.

## What the tests say

- Native code: 30 checks passed using the real XR Tools library and a synthetic controller in an isolated Godot project.
- Tested: construction, dimensions at two radii, near-grab detection, disabled rejection, pickup, held movement, release and collision-setting restoration.
- Not yet tested: placement of this exercise in the museum, physical headset input, beginner reconstruction or explanation.
- The photographed point is the existing museum artifact, captured 3 October. It is not a render of this prototype.

The six structural negative controls cover missing support, stale support, incomplete printed code and stale native evidence. These checks prevent a false green result in those cases; they do not score the quality of prose.

A separate source review found and corrected the current tutorial's Z-arm claim: the drawn black arm points toward negative Z. Museum code and reflective text were not changed.

## What guides the next draft

Keep a sentence when it helps the student build, observe, explain or transfer the selected operation. State the supplied boundary. More code is warranted when it closes a missing construction step. Extra code that implements another interaction can wait.

Use [the framework](../../course/functional_text/RECONSTRUCTION.md), then [read the pilot lesson](tutorial.md). The full example is [point.gd](point.gd). [Native evidence](report-runtime.json) and [contract check](check-report.json) keep their claim scopes separate.
