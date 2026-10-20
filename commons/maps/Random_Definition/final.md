# What chance is allowed to do

<!-- @random_touch -->

We stand before a small abacus. Five thin rods sit one above another, each a metre long, with a dark bead waiting at its centre. Behind them, a pale wall waits for marks.

We touch the first bead. The hand visible in the room follows it sideways. Our viewpoint stays still. The bead slows into one position, then departs for another. We can see how far it is allowed to go. Its next turn remains uncertain.

At the next row, the hand follows the same path twice as quickly. The third doubles that pace; the fourth doubles it again. The positions repeat. The rods have not grown, but there is less time inside the same distance. At the fifth bead, we return to the second row's pace. The visible hand rises and falls as well as moving sideways. The bead leaves the line that first seemed to contain it.

Small transparent circles gather behind the moving bead. Where they overlap, the wall darkens. We withdraw our hand. Its visible position follows our own movement again; the bead returns alone to its centre. The marks stay. Movement has left something we can examine without continuing to move.

The wall records twelve positions within each step. A faster bead draws sooner; after the same number of steps, the first four rows hold the same pattern. The fifth spreads its marks above and below the rod. The targets were selected uniformly, giving equal chances to equal intervals. The marks also include the journey between targets. A crowded middle can suggest a Gaussian distribution: a bell-shaped spread with most values near the average. Here, a central mark may record a crossing rather than a destination. The resemblance does not establish a Gaussian source.

The positions are kept in the program. We press REPLAY: the paper clears. We touch the first bead again. The turns return in the same order, and the marks gather again. The next movement can still be unfamiliar, even though the whole sequence has been kept.

<!-- @random_number_book_page_1955 -->

Further into the room, we come to a large page of falling numbers. A small stand in front says “select”. The numbers arrive from above, one row at a time, in groups of five digits. We touch a group. It turns amber and stays while the surrounding numbers continue downwards. We take our hand away. The digits remain.

Our touch has acquired another consequence. At the bead, we began a movement that left marks. Here, we keep a group already passing through the page. We have made a small still place in the fall.

RAND's *A Million Random Digits*, published in 1955, made a supply of numbers available for calculations using random selections. Producing that supply required testing and correction: its electronic source introduced biases, systematic departures from the intended even distribution. The published table preserved the results after further processing. Random numbers could be returned to at a numbered page. [RAND's production account](https://www.rand.org/pubs/monograph_reports/MR1418.html).

This falling page uses generated digits. The same sequence takes different forms: colour in the window, five digits on the page. We have selected a group that was already there. What we have changed is how long those digits stay in view. The rows move on around them. We read the five digits again.

<!-- @geiger_counter -->

The hall’s random-generating instruments share a beginning: 435. The colour window, the virtual lava lamps, the Geiger machine, even the falling page start from that number. Their differences are already visible. One beginning has become colours, rising forms, clicks and a path.

Click. A gap. Another click. The Geiger machine is already running. A physical Geiger counter detects radiation; this one calculates a sequence of detection times. No radioactive source is connected. We replay the sequence and hear the same gaps return.

435 is its seed: the number used to set the generator's starting state. Each calculation changes that state and supplies another value, which becomes a waiting time before a click. The seed stays 435 while the state advances. Resetting the same procedure to that beginning, with the same settings, produces the same sequence. This is pseudorandom generation: a repeatable calculation whose results can be difficult to anticipate.

The number has a history. A saved receipt records 435 arriving from RANDOM.ORG's atmospheric-noise service on 13 October 2026. The window reuses that receipt when the hall opens; it makes no fresh request on arrival. An acquired number has become a kept beginning. Its origin does not make every later click a new measurement of the atmosphere.[^arrival]

A seed need not be chosen randomly. At the colour window we can select a different number directly. It becomes the starting seed throughout the hall. RESET 435 restores the saved beginning; no new random selection is needed. The calculation remains; its beginning changes. Sharing 435 also does not make every object perform the same sequence: the generator, the order of requests and the assignment of values to colour, time or position matter too.

The visible hand's curve may appear random while following stored positions. The clicks may resist anticipation while repeating exactly. Our impression depends partly on what we can perceive and remember. Within a deterministic calculation, a fixed state and the same inputs supply no fresh uncertainty. The next encounter changes an input.[^entropy]

<!-- @seed_replay_demo/movement_sampler -->

A small dark sphere waits beneath six coloured traces. We pick it up, carry it and turn it. The traces show changes in position and rotation. After a sufficient recording, we release it and a seed appears, a whole number between zero and 999.

The recording keeps positions, turns and times. A fixed calculation condenses those measurements into the displayed number.[^gesture] The window changes; the Geiger begins another sequence of gaps. Keeping the recording lets us derive that seed again. The movement supplies a new input; the numbers that follow are still pseudorandom.

There are only a thousand possible seeds here. Two different gestures can become the same number. We have not yet kept such a pair. Their traces could remain different while the window, given the same seed and settings, repeats its colours.

The first spheres gave numbers a movement. Here movement gives a number back. What could that number be allowed to do next?

<!-- @random_return -->

The larger dark sphere is already travelling out from the centre and back. We hold it and travel with it. At the entrance, the bead moved the visible hand; here the floor passes beneath us.

Direction and distance can change between excursions. The centre stays where it was.

We release it. The sphere continues without us.

It returns to the centre.

<!-- @ -->

[^arrival]: The saved [opening receipt](../../../algorithms/randomness/seed_replay/opening_seed.json) records the value, provider, range and acquisition time. Each random-generating instrument in Random Definition starts a private stream from the shared hall seed. A manual choice, restored record or completed gesture recording can change it. The [435 revision](../../../doc/book/iterations/2026-10-15-seed-435-middle/README.md) records implementation and verification. The frame trace measures timing without reseeding the hall.

[^entropy]: Offline does not mean isolated from physical inputs: local hardware can supply entropy, as described in the [Linux hardware-RNG documentation](https://docs.kernel.org/admin-guide/hw_random.html). [NIST's entropy-source guidance](https://csrc.nist.gov/pubs/sp/800/90/b/final) distinguishes entropy sources from deterministic generators. The claim here concerns fixed-state computation, not the impossibility of physical randomness in a computer.

[^gesture]: The sampler stores timed positions and orientations at finite precision. It hashes the stored measurements, using a fixed calculation to produce a compact code, then reduces that code to an integer from 0 to 999. The record retains the measurements as well as the derived seed; the seed alone does not reconstruct the gesture. Desktop mode samples the carried point; VR mode samples the tracked controller. The six traces show changes between accepted samples, not the complete motion. See the [tutorial](tutorial.md) for recording, replay and reconstruction.
