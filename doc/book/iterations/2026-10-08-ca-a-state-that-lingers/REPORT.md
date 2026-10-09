# A state that lingers

The second Cellular Automata hall now teaches a precise difference: an address can be occupied without contributing to its neighbours' active count. The familiar point carries the step control; one gold frame keeps the observation at the same cell.

## The progression

**A row with neighbours → a volume with three states → a history laid out in space.**

The previous lesson supplied old/next arrays, indexed state and a rule. Here a Boolean becomes empty/active/fading, an address gains three coordinates, and the neighbourhood reaches all 26 surrounding positions. We count only active cells. A fading cell must empty before a later generation can consider birth. CA_GameOfLife is next; its lesson has not been rewritten in this pass.

## Changes in this hall

- **Tutorial:** a complete 7 × 7 × 7 construction, its unchanged PointBody file, the 81-case transition contract, synchronous updates and empty boundaries. A twelve-cell seed makes the beginning inspectable. The independent task is to predict two adjacent cells through two updates.
- **Museum:** a black pickable sphere beside the console carries STEP wherever the visitor stands. The enlarged neighbourhood now reports its generation, central state and active-neighbour count. Both use the existing solver. Its rule, seed and 50 × 50 × 50 calculation are unchanged.
- **Space:** the far gallery is level, replacing its disconnected pits and raised blocks. The opening under the volume remains. Both authored artifacts remain. Entry and exit use the central thresholds; the generic extra gate is disabled for this hall.
- **Reflection:** the existing argument stays with presence, participation, fading and the drawing's omissions. Two implementation blocks become prose. The held point and level far gallery are described. Full code belongs in the tutorial.
- **Plan:** only CA_ElementaryRules changes. The review decision remains draft; the other lessons keep their current decisions and content.

## Two constructions, one rule

The learner study and the installed work are deliberately distinguished. The small study uses twelve stated cells and draws every occupied cell. The museum uses seed 23090 in a larger volume and hides fully enclosed cells when rendering. They need not have the same shape to implement the same transition.

In the museum, address (26, 22, 24) begins active with eleven active neighbours. It becomes fading with seven, then empty with five. The middle count would allow birth at an empty address, but the current state is fading. The first branch matters.

## Evidence

**27 construction checks and 30 native museum checks pass in Godot 4.6.** Construction checks extract the exact two code blocks printed in tutorial.md and compare them with the maintained files. The carried PointBody is byte-identical to the previous hall's version. The table is checked for all three states and all 27 possible counts. Eight deterministic mixed-state seeds, each advanced eight times, agree with the installed solver. Reverse traversal agrees; deliberately counting fading cells and allowing premature rebirth are rejected. The independent two-cell exercise, state-preserving draw, rendered states and actual XRTools pickup/action/release with supplied poses also pass.

The museum check runs the actual 50-cubed installation. It checks the shared trigger, caption, replay, VIEW and release. Four routes include 197 samples of level floor and clearance for a 0.56 m wide, 1.7 m tall capsule on collision layer 1. Authored entry and exit approaches are valid. Camera-retention checks are included in the museum count; these are not 30 separate teaching assertions.

The first native learner screenshot put its small construction against the dense installed volume. That made the two hard to distinguish. The final capture mounts the same printed code in the cleared side of the far gallery, with a quieter background. It is a temporary test mounting, not an added permanent artifact. A small backing plate makes the installed hand instruction clearer. Earlier captures are retained in diagnostics.

## Remaining limits

The installed full-volume step measured **212.7 ms** in this desktop run. The existing solver is still too expensive for a smooth single VR frame; this pass does not solve that performance problem. Its observation clock starts held. The small learner study should not be mistaken for proof of the large artifact's performance.

Supplied controller poses and sampled routes are not a physical headset, Quest, complete portal-transfer or human-learning test. No independent ghost student has taken this lesson yet. Existing project warnings remain in the logs; the successful runs have no SCRIPT ERROR or Parse Error.

## Read and inspect

- [Tutorial left · reflection right](parallel.html)
- [Complete tutorial](tutorial.html) · [Complete reflection](final.html)
- [Tutorial Markdown](tutorial.md) · [Reflection Markdown](final.md)
- [Exact volume script](printed/volume.gd) · [carried point](printed/point_body.gd)
- [Construction checks](checks.json) · [Museum checks and route samples](museum/report.json)
- [Construction log](engine.log) · [Museum log](museum/engine.log)
- [Scoped changes](changes.diff) · [Review ZIP](ca-states-review.zip)
