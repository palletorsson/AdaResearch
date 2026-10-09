# Predictions recorded before engine execution

I have not run Godot, read a teacher test, or observed any run of these files. These are predictions from the supplied packet. Each fresh comparison begins at rest in the stationary, unit-scale PointStudy, with its local +Z clear, no gravity or damping, no hand contact, and no collisions. Times below begin with a button press.

I use the lesson's velocity-change rule, delta-v = force * duration / mass. For distances I reuse Launch's constant-acceleration term, 0.5 * acceleration * time * time, and add velocity * time during coasting. Applying those two pieces consecutively is my own algebraic inference. These are ideal continuous-time values; the displayed readings and end snapshot may differ slightly at a physics-step boundary.

## Original and mass edit

For one newton throughout the first second, acceleration is 1/m metres per second squared, and the speed at t = 1 s is 1/m metres per second.

| Trial | Mass (kg) | Speed at 1 s (m/s) | Distance at 1 s (m) | Speed at 2 s (m/s) | Distance at 2 s (m) |
| --- | ---: | ---: | ---: | ---: | ---: |
| Original | 1 | 1 | 0.5 | 1 | 1.5 |
| Original | 2 | 0.5 | 0.25 | 0.5 | 0.75 |
| Original | 4 | 0.25 | 0.125 | 0.25 | 0.375 |
| Mass edit | 1 | 1 | 0.5 | 1 | 1.5 |
| Mass edit | 2 | 0.5 | 0.25 | 0.5 | 0.75 |
| Mass edit | 8 | 0.125 | 0.0625 | 0.125 | 0.1875 |

The two-decimal supplied readout cannot display 0.125 exactly. I expect a value near 0.12 or 0.13 m/s there, depending on numeric rounding; the underlying prediction remains 0.125 m/s. The edit changes the third body's mass and the caption heading together.

## Two points, two clocks

| Time after START BOTH | 1 kg speed (m/s) | 2 kg speed (m/s) | 1 kg distance (m) | 2 kg distance (m) |
| --- | ---: | ---: | ---: | ---: |
| 1 s | 1 | 0.5 | 0.5 | 0.25 |
| 2 s, both pulses ended | 1 | 1 | 1.5 | 1 |
| 3 s, one second of shared coasting | 1 | 1 | 2.5 | 2 |

At 2 s the first point has accelerated for one second and coasted for one second. The second has accelerated more slowly throughout both seconds. Equal final speed therefore leaves a 0.5 m difference in their forward displacements. After that, equal speeds retain that difference. The caption's live distances keep growing, but its one stored end-distance pair should remain near 1.5 m and 1 m until the next button press clears the flag. Distances are measured from the original scene starting positions, including if I press again.

The two points begin 1.2 m apart across X, which exceeds their combined diameter of 0.28 m. In the ideal straight motion their sideways separation remains fixed, so they do not collide with each other.

## Why the bodies coast

Each clock is reduced with maxf(0, remaining - delta). When the available interval is zero, the conditional skips apply_central_force. That ends the force; it does not assign a stop velocity. In free_point.gd, freeze is false, gravity_scale is zero, both damping modes replace other damping with zero, and can_sleep is false. With no new influence, I predict unchanged velocity and distance increasing by speed times further elapsed seconds. The lesson also allows collisions and pickup; coasting is conditional on avoiding those.

## My further choice

I chose 3 kg and kept the force at 1 N along local +Z. To reach 1 m/s from rest, duration = desired speed * mass / force = 3 s. The acceleration is 1/3 m/s squared.

| Time (s) | Speed (m/s) | Distance (m) |
| ---: | ---: | ---: |
| 1 | 1/3 | 1/6 |
| 2 | 2/3 | 2/3 |
| 3 | 1 | 1.5 |
| 4 | 1 | 2.5 |

The transfer button uses the supplied helper, and the fresh point starts at rest. I expect its final speed to match both comparison points. Compared at each trial's own force-ending instant, it has gone farther than the 1 kg point's 0.5 m and the 2 kg point's 1 m. Those ending instants are different, so that observation does not compare all three at one shared time.

## A second press

After a completed original pulse, another full pulse before any contact adds the same velocity change. The original speeds become 2, 1 and 0.5 m/s after two pulses; the edited speeds become 2, 1 and 0.25 m/s. Those speed sums assume both pushes and the existing motion point along +Z. More generally it is velocity vectors that add, and the caption reports their length.

If the second original pulse starts immediately at t = 1 s, the ideal distances at t = 2 s are 2, 1 and 0.5 m. A waiting interval adds further coasting distance but does not change the eventual speeds. For the two-clock comparison, pressing again after both finish adds 1 m/s to each point, ending at 2 m/s each; the first still completes its added change one second earlier. A second complete transfer pulse likewise adds 1 m/s.

Pressing during an original pulse replaces its remaining time with 1 s. It does not queue a separate pulse or reset the body. For example, pressing at t = 0.5 s and then leaving it alone keeps the 1 N force on until t = 1.5 s, producing ideal original speeds of 1.5, 0.75 and 0.375 m/s. For the comparison, that press restarts both entries to their respective durations.

## Holding a point

The packet says a held point misses force while its clock continues to count down. If a point is held for a total h seconds during a one-second pulse, the button contributes only (1 - h)/m m/s of +Z velocity change over the unheld part. For h = 0.5 s, the original button contributions are 0.5, 0.25 and 0.125 m/s for masses 1, 2 and 4 kg. If a point is held throughout its entire pulse, the button contributes zero and does not save time for later. A 2 kg comparison point held throughout its first second has one second of potential force left, contributing 0.5 m/s if released then.

I cannot infer an exact final speed after an arbitrary catch and release from this packet. The hand can alter the state, and the supplied physical-release helper does not explain how release velocity is chosen. The numbers above describe the force's contribution, or the final speed under the extra assumption of a stationary release and no other velocity. I will not treat the unheld-time arithmetic as a prediction that catching preserves pre-catch motion. A later new press begins from whatever state the intervention left.
