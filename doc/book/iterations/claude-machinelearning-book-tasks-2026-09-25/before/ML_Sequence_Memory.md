# What should survive the next input?

How can a learner use the past without keeping every past event equally active?

<!-- @lstms_vr -->

Three spheres float at the edges of a cell you can walk into. Take one and lift it. Nothing about it is trained: its height *is* its value, nought at the floor and one above your head, and the only thing that decides it is where your hand leaves it.

The cell is open at one end. Beside it a rack holds pale tokens and dark ones. Carry a pale token in.

Something changes as it crosses: the cell shifts colour, and out at the far end a slab rides up a post. Carry a dark token in after it. The slab drops past where it started.

Now do it again in the other order. Two dark tokens, one after the other.

Both runs ended with the same dark token. The slab is not in the same place.

That difference is the whole subject of this hall, and it is arithmetic you can follow. Each crossing runs one step:

```gdscript
cell_state = forget * cell_state + input_gate * x
hidden_out = output * cell_state
```

`x` is the token that just crossed — pale is `+1`, dark is `−1`. `cell_state` is what the last crossing left behind. The three gates are the three spheres, wherever you put them. With all three at half height, a pale token then a dark one leaves the slab at −0.125; two dark tokens leave it at −0.375. Same last input, different output, because the first term carried something.

Only the first term reads the past. So the gap between two histories that differ at one earlier step is exactly twice the forget gate times the input gate — nothing else in the rule can produce it.

Put the forget sphere on the floor and run both histories again. They land in the same place, to six decimals. With nothing retained, the last token is all there is, and a history stops being a history.

Raise it instead, and the difference opens. The sphere in your hand is the coefficient on everything that already happened.

A band is painted up the post. From a cleared state no single token can reach it: the admitted term is at most one, and the exposing gate cannot enlarge what it is given. Anything above that line was carried there. The band is not a threshold anyone set — it is where the arithmetic runs out of present tense.

The three kinds of decision are separate, and the readout keeps them separate: what to retain, what to admit, what to expose. A memory has to preserve something while permitting something else to change.

What this is not: the gates are set by hand and nothing here learns. The rule is linear, where a trained network squashes each step through a curve and computes its gates from the input rather than from your arm. Keeping it linear is what lets you predict the next slab height before it moves — and a model you can predict is a model you can be wrong about in a way you can check.

Take the sentence "the key beside the cabinets is missing". Which earlier distinction decides "is" rather than "are"? Something has to survive the intervening words. You have just set, by hand, how much of it does.

<!-- @ -->

Generative learning next changes the task again: a model produces candidates, while another source of feedback judges them.
