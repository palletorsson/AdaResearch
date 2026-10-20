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

This falling page uses its own generated digits. We have selected a group that was already there. What we have changed is how long those digits stay in view. The rows move on around them. The five digits remain available to read again.

<!-- @geiger_counter -->

The Geiger machine is clicking. On its screen:

> seed 435

The colour window displays the same number in large figures. Beside the virtual lamps, a capture also carries seed 435. The opening hand’s path began from it. The number recurs; what it sets in motion changes.

A click. A pause. Another click. Then another pause.

We press RESTART. The first gap returns, then the next. We stay through another click. The screen still reads 435.

This machine detects no radiation. Its waiting times are calculated. Nothing has been added to the recording by listening again.

All 96 detection times were calculated before this playback began. Each calculation advanced the generator’s state and supplied another waiting time. 435 is the seed—the number that set its starting state. This is pseudorandom generation: numbers produced by a repeatable rule. The pauses were kept before we heard them. RESTART plays the stored trace again.[^record]

The beginning has a record of its own.

*Saved acquisition receipt, abbreviated:*[^receipt]

> Received: 13 October 2026, 14:29:02 UTC  
> Provider: RANDOM.ORG · atmospheric noise  
> Requested range: 0–999 · value kept: 435

No new sample of the atmosphere enters with these clicks. The hall opens with the number that was kept. Reusing it preserves a beginning, not an ongoing connection to its source.

Another number can be entered deliberately at the colour window. It becomes the hall’s new seed. Each instrument receives it through its own procedure: a value may become a colour, a waiting time or a destination. Sharing a beginning does not make their sequences identical.

The visible hand’s curve can seem irregular even when its positions are stored. The clicks can remain hard to anticipate after we have heard them return. Knowing that something repeats is not yet knowing its next turn.[^entropy]

A beginning can also be taken from a movement.

<!-- @seed_replay_demo/movement_sampler -->

At MOVE / KEEP, a small dark sphere waits beneath six coloured traces. We pick it up, carry it and turn it. The traces show changes in position and rotation. After a sufficient recording, we release it and a seed appears, a whole number between zero and 999.

The instrument records positions, rotations and times. It rounds those measurements, hashes them—a fixed calculation producing a compact code—and reduces the code to one of a thousand possible seeds. The samples can be kept, along with the number derived from them.

That number becomes the hall’s new beginning. The window and Geiger start from it. Their subsequent values remain pseudorandom: the gesture has supplied an input to the calculation.

Two different gestures can arrive at the same seed. If we kept such a pair, their recorded traces could be compared. Sending their matching seeds to the colour window, with the same requests and colour assignment, would produce matching pictures. The gestures can remain different to us while that procedure treats them alike.

The first spheres gave numbers a movement. Here movement gives a number back.

<!-- @random_return -->

The larger dark sphere offers a journey. We hold it and travel with it; on release, it finishes alone. Direction and distance vary, but the sphere returns. The destination of this return was decided before the excursion began.

Chance has room to move someone, within a journey whose ending was decided for it. A different seed can offer another excursion. It cannot abolish the obligation to come back.

<!-- @ -->

[^record]: The current Geiger model calculates 96 event times and renders their clicks into a stored sound before playback. RESTART replays that sound. Regenerating with the same seed and settings reproduces the times; these are distinct operations. The [435 implementation and test record](../../../2026-10-15-seed-435-middle/README.md) documents the shared seed. The quoted screen excerpt is visible text, not a claim that the internal generator state is displayed.

[^receipt]: Transcription of the [saved acquisition receipt](inputs/algorithms/randomness/seed_replay/opening_seed.json). This is a document in the book, not a newly invented paper receipt in the room. RESET 435 recalls this saved beginning without a network request. A chosen number, restored record or completed gesture recording can change the hall seed; instruments retain private streams.

[^entropy]: A fixed-state deterministic calculation with the same inputs supplies no fresh unpredictability. Offline computers can still receive physical inputs; see the [Linux hardware-RNG documentation](https://docs.kernel.org/admin-guide/hw_random.html) and [NIST’s entropy-source guidance](https://csrc.nist.gov/pubs/sp/800/90/b/final). A recorded gesture is not proof of a true-random source. This distinction concerns the source and procedure, not a prescribed feeling of randomness.
