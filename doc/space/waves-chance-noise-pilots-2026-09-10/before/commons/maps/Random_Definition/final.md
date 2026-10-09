# A pattern that returns

Can a pattern look unpredictable and still return exactly?

<!-- @seed_replay_demo -->

Choose a small part of the coloured grid that you can recognise: perhaps a bright corner or a surprising pair of neighbouring colours. Press REPLAY and look there again. Compare more than one cell before deciding whether anything changed.

Use RANDOM to choose another seed, then replay that result too. The grid changes when its starting state changes; replaying the same starting state reconstructs the same arrangement. You can also choose a seed with the slider. Nearby numbers need not produce nearby-looking pictures.

Choose a little arrangement involving several cells, such as a corner and its two neighbours. Name their colours and their order before pressing REPLAY. Matching one colour might happen by coincidence; matching the arrangement gives you a more demanding check. Try another location as well. After RANDOM, inspect the same positions rather than searching elsewhere for something that resembles your original patch. The comparison concerns what the procedure reconstructs at particular addresses. Moving your attention to a convenient match would change the question. If you remember the earlier seed, returning the slider to that value offers another way to test the same construction across an intervening change.

The colours are produced by a pseudorandom generator. It begins in a state selected by the seed and follows a definite procedure to supply successive values. Those values become colour channels in a fixed sequence of cells. The picture can be difficult to predict by looking at it while remaining reproducible by repeating its construction.

This separates irregular appearance from uncertainty about the procedure. Calling a grid random because you cannot see a pattern is a report about your reading. Reconstructing it from the same seed is evidence about how this particular generator behaves.

Ask another visitor to choose the picture they find least predictable. Replaying it does not make their first impression foolish; it answers a different question. A surprising result can have a repeatable cause.

The seed is not an independent name for the image under every possible program. Change the generator, its parameters or the order in which values are used, and the same seed can yield another result. Reproducibility belongs to the whole procedure.

<!-- @ -->

The entropy gauge next asks what a numerical description can retain from a sequence. Keep appearance, construction and measurement separate: a number about the output will not automatically tell you everything about how it was made.
