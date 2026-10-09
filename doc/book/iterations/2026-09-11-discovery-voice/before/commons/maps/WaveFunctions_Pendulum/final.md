# Where a swing leaves its past

Behind the bob there seems to be a second body, thinner, keeping just out of reach. Which way is it going?

<!-- @PendulumWave -->

Stand at the east post of the frame and watch the bob first. It swings left and right in one plane, under a beam, and it keeps returning. Now look past it. A cyan line leaves the bob and recedes down the hall, and the line is made of marks. Pick one mark near the bob and keep your eye on it. It does not swing. It travels straight away from you at a slow walking pace, and it will never do anything else.

Walk south along the east side, beside the record. Seen side-on the marks draw a wave, but the bob never drew one. Each mark is where the bob was at one moment, and its depth is how long ago that was. Find a mark where the line crosses the middle, then follow the line to the next crossing on the same side, the one after a whole swing. Count the marks between them. The plate a few steps further on prints the measured period and the target interval. Divide one by the other. Your count should come close; keep the difference in mind.

The plate prints more than that. Once the record fills: three hundred marks, about 7.5 seconds kept, a target of 25 milliseconds. Beneath the target, another line gives the actual gaps: about 16.7 to 33.3 milliseconds. Which interval did you count?

The request falls between two ticks of the physics clock. At this project’s 60 ticks per second, the recorder cannot visit 25 milliseconds exactly. It waits one tick, then two, alternating around the interval it was asked for. No extra position is invented between them. The small mismatch is already in the cyan line.

Go back to the post and press COARSE. The swing is not touched; the record starts again. The count settles around fifty, and the oldest mark approaches ten seconds of age before it leaves. A coarser sampler kept more time in fewer marks. The wave is still there, with corners, and your two crossings are now a handful of marks apart. Two rules end a record here, and the two settings run into different ones:

```gdscript
_sample_clock += delta
if _sample_clock >= sample_interval:
	_sample_clock -= sample_interval
	var bob_local := Vector3(length * sin(angle), pivot_height - length * cos(angle), 0.0)
	trail_points.push_front(Vector3(bob_local.x, bob_local.y, time))
while trail_points.size() > max_trail_length:
	trail_points.pop_back()
while not trail_points.is_empty() and time - trail_points.back().z > max_history_seconds:
	trail_points.pop_back()
```

A sample is the bob's position and the time it was taken, pushed to the front of a list. The first `while` cuts the list at three hundred entries; the second cuts anything older than ten seconds. FINE spends its three hundred in roughly 7.5 seconds and never reaches the age limit. Three hundred positions span 299 gaps; the age on the plate also includes the wait since the newest mark. COARSE is cut by age long before it reaches three hundred. `delta` is the physics step—one sixtieth of a second at the current setting—and `time` advances there. The physics clock keeps the record; drawing it on the headset is another operation.

Depth is the same clock read backwards:

```gdscript
var depth: float = (time - p.z) * time_speed
```

The third component of each sample is its time. Age times 0.6 metres per second is how far behind the bob a mark is drawn, so the line is not a path. It is a list laid out along the hall with the newest entry at the bob.

Now walk to the far end and wait for one mark. It is there, and then it is not. Nothing fades. The pendulum lost nothing at that instant; its next swing needs only the angle and the speed it has now. The record lost a position it can never sample again. One rule carries a state forward, the other keeps a list, and the hall shows both at once.

Press STROBE. The pendulum has been timing itself: each upward crossing of the middle is kept, and two of them give a period. The sampler now takes one mark per period. After the record fills, about three or four marks remain, nearly aligned. The clock also measures the period in ticks, so a little spread can survive. The record of a moving bob approaches the record of a bob at rest. The sampler was given the rhythm of what it samples, and much of the movement disappears from this record. RESET returns the swing to its starting angle, this experiment's clock to zero and its list to empty. The room's clock is not ours to reset.

The drawing dot in the point rooms kept a list too, but it asked whether the hand had moved before it kept anything. This recorder asks only whether enough time has passed, so a bob resting at the end of its swing is marked again and again. Two recorders, two questions, and neither of them is the motion.

<!-- @ -->

On the west walkway a drum recorder turns under a pen. It keeps the same kind of past on a different clock, where time is an angle rather than a depth.

The next hall takes the rising and falling out of time. Two walls carry it along a passage, so that what was "how long ago" becomes "how far along", and the body that reads the record has to walk it.
