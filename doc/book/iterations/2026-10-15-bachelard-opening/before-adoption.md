# What chance is allowed to do

<!-- @random_touch -->

Three thin horizontal lines hang in space, each two metres long, one metre apart. A dark sphere waits at the centre of each. Touch the first. It moves sideways and carries the avatar with it. Withdraw the hand and the ride stops; the sphere settles back onto its line alone.

One metre farther back, another sphere waits. Touch it and the same horizontal path unfolds twice as fast, with more frequent changes of direction. The third adds rising and falling to the first ride's sideways movement. How does each journey feel? The comparison leaves that answer to the person making it. In VR, touch begins the ride; on desktop, right-click holds and releases the sphere. The avatar moves, but there is no physical surface pushing the hand back.

We have changed two conditions separately: how quickly a path unfolds, and which directions movement is allowed to take. The destinations come from a pseudorandom generator—a calculation whose changing internal state produces a sequence of values. Its seed sets the starting state. Replay arms the spheres at their centres; another touch begins the retained path again. What felt difficult to anticipate can nevertheless return exactly in the sphere's motion. The player's journey also meets the room's collisions.

The sideways targets stay within the two-metre line. The third ride can rise one metre above its entry height. Movement between targets is smoothed. Neither these bounds nor the smoothing comes from chance. If something in this motion matters to us, what would we keep long enough to investigate?

<!-- @random_number_book_page_1955 -->

On a large page, rows of five-digit groups enter from above and descend. Touch one group. It stays amber while the others continue. Here keeping interrupts a disappearance. It may begin with no better reason than that these were the numbers under a finger.

The object's historical relative, RAND's *A Million Random Digits*, published in 1955, supplied numbers for calculations using random selections. Preparing that supply required testing and correction: the electronic source had biases, systematic tendencies away from the intended even spread.[^rand] Recording faithfully could preserve an unwanted pattern too.

Our falling page is an authored stream, not the historical table brought to life. Still, it lets preservation become an action. A saved page can be examined for patterns; it cannot alone establish its physical origin or guarantee that future numbers will be unpredictable. We have kept something available. We have not yet settled what it tells us.

<!-- @lava_entropy_wall -->

Coloured blobs rise inside virtual lamps. Below them are two images, BASELINE and CURRENT CAPTURE: a saved comparison and the latest sensor reading. The simulated sensor turns the lamp scene into a grid of colour measurements.

Hold the scene and cover half the sensor's view. The capture changes; the lamp arrangement stays. The missing portion still exists in the world but has no place in this reading of it. Unlike the finger on the page, the cover selects what will enter the record at all.

Physical random-number systems can use measurements of uncertain processes as their source. These lamps model an acquisition procedure; their appearance does not turn them into a physical source of randomness. Here we can investigate the receiving instrument. A cover makes its exclusion visible. What happens when the exclusion is too small to see?

<!-- @geiger_counter -->

Click. A gap. Another click. A Geiger counter detects radiation; this board simulates detections, with no radioactive source connected. It compares two time gaps and turns their ordering into a bit—a zero or one, shown in cyan or amber.

Replay the recorded events with a coarser clock, one that measures in larger time steps. Two unequal gaps can now receive equal measurements. The board skips that pair. Listen again: the recorded clicks remain; a distinction disappears from the result.

This differs from covering the lamps. The events are already kept, yet the next operation cannot use all their differences. A more complete recording makes another reading possible. What if the recorded event is something we do with a hand?

<!-- @seed_replay_demo/movement_sampler -->

At MOVE / KEEP, a small dark sphere waits beneath six coloured traces. Carry and turn it. The traces show changes in position and rotation. Release it and a seed appears, a whole number between zero and 999.

The instrument records where and how the point was held, with times. It rounds those measurements, hashes them—a fixed calculation producing a compact code—and reduces the code to one of a thousand possible seeds. The fuller sample record remains available, but the generator receiving the seed gets only that number.

Two different gestures can therefore arrive at the same seed. We have not yet found and kept such a pair in this experiment. It is something to try: retain both recordings, compare their paths, then send their matching seeds to the optional colour window. With the same generator, request order and colour assignment, its pictures should agree. The gestures can remain different to us while that downstream procedure treats them alike.

The first spheres gave numbers a movement. Here movement gives a number back. What could that number be allowed to do next?

<!-- @random_return -->

The larger dark sphere offers a journey. Hold it and the avatar travels with it; release and it finishes alone. Direction and distance vary, but the sphere returns. The destination of this return was decided before the excursion began.

Chance has room to move someone, within a journey whose ending was decided for it. A different seed can offer another excursion. It cannot abolish the obligation to come back.

At the entrance, touch set a body moving along selected axes. Here it encounters another boundary, written into the journey rather than drawn around it. Changing that relation would require a new rule. What part of this experience would we keep—and what would we rebuild so that it could have another consequence?

<!-- @ -->

[^rand]: RAND's [introduction and production account](https://www.rand.org/pubs/monograph_reports/MR1418.html) describes the historical table's production, testing and transformation. The museum's falling page is a separate simulated artifact.
