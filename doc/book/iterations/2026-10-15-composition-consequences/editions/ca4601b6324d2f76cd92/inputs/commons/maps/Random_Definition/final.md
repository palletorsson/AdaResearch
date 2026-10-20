# What chance is allowed to do

<!-- @random_touch -->

We stand before three thin lines hanging in the air, two metres apart. Each is two metres long, with a dark sphere waiting at its centre. We can see the room behind and between them.

We touch the first sphere. The hand visible in the room follows it sideways. Our viewpoint stays still. The sphere slows into one position, then departs for another. We can see how far it is allowed to go. Its next turn remains uncertain.

At the next line, the hand follows the same path twice as quickly. The positions repeat. The line has not grown, but there is less time inside the same distance. With the third sphere, we return to the slower pace. The visible hand rises and falls as well as moving sideways. The space above the line becomes available to the movement.

We withdraw our hand. Its visible position follows our own movement again; the sphere returns alone to its centre. No trace of the passage remains on the line. Yet the path has not been lost.

The positions are kept in the program. We press REPLAY and touch the first sphere again. The turns return in the same order. The next movement can still be unfamiliar, even though the whole sequence has been kept.

<!-- @random_number_book_page_1955 -->

Further into the room, we come to a large page of falling numbers. A small stand in front says “select”. The numbers arrive from above, one row at a time, in groups of five digits. We touch a group. It turns amber and stays while the surrounding numbers continue downwards. We take our hand away. The digits remain.

Our touch has acquired another consequence. At the sphere, we began a movement. Here, we have made a small still place in the fall.

RAND's *A Million Random Digits*, published in 1955, made a supply of numbers available for calculations using random selections. Producing that supply required testing and correction: its electronic source introduced biases, systematic departures from the intended even distribution. The published table preserved the results after further processing. Random numbers could be returned to at a numbered page. [RAND's production account](https://www.rand.org/pubs/monograph_reports/MR1418.html).

This falling page uses its own generated digits. We have selected a group that was already there. What we have changed is how long those digits stay in view. The rows move on around them. We read the five digits again.

<!-- @geiger_counter -->

The hall’s random-generating instruments share a beginning: 435. The colour window, the virtual lava lamps, the Geiger machine, even the falling page start from that number. Their differences are already visible. One beginning has become colours, rising forms, clicks and a path.

Click. A gap. Another click. The Geiger machine is already running. A physical Geiger counter detects radiation; this one calculates a sequence of detection times. No radioactive source is connected. We replay the sequence and hear the same gaps return.

435 is its seed: the number used to set the generator's starting state. Each calculation changes that state and supplies another value, which becomes a waiting time before a click. The seed stays 435 while the state advances. Resetting the same procedure to that beginning, with the same settings, produces the same sequence. This is pseudorandom generation: a repeatable calculation whose results can be difficult to anticipate.

The number has a history. A saved receipt records 435 arriving from RANDOM.ORG's atmospheric-noise service on 13 October 2026. The window reuses that receipt when the hall opens; it makes no fresh request on arrival. An acquired number has become a kept beginning. Its origin does not make every later click a new measurement of the atmosphere.[^arrival]

A seed need not be chosen randomly. At the colour window we can select a different number directly. It becomes the starting seed throughout the hall. RESET 435 restores the saved beginning; no new random selection is needed. The calculation remains; its beginning changes. Sharing 435 also does not make every object perform the same sequence: the generator, the order of requests and the assignment of values to colour, time or position matter too.

The visible hand's curve may appear random while following stored positions. The clicks may resist anticipation while repeating exactly. Our impression depends partly on what we can perceive and remember. Within a deterministic calculation, a fixed state and the same inputs supply no fresh uncertainty. The next encounter changes an input.[^entropy]

<!-- @seed_replay_demo/movement_sampler -->

At MOVE / KEEP, a small dark sphere waits beneath six coloured traces. We pick it up, carry it and turn it. The traces show changes in position and rotation. After a sufficient recording, we release it and a seed appears, a whole number between zero and 999.

The instrument records where and how the point was held, with times. It rounds those measurements, hashes them—a fixed calculation producing a compact code—and reduces the code to one of a thousand possible seeds. This recording was made during our visit. Its derived seed becomes the hall’s new beginning. The window changes; the Geiger starts another sequence of gaps. Their subsequent values are still pseudorandom. Keeping the recording allows its seed to be derived again. The gesture supplies an input, without establishing a source of true randomness.

Two different gestures can therefore arrive at the same seed. We have not yet found and kept such a pair in this experiment. We could retain both recordings, compare their paths, then send their matching seeds to the colour window. With the same generator, request order and colour assignment, its pictures should agree. The gestures can remain different to us while that procedure treats them alike.

The first spheres gave numbers a movement. Here movement gives a number back. What could that number be allowed to do next?

<!-- @random_return -->

The larger dark sphere offers a journey. We hold it and travel with it; on release, it finishes alone. Direction and distance vary, but the sphere returns. The destination of this return was decided before the excursion began.

Chance has room to move someone, within a journey whose ending was decided for it. A different seed can offer another excursion. It cannot abolish the obligation to come back.

At the entrance, touch set the visible hand moving along selected axes. Here the whole body travels, and encounters another boundary, written into the journey rather than drawn around it. Changing that relation would require a new rule. What part of this experience would we keep—and what would we rebuild so that it could have another consequence?

<!-- @ -->

[^arrival]: The saved [opening receipt](../../../algorithms/randomness/seed_replay/opening_seed.json) records the value, provider, range and acquisition time. Each random-generating instrument in Random Definition starts a private stream from the shared hall seed. A manual choice, restored record or completed gesture recording can change it. The [435 revision](../../../doc/book/iterations/2026-10-15-seed-435-middle/README.md) records implementation and verification. The frame trace measures timing without reseeding the hall.

[^entropy]: Offline does not mean isolated from physical inputs: local hardware can supply entropy, as described in the [Linux hardware-RNG documentation](https://docs.kernel.org/admin-guide/hw_random.html). [NIST's entropy-source guidance](https://csrc.nist.gov/pubs/sp/800/90/b/final) distinguishes entropy sources from deterministic generators. The claim here concerns fixed-state computation, not the impossibility of physical randomness in a computer.
