# What should survive the next input?

How can a learner use the past without keeping every past event equally active?

<!-- @lstms_vr -->

Three spheres float at the edges of a cell you can walk into. Take one and lift it. Nothing about it is trained: its height *is* its value, and the only thing that decides it is where your hand leaves it. The scale is coarser than floor-to-head, though. A sphere reads nought anywhere below a metre, reaches one only at three metres, where no hand goes, and where the three hang, two metres up, it reads one half.

The cell is open at one end. Beside it a rack holds pale tokens and dark ones. Carry a pale token in.

Something changes as it crosses: the cell shifts colour, and out at the far end a slab rides up a post. Above the post a readout prints the step, the retained term f*c, the admitted term i*x, and c and h to three decimals. Carry a second pale token in after the first. The slab climbs again, by less.

Now clear the cell and run a different history. The rule contains its own reset: put the forget sphere and the input sphere on the floor, carry any token through once, and the readout shows c back at nought, whatever it held. Hang the two spheres back where they were, as near as your hand allows; the numbers below assume exactly half, and the readout will show you how far off you are. Then a dark token, and a pale one after it.

Both runs ended with the same pale token. The slab is not in the same place.

That difference is the whole subject of this hall, and it is arithmetic you can follow. Each crossing runs one step:

```
c = f*c + i*x    h = o*c
```

`x` is the token that just crossed — pale is `+1`, dark is `−1`. `c` is what the last crossing left behind, `h` is what the slab shows, and `f`, `i` and `o` are the three spheres, wherever you put them. With all three at half height, two pale tokens leave the slab at 0.375; a dark token then a pale one leave it at 0.125. Same last input, different output, because the first term carried something.

Only the first term reads the past. So the gap in `c` between two histories that differ at one earlier step is exactly twice the forget gate times the input gate — nothing else in the rule can produce it — and the slab shows that gap scaled once more by the exposing gate. Here: one half in `c`, a quarter on the post.

Put the forget sphere on the floor and run both histories again; no clearing is needed now, because nothing is kept. They land in the same place, to every decimal the readout prints. With nothing retained, the last token is all there is, and a history stops being a history.

Raise it instead, and the difference opens. The sphere in your hand is the coefficient on everything that already happened.

A band is painted up the post. From a cleared state no single token can reach it: the admitted term is at most one, and the exposing gate cannot enlarge what it is given. Anything above that line was carried there. The band is not a threshold anyone set — it is where the arithmetic runs out of present tense.

The three kinds of decision are separate, and the readout keeps them separate: what to retain, what to admit, what to expose. A memory has to preserve something while permitting something else to change.

What this is not: the gates are set by hand and nothing here learns. The rule is linear, where a trained network squashes each step through a curve and computes its gates from the input rather than from your arm. Keeping it linear is what lets you predict the next slab height before it moves — and a model you can predict is a model you can be wrong about in a way you can check.

Take the sentence "the key beside the cabinets is missing". Which earlier distinction decides "is" rather than "are"? Something has to survive the intervening words. You have just set, by hand, how much of it does.

<!-- @ -->

Generative learning next changes the task again: a model produces candidates, while another source of feedback judges them.
