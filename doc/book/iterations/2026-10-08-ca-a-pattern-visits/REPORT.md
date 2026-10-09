# A pattern visits an address

The previous hall kept a history. Here both grid axes belong to one present. A glider seems to travel; the cells stay in place. One selected address can light a lamp without receiving any influence back from it.

## Changes per track

- **Tutorial:** complete `life.gd` plus the unchanged PointBody file. Count eight neighbours, apply B3/S23 synchronously, draw fixed cells and connect one address to one lamp. Build a blinker, predict its phases, then move only the lamp's binding. All geometry is visible in the code; the existing museum supplies Day Zero's player, camera, light and XR Tools.
- **Reflection:** retain the encounter with pattern, place, withdrawal and support. Remove implementation blocks. Clarify that Conway's reported design aims were not a theorem forbidding unbounded growth. The observing body still does not enter this rule; that transition belongs to the next hall.
- **Interaction:** the familiar black point now carries STEP beside the large floor. Pick it up, walk to an address and use the trigger. Release parks it by the console. Its location does not change a cell. This addition applies only to `floor:walk` address-study placements.
- **Room:** level the rear gallery and remove its short partition. Scale the mould and growth studies to fit; move the dark sphere and screen away from crowding. Keep all six authored works, including the existing hexagonal table. Reserve incidental sculpture out of circulation and put entry/exit on the thresholds.
- **Plan:** update this hall's summary, dependencies, transfer task and evidence. Other lesson rows and this lesson's draft decision are preserved.

## The teaching line

The opening taught an old-to-next row. The next room gave state a duration in a volume. The third kept independent generations and used them as image, ornament and support. **This fourth hall asks what we follow when we recognise a moving figure.** It introduces Conway's two-dimensional present and an explicit output connection.

The learner study is deliberately smaller than the installation: one lamp and manual steps at a table, rather than three lamps, RUN, TRACE and preset controls around a 9.6 m floor. Both use a 24 × 24 wrapped grid, the same starting glider and the same transition law. The complete learner files were mounted temporarily inside the museum for their photograph; no extra permanent table was added.

The independent exercise changes the beginning to a three-cell blinker. The centre lamp stays lit while the line alternates. Moving the binding to an end address makes the lamp alternate, with no change to the automaton. This checks whether the student can separate a rule from a use of its answer.

## Evidence and limits

**29 exact-code checks and 38 museum checks pass in native Godot 4.6.** The printed blocks are extracted, matched byte-for-byte to the maintained files, then executed. Checks cover all eighteen rule cases, all eight neighbour offsets, wrapping, fresh buffers, reverse iteration, 48 glider steps and eight other beginnings against the installed solver. They also cover the independent blinker/address exercises, two deliberately broken rule variants, rendered colours, fixed transforms, collision support and actual XRTools pickup/action/release with supplied poses.

The museum checks cover carried STEP, LINK without cell changes or false onset counts, TRACE restoration in both views, the blinker and meeting, RUN/limit, and a supplied body supported at address A before, during and after occupancy. Five routes contain **306 samples** of level floor and clearance for a 0.56 m wide, 1.7 m high capsule on layer 1. Portal approaches pass. Camera-retention checks are included in the museum total.

The first learner probe used an incorrect production property name; the corrected harness passed. The first route samples touched the console and readout stem. The final path stops at the reachable console approach and goes around the furniture. Earlier diagnostic logs are retained. Final successful runs contain no SCRIPT ERROR or Parse Error; existing project warnings remain.

The Life solver and lamp receiver are unchanged from this pass's baseline. The hand control reuses the existing STEP. Secondary works were repositioned, not given a new interaction audit. Native captures retain the current lighting and blank wall frames. These results do not establish tracked-headset comfort, Quest performance, full portal transfer, every collision layer, or an independent student's understanding.

## Read and inspect

- [Tutorial left · reflection right](parallel.html)
- [Whole tutorial](tutorial.html) · [Whole reflection](final.html)
- [Tutorial Markdown](tutorial.md) · [Reflection Markdown](final.md)
- [Exact life.gd](printed/life.gd) · [unchanged point_body.gd](printed/point_body.gd)
- [Learner checks](checks.json) · [Museum checks and routes](museum/report.json)
- [Learner engine log](engine.log) · [Museum engine log](museum/engine.log)
- [Scoped changes](changes.diff) · [Review ZIP](ca-life-review.zip)
