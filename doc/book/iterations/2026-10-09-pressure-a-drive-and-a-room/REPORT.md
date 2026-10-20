# Pressure — a drive and a room

Soft Bodies, hall 4 of 9. Carusell moved a boundary. Here the boundary stays and a pressure command changes. The black PointBody returns unchanged; the closed box from the first hall becomes two small panels. The open sheet is not silently relabelled as an inflated volume.

|Part|Before|Now|
|---|---|---|
|Tutorial|A pressure-loop fragment with no complete host|Three full files: closed panel, pressure host, inherited point|
|Lineage|General reference to earlier sine spaces|Closed cube → pinned sheet → moving support → pressure-driven closed panels|
|New distinction|Pressure described alongside wall displacement|Command range, cycle rate and physical response remain separate|
|Transfer|No independent executable edit|Halve amplitude; predict three signal values and unchanged period|
|Reflection|Dimensions and perimeter pins from an unused generator; code interruption|The actual unequal authored slabs; bodily recognition and what a container permits|
|Room|Desk obstructs centre arrival|Same desk moved from (15,3) to (11,5)|

## What the source audit changed

The placed scene uses `breathing_room_scene.gd`, not its similarly named sibling `breathing_room.gd`. Its two meshes begin 1 × 4 × 7 metres, with 19 and 16 selected pinned indices. Their stiffness is .5 and .02; shrinking settings are −.2 and .02. The lesson flag adds the sine pressure driver to those existing bodies. The older text instead described the unused generator’s .5 × 4 × 10 walls and perimeter pins.

This matters pedagogically. Two unequal bodies receiving one command do not isolate a single material variable. The installed pair stays as the encounter; the learner creates a declared matching pair for a smaller experiment. Production scene and script hashes, controls and sequence order are unchanged. The contact-gallery portion of final.md is preserved verbatim.

## The learner’s object

Each .16 × 1.2 × 1.8 metre closed panel has 232 mesh entries, with 136 selected on its perimeter. The broad faces remain free. One phase supplies both pressure coefficients. The inherited ball can be picked up and used as a contact probe; its trigger holds/resumes the phase. It parks at the opening on release.

HOLD leaves the current command in place. RESET PHASE sets the clock to zero and applies half the current amplitude, without replacing the bodies or restoring their shapes. Changing amplitude while held changes pressure at that held phase. Those distinctions are explained alongside the complete code.

The independent edit changes AMPLITUDE .5 to .25. At phase 0, π/2 and 3π/2, the expected coefficients are .125, .25 and zero. The rate remains 1 rad/s. The tutorial asks the learner to distinguish this prediction from the observed space between the surfaces.

## Evidence

**32 exact printed-code checks and 31 native museum checks passed.** The test extracts the three code blocks from tutorial.md and runs those files under native Godot 4.6 with Jolt. The whole amplitude-edited host also runs. Three faulty hosts—missing delta, ignoring HOLD, and omitting the sine offset—are rejected by behavioural checks.

Checks read actual vertex positions, retained mesh/body identity, world-space pin locations under a translated and rotated parent, pressure values and supplied XRTools pickup/actions/release. Free vertices moved 0.0074 m while the isolated pressure command was held, and 0.0148 m in the museum test. A paired run with matching construction, gravity and settings but different pressure produced a maximum relative position difference of 0.0400 m. These are runtime observations, not calibrated material measurements or promised identical trajectories.

The real museum desk’s AMPLITUDE, RATE, HOLD DRIVE, STIFFNESS, RESET PHASE and RULE buttons were exercised through the desktop pointer. The authored wall settings were inspected at runtime. Native screenshots include the entry, walls, learner pair, held command, amplitude edit and hall from above.

## Space

The before run found the desk’s collision body and buttons in centre arrival. The relocated desk clears that path and remains reachable. All 313 quarter-metre route samples have capsule clearance and floor support along the outer crossing. This tests a route around the deforming specimens, not passage through them at every possible pressure.

The learner study is temporarily placed at hall-local (22,0,27), yaw 180 degrees, unit scale. Its initial test location was too close to the existing contact gallery. The final approach is clear and supported. No permanent extra exhibit was registered. Before and after images use the same .3 camera exposure; the simulations continue between photographs.

## Limits

The code and museum probes complete without script, parse or missing-physics-space errors. Existing project UID/renderer warnings remain in the logs. This is an author-led executable reconstruction, not an independent student assessment. Physical headset input, Quest performance and full-body contact with the large walls remain untested. Local HTML links, displayed-code parity and ZIP contents are checked; browser layout has not been automated.

Next: **SoftBodies_Obsticals_Part2 — same fall, another encounter**. The task becomes rebuilding declared starting conditions and observing what a changed contact makes possible.
