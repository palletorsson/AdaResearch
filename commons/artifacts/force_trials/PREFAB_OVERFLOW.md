# Just get it through

The existing `force_trial_conveyor` now carries the physical-consequence passage in Change_Choreography. Same token, scene, placement and 10 × 11 m floor space. `prefab_overflow.gd` uses the current hand-led force-play framework.

## Encounter

Start FEED or hold the rose gate grip and press its trigger. The belt transports cargo through friction against a collision surface moving at 1.8 m/s. Pull the grip to apply force at the gate's outer edge. Its real hinge stays attached; a bounded restoring torque tries to close it. The trigger shortens the delivery interval from 0.9 to 0.3 seconds. Release the grip to end the flood.

32 deliveries: crates, chairs, extinguishers and black PointBody spheres. Existing museum meshes are reused. The second half enlarges props; prop mass scales with the cube of size. These are chosen model masses, not measured properties of the depicted furniture. The chair uses six convex part shapes; the crate a box and the extinguisher a capsule. The point keeps its sphere collider.

The receiving tray is another real hinge with restoring torque. Collisions and gravity change its load and rotation. There is no scripted pile, automatic destruction, ragdoll, forced catastrophe or simulated material deformation. Ordinary jams and spills persist; the visitor can carry props or push them with the supplied stick.

## Engine choices made visible

One moving surface prescribes the belt's speed. It can supply energy and does not simulate a motor's torque curve. Friction, Jolt contact resolution, model masses and the chosen hinge torques shape the outcome. The rate counters describe admissions and first crossings, not a causal explanation of every collision.

The familiar prefab enters a new combination; the same object now serves as delivery, obstacle, roller or brace. Increasing its size changes fit and leverage. This is the chosen exaggeration. A second possible variation—attaching a chain of chairs—was left for another encounter so this one retains a readable task.

Finite capacity is explicit. After 32 admissions the feed stops; it does not delete old props to pretend infinite overflow. The inlet checks available space. Idle pooled bodies are hidden, frozen, collisionless and below the floor. Reset restores them without a kinematic teleport impulse, and refuses while a body or the gate grip is held. The shared force-play recovery still catches bodies below -12 m or beyond 85 m; it is a boundary recovery, not the usual outcome.

## Relation to the book

`final.md`: short physical task → expectation → hand intervention → consequence → another use for the residue. The Keats and Garry's Mod references are associations, not claims that these sources predict our simulation. No numerical entropy claim. Phase rods remain the agreed tutorial anchor; this is an embodied comparison for rates, contact, torque and accumulated state.

## Verification

`tools/probes/prefab_overflow.gd` exercises real Jolt bodies, inherited XRTools pickup, hand-applied gate force, anchor retention, occupancy, pause, pooling and held-safe reset. `prefab_overflow_museum.gd` verifies actual placement, aisle clearance and the event in the production museum. Physical headset feel and Quest performance require a user visit.
