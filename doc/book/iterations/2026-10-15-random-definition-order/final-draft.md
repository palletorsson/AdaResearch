# What chance is allowed to do

<!-- @seed_replay_demo -->

Two small windows hold the same arrangement of coloured squares. REPLAY brings the picture back, down to its neighbours. Yet +1 DRAW changes the right-hand window while the number above it stays the same. One value has been passed over before the colours are assigned. The picture depended on where we began reading, as well as what we read. What sort of chance can keep an appointment this precisely?

<!-- @prng_crank_machine -->

The crank offers an answer slowly enough to watch. A state is multiplied, increased and reduced to the machine's range. The result becomes the next state. This is a pseudorandom generator: a deterministic procedure producing a sequence for uses that require random-like values. A seed establishes its starting state. Keep the procedure, state and requests the same, and the values return. Their return gives us something to work on twice.

<!-- @film_prng_register -->

On the neighbouring register film, the arithmetic occupies blocks of bits. Sixteen outputs can be recovered from the same beginning. The number that seemed to arrive alone has a predecessor.

<!-- @seed_replay_demo/source_console -->

But where did the beginning come from? The source console keeps different answers available. The opening 435 was received from RANDOM.ORG, which uses atmospheric noise, then saved here. The request had already limited the answer to an integer between zero and 999.[^atmosphere] Replaying the picture consults the kept number; the weather is not being asked again.

<!-- @random_number_book_page_1955 -->

A book once made a vast supply of such returns possible. RAND's *A Million Random Digits*, published in 1955, supplied numbers for sampling calculations. Its electronic source required testing and correction before publication.[^rand] Here the book's sculptural relative lets its digits fall. Touch holds one cell while others depart. The historical table made a number available later. This page makes keeping it an event.

<!-- @seed_replay_demo/frame_timing -->

Beside it, the frame study measures the application's intervals. An uneven trace can look like chance arriving directly from the machine. But the display has shown us a measurement, not established how unpredictable its source is. A jagged line can persuade the eye before we know what made it.

<!-- @trng_vs_prng -->

The comparison exhibit separates calculating from state and measuring a physical source of uncertainty. Physical-source generators need an account of their source, measurement and processing; a convincing display cannot supply that account. The virtual streams here remain simulations where their implementations say so. An animation can let us investigate an apparatus without becoming a physical entropy source.

<!-- @lava_entropy_wall -->

Through the doorway, coloured bodies rise inside the virtual lamps. A synthetic sensor samples their arrangement. Cover part of its view and the recorded input changes although the same lamp state can be retained. Something happens between a scene and its becoming a number. The sensor decides which part of the movement can enter the record.

<!-- @geiger_counter -->

The Geiger study makes measurement audible. Its simulated detections click across a recorded stretch of time. A finer or coarser clock can extract different bits from those same events. The clicks need not change for their numerical account to change. Stay with the silence between two of them; the apparatus must decide how finely to distinguish its duration.

<!-- @seed_replay_demo/movement_sampler -->

Now a hand can supply the arrival. MOVE / KEEP records a movement and derives a seed. The gesture becomes usable by the generator, but the integer cannot tell its whole story. A pause, a turn and the reason for either exceed what this encoding promises to keep.

<!-- @seed_study -->

At the five trays, forty-eight stored values acquire several jobs. Triples make colour; their means set height, size or rotation. A bar keeps its foot planted while its top rises. These arrangements share numbers without sharing a form. The entrance window looks different in memory: colour was one assignment among others. What must we rebuild to give a value another kind of consequence?

<!-- @random_return -->

The dark sphere makes the question bodily. Holding it joins an excursion; releasing it leaves the sphere to finish alone. Direction and distance vary, but return is prescribed. Chance has room to move someone, within a journey whose ending was decided for it. Imagine allowing a passenger to change the return. That would require a new rule, not merely another seed.

<!-- @slot_machine -->

At the exit, the reels stop one after another. Their delay gives expectation time to gather around an outcome. A count can retain the symbols without retaining that wait. The next hall begins counting. Which part of what happened has become a number, and which part still asks for another form?

<!-- @ -->

[^atmosphere]: RANDOM.ORG documents its atmospheric source and bounded requests in its [HTTP interface](https://www.random.org/clients/http/api/). The initial 435 is a saved response from 13 October 2026, retained in `algorithms/randomness/seed_replay/opening_seed.json`; it is not a continuous feed.

[^rand]: RAND's [introduction and production account](https://www.rand.org/pubs/monograph_reports/MR1418.html) describes the table's sampling uses, electronic generation, testing and transformation. Falling digits are the museum artifact's authored behaviour.
