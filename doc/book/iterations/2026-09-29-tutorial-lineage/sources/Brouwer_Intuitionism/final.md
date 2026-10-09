# Only What You Can Construct

Wait before touching anything.

The game keeps running. The row does not grow. For once, the clock is not the author of the next term.

## A place you have not filled

<!-- @brouwer_choice_sequence -->

Choose **0**. A blue bead appears, with its value above it. Choose **1**. An amber bead follows. Try a few more, then stop.

The question mark stays ahead of what you have made. There is no next value concealed behind it, waiting for the animation to reveal it. The program has not stored one. Your next press will append it:

```gdscript
terms.append(value)
```

We met the array much earlier. Here it holds a record of decisions. The order matters: `0, 1` is not `1, 0`. Waiting changes neither. **RESET** clears this record and lets another beginning happen.

Ask a small question: does your current prefix contain a 1? You can inspect it. If it does, point to a position. If it does not, checking every stored term settles that finite question.

Now imagine continuing without a final term. Will a 1 ever appear? A single chosen 1 would answer yes. However long a run of zeros you have made, that run alone does not show that no later choice will be 1.

The difference is already in your hand: evidence about what has been made, and a claim about every continuation.

Brouwer's choice sequences make room for construction that proceeds through time. Some sequences follow a rule; others admit choices as they develop.[^choice] This bench offers a modest encounter with that distinction. It records a finite binary prefix, shows its latest ten terms and stores at most 256. Filling that storage completes neither infinity nor the philosophical argument. It fills this instrument.

And who chose the things you are allowed to choose? There are two buttons. You may make a rhythm, break it, repeat yourself, refuse to continue. The freedom has a shape before your hand arrives.

## What would count as an answer?

<!-- @excluded_middle_demo -->

Two spheres name **P** and **not-P**. The sign between them means *or*. Move the reading slider. The objects stay; the caption changes the terms under which the statement may be used.

Classical logic permits `P or not-P` without requiring us to settle which. Under the constructive reading, asserting that disjunction calls for a proof of one side. We may have neither proof. That lack is not a third truth value between true and false.[^logic]

Return to your row. The current finite prefix can be checked. An unrestricted question about an indefinitely continuing sequence asks for more. The distinction concerns the claim and its evidence, not whether you happen to feel certain.

Contradiction still has work to do in intuitionistic logic: showing that an assumption leads to contradiction can establish its negation. What is unavailable in general is the further classical move from *not-not-P* to *P*. The slider is a comparison of these readings. It is not a machine deciding an arbitrary proposition for us.

## Show me which one

<!-- @constructive_proof -->

The small cube offers the word *witness* a place to land. To establish that something with a property exists constructively, supply the thing and establish the property. In your row, a position holding 1 is a witness to “there is a 1 here.” A blue cube alone cannot witness every claim written beside it.

Consider a classical existence argument. Let `c = √2^√2`. If c is rational, the irrational pair √2, √2 already gives a rational power. If c is irrational, the irrational pair c, √2 gives `c^√2 = 2`. Either way such a pair exists. This argument does not tell us which pair its case split has supplied.

The constructive demand asks for that missing identification. It changes what we accept as evidence. It does not make every classical proof worthless, or require every mathematical object to be a physical object we have touched.

## A witness you can check

<!-- @cantor_diagonal_workbench -->

At the workbench, set the list size to four. Four rows, four bits in each. Follow the gold diagonal. Underneath it, the red row gives the opposite bit at each position.

Compare the red row with the first row: they disagree at the first position. Compare it with the second: at the second. Keep going. You can point to why the new string differs from every displayed row.

Increase the size. More rows arrive; the earlier bits stay. The construction extends with them:

```gdscript
_d[i] = 1 - _list[i][i]
```

This is a finite stage of diagonalisation. The mathematical argument for infinite binary sequences applies the same rule to every row of a proposed countable list. The headset displays finite strings, up to 32 bits here. Their disagreement is real and inspectable; displaying it does not display the completed infinite object.

You now have two ways of extending a row. At the first bench you choose the next bit. Here a rule determines it from another bit. Both produce something, but they distribute the work differently.

## Whose construction?

<!-- @constructive_staircase -->

Watch the little staircase. Its steps appear on a timer, then dissolve and begin again. Cyan shapes preview what is about to be drawn. This model supplies a construction for you; it does not wait for a decision, and its treads do not carry your body.

Come back to the choice bench and wait again. The contrast is audible even in silence: one apparatus continues; the other leaves you time.

<!-- @angle_sum_triangle -->

<!-- @parallel_lines -->

The triangle and parallel lines return from the earlier geometry. Someone has already supplied their coordinates and relations. A preset is still a construction. What it may conceal is the work by which its particular case supports—or fails to support—a general claim. Look at the displayed shape and ask what the caption adds beyond it.

<!-- @intractable_evidence -->

Back beside the choice bench, the sum over hypotheses brings another limit back from computation. A procedure may be specified and still cost too much to run. That is a different difficulty from having no constructive proof. A formula on a panel cannot tell us, by its appearance alone, which difficulty we face.

This room has not made the world obey your hand. It has made a small part wait for it. Carry that difference onward: what has been asserted, what has been produced, and what follows from the production?

[^choice]: Joan Rand Moschovakis, [Brouwer's Notion of Choice Sequence and Its Descendants](https://www.math.ucla.edu/~joan/Oslonewzoom2022handout.pdf), especially the distinction between lawlike sequences and successive choices. The binary bench is our finite teaching model.

[^logic]: Joan Moschovakis, [Intuitionistic Logic](https://plato.stanford.edu/entries/logic-intuitionistic/), sections 1–2. These explain the restriction on excluded middle, the continued use of contradiction to establish negations, and the constructive interpretation of disjunction and existence.
