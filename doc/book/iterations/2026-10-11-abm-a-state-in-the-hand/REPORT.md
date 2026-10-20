# A state in the hand

Endless Museum · Agent-Based Modelling · 11 October 2026

The complete printed six-point study now has a permanent table in the existing ABM hall. It uses the same PointBody and byte-identical runtime copies of the three files already shown in tutorial.md. Runtime copies live under commons because packaged builds exclude doc; the publisher verifies equality. New furniture gives it a stable surface, close controls and space to approach from either side.

## The lesson

Boids asked which nearby bodies enter a calculation. Here the familiar sphere carries a Boolean state: searching or returning with food. Hold a point to pause all six, move it to FOOD, release it and press ONE TICK. A green cube appears above that same sphere. Its next request is now towards HOME, and it deposits a trace. Move it home and step again: one delivery is counted, the cube disappears and searching resumes. Let the group run, then compare REPLACE AGENTS with CLEAR ALL. New individual records can inherit the field left by the old ones. This prepares the next Ant Colony lesson, where state selects between two trace channels.

Learning elements: **individual state; contact and transition; state-dependent behaviour; shared history; two kinds of reset.** Boids was already an agent-based model; this hall isolates an additional mechanism.

## Try it

Enter **Swarm Intelligence → Agent-Based Modelling**. The table is on the right near the north entrance. Hold any sphere; trigger selects it for the readout and white ring. The four front buttons are RUN / PAUSE, ONE TICK, REPLACE AGENTS and CLEAR ALL. Walk around the sides to reach the points. Keyboard controls remain 1, 2, 3 and R.

The table starts paused. Holding a point suspends stepping for everyone. REPLACE and CLEAR refuse to run while a point is held. Release and step to make the change observable. All operations reuse the same six sphere instances.

## What remains in the room

The original colony display, navigator and full-size listening court remain. They offer richer and different encounters around one primary coding object. The unchanged final.md reflects on a changed path, on reading intention into a rule, and on what a replacement population inherits.

The unused physarum_colony placement was removed from this hall: the baseline museum loader left it uninstantiated. Its original source remains. The table takes the nearby clear bay. The hall retains its 24 × 10 layout; entry and exit markers now align with the central route. Only this hall's row in the museum plan changed.

The printed study is deliberately limited. Food is inexhaustible; contact is a distance test at the start of a tick; points can overlap and wrap at the edge. The cube records state. These choices differ from the original colony's finite food and additional behaviours and are already explained in the tutorial.

## Checks

**94/94 automated checks passed:** 42 reconstructed printed-code assertions, 40 installed-museum checks and 12 portal checks. The code test includes an independent slower-return edit, three deliberately faulty variants and supplied XRTools inputs. The installed test uses the actual point and button methods for pickup, release, stepping, delivery and resets.

Five routes were sampled at 277 positions for floor support and standing-capsule clearance. The portal coordinator completed ABM → Ant Colony → ABM, with supported arrivals and one resident hall. The unassisted study made 12 deliveries in 300 model ticks; these ticks were stepped by the probe, not a VR frame-rate measurement.

All 37 saved source/text hashes still match, including the original exhibits, PointBody, lesson source, sequence order and all fourteen canonical swarm texts. No tutorial or final text was rewritten. The publisher verifies the exact intended map and plan differences.

No script or shader errors appeared in the final runs. Existing UID, renderer, Jolt and viewport-texture messages remain in the logs. These are author-operated automated checks; physical headset use, Quest performance and independent student learning have not been verified.

## Images

The report contains eleven native Godot captures. Before/after pairs use the same room, overhead and table cameras. The five state photographs use one fixed view. The unrelated original colony continues running between captures. No generated illustrations substitute for the installed scene.
