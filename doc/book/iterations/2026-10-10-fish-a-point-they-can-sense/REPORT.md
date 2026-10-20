# A school within reach

Built in the Endless Museum · 10 October 2026

There are now 72 fish beside the Boids hall's observation balcony. Pick up the black point from its stand: nearby fish gather. Hold the trigger to scatter them. Release the trigger and they gather again. Let go of the point and the school continues through its own neighbour rules. The point returns to its stand after 1.5 seconds.

## Try it

Reload **Swarm Intelligence → Boids Algorithm** and walk through the west opening onto the balcony. The point is on a pale stand, 1.18 m above the deck.

- **VR:** grip to carry; hold trigger to scatter; release grip to leave it.
- **Desktop:** right-click to carry/drop; hold left-click to scatter; move the mouse to guide the carried point.
- **Look:** cyan means gather, pink means scatter. The large rings mark the eight-metre range. The gold-ringed fish carries an arrow showing the sphere's steering contribution.

## What carries forward

The point is the existing PointBody class. The new fish reuse the original Boid steering code: separation, alignment and cohesion. This encounter adds an explicit fourth contribution, desired velocity minus current velocity, limited by strength and distance. Aiming for the point and fleeing it become changes in the same calculation. The boundary also contributes a turn, so the hand never has sole control.

This makes a useful optional bridge from the tested neighbour lesson to seek/flee steering. The fish are stylized agents; their shape does not establish biological accuracy. [The Nature of Code: autonomous agents](https://natureofcode.com/autonomous-agents/) supplies the relevant steering framework.

The original 100-prism flock, one-metre aquarium, controls and balcony remain. The 72 fish are a new companion encounter, not the original flock reskinned. The fourteen canonical tutorial/final files and the sequence order match their pre-change hashes.

## Evidence

**38/38 checks passed:** 19 focused production-code checks and 19 native museum checks, including four retained-camera captures.

The tests cover real integration, transformed coordinates, radius and strength limits, coincident positions, action/release, return to the stand, finite motion and capped speed over 20 simulated seconds, and the original Boid defaults. In the actual hall, a standing capsule has a clear approach and the stand is reachable. Only the stand seals navigation cells; the fish and visible range rings do not.

In this native run, mean distance from the point was **1.77 m after gathering**, then **4.11 m after three seconds of scattering**. These are observations from this run, not universal target distances. The simulation kept running during the images.

Pickup and trigger events were supplied by the probe. Physical headset use and Quest performance remain untested. The native run has an existing unresolved UID warning; no script errors were logged. All pictures below are captures from Godot in the actual museum.
