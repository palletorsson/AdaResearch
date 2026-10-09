# Forces: what carries the tutorial?

Implemented tutorial selection for the eleven existing halls, updated 8 October 2026. Each tutorial.md now contains a complete tested continuation. Motion’s final.md now follows its current spheres; the other ten reflections remain preserved for editorial comparison and need alignment where controls changed. The sphere/PointBody remains the student's recurring body. Supporting apparatus gives that body somewhere to act.

| Hall | Tutorial object | Small new operation | Other encounters / boundary |
|---|---|---|---|
| Vectors — What a vector is | Two familiar points | Subtract positions; measure length; handle zero before normalizing. Then return to the same points for addition and projection. | The cylinders show relations. They are not forces. This hall may need several short steps, not one dense script. |
| Launch | A point in Launch Arc | Give a point initial velocity; evaluate its flight under constant acceleration. | Keep the analytic prediction explicit. Catapults and fireworks compare it with contact and timing; constructing a catapult is optional. |
| Motion | The three weighted point spheres | Apply the same force for the same duration; vary only mass; release and retain velocity. | The trolley and flower mower put resistance and work into play. Equal visible size can hold different masses. |
| Fields and motion | One point crossing the vortex | Sample acceleration at the body's current position, every physics step. | Additional receivers and the visitor reveal the same rule at scale. Do not substitute prescribed velocity without naming the change. |
| Resistance | One point in one liquid region | Apply speed-dependent drag against velocity; compare a second coefficient. | The four basin ramps teach contact friction/rolling as a separate comparison. Buoyancy is another term; add it after drag is understood. |
| Oscillation | One tethered point | Restore toward a rest length; add damping; release and compare. | Only then couple two points. The seven-point row, hinged swings and suspension show extensions. A spring permits extension; a hinge retains its pivot. |
| Choreography | Two point-tipped arms in the phase-rod study | Distinguish an angle offset from a rate difference; compare prescribed repetition with a spring. | Retain the phase rods as primary: the existing writing makes this distinction well. Conveyor overflow remains the physical consequence beside them, not a second required tutorial. |
| Gravity | Two attracting points | Compute an equal/opposite pair interaction; preserve the initial velocities. | Add the third body only after the pair. The tower demonstrates support under uniform gravity; the magnet is a selective model, not the same law. |
| Support | A familiar cube resting on the removable-leg table | Let collisions and supports carry a load; remove one support and observe the new state. | Use the existing scene's small construction. Do not rebuild an entire walking creature for this lesson. |
| Arena | The bowling point | Give one impulse; let the physics engine resolve contact with a pin, then ten pins. | Recoil and target choice extend the encounter. The catalyst provides a second intervention; it need not become a full weapon-system lesson. |
| Force as place | The two hand-held point thrusters | Send a direction and acceleration request to the existing player movement adapter. Release the trigger without erasing velocity. | The player is now the receiver. Use the existing player/XR setup; do not reconstruct locomotion here. The points thrust where the hands point. |

## What stays with the student

An address became a line, then a trace and a body. Here the body acquires velocity, mass and responses. Reuse the earlier PointBody and its visible identity when the lesson needs a sphere. Introduce another body only when its shape, contact or attachment changes the question. The student carries learned code and data; do not claim the museum currently transports one identical physical instance through every hall.

The long stick supplies reach and collision. The catalyst supplies an intervention after motion has started. Both belong in the room, without forcing their complete implementation into every tutorial. The current museum catalyst is BecomingCatalyst, a separate existing tool with its own mode system; its Forces shot reduces velocity and adds temporary damping. It is not the flight point or the gravity gun.

## The minimum lesson contract

- Name the existing artifact and the earlier code being continued.
- Teach one new operation first; supply every new dependency used in the runnable example.
- Keep force, acceleration, velocity and prescribed position distinct.
- Show a controlled comparison before combining the mechanisms.
- Give the student one independent change and an observable prediction.
- Run the reconstructed code in Godot with assertions for that prediction and its boundary case.
- Keep reflective claims in final.md grounded in what the encounter actually does.

The spring hall remains a useful next application: displace the point; predict its return; release; vary damping; push it with the stick; compare with a hinged seat; try the catalyst. The tutorial reconstructs the point's spring response. The full row and extra tools remain available for exploration.

## Evidence and review

The code lives in `doc/book/studies/forces-point-lineage`. The review, eleven summaries, preserved before texts, exact-code comparisons and actual museum captures are in `doc/book/iterations/2026-10-08-forces-one-body-through-the-halls/index.html`. Execution-plan hall summaries are synchronized without changing review decisions. Strong writing can revise the plan; do not overwrite it merely because an artifact inventory suggests another topic.


## Build and investigate: Motion pilot

Motion now includes an independent two-point/two-clock construction alongside its complete reference. Students predict equal final speeds but different travelled distances, implement both clocks, retain measurements, and explain coasting. A ghost-student reconstruction exposed missing explanations; the repaired version passed native checks and ran in the actual museum. See [the pilot](../iterations/2026-10-08-motion-build-and-investigate/index.html). This is the first complete test of that expanded teaching contract, not evidence that the remaining ten lessons already satisfy it.
