# PG: N-grams

A bigram remembers one step back. A trigram, two. An N-gram slides a window of fixed width across a sequence and asks: given this context, what comes next? Frequency becomes probability. Probability becomes prediction. The window never sees the whole — only the local pattern, the last few tokens, the recent past.

Where Markov chains forget everything before the current state, N-grams carry a small suitcase of history. Larger N means sharper prediction, tighter constraint — but also exponential hunger for data. The curse of dimensionality is really a curse of memory: the more you remember, the more you need to have seen.

Count what follows what. Build a table. Sample from it. The output sounds almost like language — coherent locally, drifting globally. Structure without comprehension. Pattern without meaning. Every autocomplete is an N-gram's ghost, guessing the next word from a window that never opens wide enough to understand the sentence.