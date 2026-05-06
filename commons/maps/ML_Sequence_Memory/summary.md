# ML Sequence Memory — Summary

ML_Sequence_Memory is the sixth map in the Machine Learning sequence. It introduces recurrence — the practice of feeding a network's hidden state back into its own input at the next step — and makes memory a property of a shared connection rather than a separate module.

A recurrent network sits at the centre of the space. Its hidden state is drawn as a coloured bar above the neuron body, and the feedback connection loops visibly from the output back to the input. Short text sequences scroll into the network one token at a time; the hidden state changes with each input and carries traces of previous tokens forward. A readout panel at the output shows the network's prediction for the next token in the sequence.

A second station demonstrates the vanishing-gradient problem. The same network is run on longer sequences, and a diagnostic panel traces how much influence each input token still has on the final output. The trace decays as inputs recede into the past; by ten steps back, the influence is nearly zero. A toggle swaps in an LSTM cell, whose gated memory decays much more slowly.

Within the sequence, this map adds the temporal dimension that feedforward networks lack. ML_Generative will next build generation on top of it.
