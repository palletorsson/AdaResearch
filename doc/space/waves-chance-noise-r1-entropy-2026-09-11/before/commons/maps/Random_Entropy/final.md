# What the gauge forgets

What can one number tell you about the uncertainty in a sequence?

<!-- @shannon_entropy_meter -->

Look at the symbol strip and the frequency bars before reading the large number. Find a symbol that appears often in the visible strip and another that appears less often. Compare their bars, remembering that the strip shows only part of the sample used to make the histogram.

Now compare the entropy reading with the maximum marked on the gauge. The source gives each of ten symbols an equal chance, but a finite collection of draws need not contain exactly equal counts. The bars record that particular sample, rather than drawing the ideal distribution as if it had already happened.

Choose two neighbouring symbols in the strip and ask whether their closeness tells you which has the taller frequency bar. Then look for another occurrence of either symbol elsewhere in the strip. The strip makes order visible; the bars collect occurrences regardless of where they appeared. Describe one fact that is easy to read from each view and difficult to recover from the other. You might follow a repeated pair in the strip while comparing a whole symbol's share in the histogram. Keep the sample sizes in mind: the shorter strip is a window into the sequence, so its apparent favourite need not lead the full count.

The calculation uses each symbol's proportion in the sample. A more concentrated distribution makes some outcomes easier to anticipate; a more even distribution over the same symbols has greater entropy by this measure. The maximum also depends on how many symbols are available. A number without that context would be difficult to interpret.

Imagine gathering all occurrences of each symbol together so the sequence reads as a series of sorted blocks. You have changed the order dramatically without changing a single count. What would happen to this gauge's number?

It would remain the same. This calculation measures individual-symbol frequencies. It does not inspect the dependencies between successive symbols, and it does not know whether their order forms a message, a rhythm or a useful instruction. A high reading is not a certificate of meaninglessness; a low one is not a certificate of value.

<!-- @ -->

The gauge presents a completed sample rather than a distribution you can edit here. A future ordering comparison could make its omission visible side by side. In the next room, the eligible set becomes spatial: before anything is removed at random, a rule has already decided what can be chosen.
