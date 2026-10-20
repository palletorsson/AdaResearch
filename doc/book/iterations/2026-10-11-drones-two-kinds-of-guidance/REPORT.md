# Two kinds of guidance

Endless Museum · Boids · 11 October 2026

Two flights begin alike. Move the black point. The cyan bodies recover assigned places; the pink bodies adjust to neighbours while seeking a shared destination. Similar-looking groups can be held together by different instructions.

## Try it in the museum

Reload **Swarm Intelligence → Boids** and enter the new east court through the opening in the existing room. The black point waits on a pale stand at hand height. A 2.2 m aisle runs between the flights.

- **VR:** grip and carry the point. Trigger shows or hides guidance.
- **Desktop:** right-click to carry/drop; left-click while carrying toggles guidance.
- Move it left, right, up or down. Both destination systems receive the same bounded displacement.
- Let go. The targets ease back to centre; the point returns to its stand after 1.5 seconds.

## What changes between the flights

| Kept in both | Cyan: assigned slots | Pink: neighbours + common target |
| --- | --- | --- |
| Twelve agents, identical relative starts and velocities | One destination per body | One shared destination |
| Same separation, arrival rule, speed cap and boundary rule | Alignment and cohesion off | Alignment and cohesion on |
| Same carried point | Moves the whole slot arrangement | Moves the common target |

The gold drone in each flight is a stable witness. Its gold arrow shows actual total acceleration at **0.25 m per m/s²**. A fine link leads to its destination. Pink links connect the witness to bodies within its two-metre perception radius. At rest, an acceleration arrow can shrink away. Trigger removes these guides without changing the simulation.

The drone bodies reuse the existing museum Boid movement code. Their new adapter supplies an arrival request. The hand control reuses the existing PointBody. The two groups read their own neighbours, so they do not steer toward the other flight across the aisle.

## What this adds to the sequence

Fish made the point a source of attraction or repulsion. The listening crowd kept a position after the point moved away. Here the point changes a destination, and the comparison makes the source of coordination visible. The new question is **which information each body uses**.

This is an optional encounter beside the primary Boids lesson. The fourteen canonical tutorial/final texts and seven-hall order are unchanged. The original flock, aquarium, controls and fish balcony remain. The map extends from 13 × 13 to 28 × 13 cells; its automatic entry partition is disabled because it otherwise cuts through the new comparison court. Authored walls and existing exhibit placements remain, apart from the three-cell opening to the court.

## A possible reflection

You move one point; two groups answer. One carries twelve appointed places. The other keeps measuring who is near. The order you see does not tell you how it was made. Both movements depend on choices we have written into the room. Show their guides and some of those choices become visible.

This is an encounter note, not an insertion into the agreed final text.

## Evidence and limits

**43/43 checks passed:** 24 production-code checks and 19 native museum checks, including five rendered captures.

The code checks exercise the real Boid integrator, matching initial conditions, separate neighbourhoods, destination semantics, arrival braking, synthetic pickup/action, transformed coordinates, display-only toggling, finite and speed-capped movement, formation convergence and extreme hand targets. Forty seconds at neutral plus fifteen seconds at each extreme remain bounded in the tested setup.

The museum checks exercise the real hall, standing-capsule clearance and floor support through the opening and aisle, point reachability, live target movement, guide visibility, release/reset and retained exhibits. All images are native Godot captures. The final run has no script errors; the existing unresolved UID warning remains in its log.

An early capture exposed the unwanted partition. The first control checks also sampled from the overhead camera and before the display had updated; the final probe returns to visitor height and waits for the update. Failed receipts are retained in the earlier run folders.

These are kinematic agents with soft steering and separation. Rotor dynamics, sensor noise, physical collisions and real-drone flight control are not simulated. Both flights contain authored goals and constraints. The neighbour-driven flight is not a demonstration of complete decentralization. The production Boid integrator reads sequential live states, unlike the snapshot update used in the printed tutorial model.

Physical headset use, portal crossing and Quest performance remain untested. This encounter run is not a new ghost-student assessment of the book.
