# Writing at the Edge of the Simulation

*How Ada Research makes technical knowledge, critical attention and speculative writing part of the same experiment*

Two grids of coloured cubes stand beside each other in Ada Research. They are four cubes across and four high. A number above them is their seed. Press REPLAY and the colours return. Press +1 DRAW and the right-hand picture changes while the left remains as it was. The seed has not moved. One random value was requested and discarded before the next values were assigned to red, green and blue.

This is a small, precise lesson about pseudorandomness. A seed does not name a picture by itself. The generator, the order of requests and the interpretation of each value are part of what makes the image. Nothing in a draw says that it is red.

But there is something else happening in the room. Perhaps an orange square beside a violet has become a relation you want to keep. Perhaps the new arrangement is more pleasing than the successful replay. The instrument compares two procedures. The visitor has begun comparing pictures for reasons the instrument does not measure.

This is where the literary work begins—not when the mathematical explanation ends, but while the explanation is still changing what we can notice.

## An instrument has an edge

Ada Research is a programmable, inhabitable museum of algorithms. Its rooms offer encounters with coordinates, geometry, forces, chance, noise, cellular automata and artificial life. There are two principal kinds of writing beside them. The tutorial gives a reader the means to construct and investigate an operation. The reflective text, called `final.md` in the project, develops the encounter through observation, history, criticism, association and possible futures.

I increasingly think of the final not as an explanation added to the work but as a **critical instrument** in its own right. It looks for four kinds of pressure: **edge, leak, technical bias and attachment**.

An *edge* is where an operation reaches a limit. In the colour bench, the random values can recolour a cube, but they cannot move it out of its cell. Thousands of seeds can produce thousands of palettes without changing this geometric restriction. The edge is not an abstract complaint that computation is controlling. It is a specific property of the implemented system. We can locate the rule, alter it, and see what happens.

A *leak* is what a description, measurement or representation fails to carry. In the next randomness hall, a Shannon entropy meter gathers symbols into counts. Sorting a sequence changes which colours are neighbours without changing their frequencies. The entropy reading remains the same because its calculation does not include adjacency. That does not make the calculation incorrect. It makes the question it answers exact—and makes the relationships it leaves unanswered newly interesting.

*Technical bias* concerns the choices built into the apparatus: the sampling interval, distribution, coordinate system, threshold, fixed geometry, controller affordances, default values and vocabulary of permissible outcomes. These are not all examples of social prejudice, and we should not pretend that they are. But they are decisions about what the system can recognize and do. Sometimes those decisions become critical or political when we investigate who can act through them, which bodies they accommodate, or which alternatives they systematically exclude.

An *attachment* is more difficult to specify. It may be a pleasure, discomfort, fascination, recognition or desire to keep something the apparatus treats as disposable. It may begin as a wish to put one's hand through a diagram. This is not noise surrounding the knowledge. It may be what makes us want the knowledge at all.

The four pressures can interfere with one another. An attachment can expose an edge. A measurement's leak can reveal a technical decision. A bias can make an unexpected form desirable. None must be present in every room. To require one of each would turn critical writing into a predictable checklist.

## From a network of knowledge to a line of desire

A computational artifact stands in a dense network of relations. One random-number generator connects to probability theory, cryptography, RAND's 1955 tables of random digits, John Cage's chance operations, the engine's draw order, the visual vocabulary of RGB colour, and the question of what a visitor chooses to preserve. The object connects to more things than one chapter can reasonably hold.

A reader, however, encounters one sentence after another. Writing chooses a path through that network. Every path makes certain relations easier to notice and leaves others unvisited.

We have been developing a writing method around this difficulty. Beside the prose sits a research pool containing specific claims, evidence, technical observations, historical sources, critical associations and unbuilt proposals. A paragraph is selected not because its knowledge is impressive but because it has a job to do at that moment: introduce a discrepancy, make a mechanism intelligible, complicate a promise, create an appetite for history, or change what an earlier encounter meant.

Each paragraph has a provisional card: information, job, attitude, reader's gain, bridge and size. We now need two additional questions: what critical pressure becomes visible, and what further experiment might it suggest? These cards are instructions to the writer, not headings to be printed in the finished essay.

The central editorial question is **why should the reader want to know this now?**

Consider the historical RAND number book. It might be a dry insertion into a description of the seed bench. But if the reader has just encountered a pattern that returns, the history answers a newly interesting question: how did chance become something researchers could preserve and retrieve? The historical episode changes what the bench means. It does not merely add background information.

In the same way, the sphere that carries a visitor on a randomly chosen excursion complicates the word *return*. The sphere returns to its origin without necessarily repeating the same movement. A saved seed can reproduce an assigned sequence without reconstructing the visitor's first experience. The book can travel through these different kinds of return because each makes the previous one stranger.

Not all edges between subjects should be smooth. A collision between a mathematical definition and an unexpected bodily desire may be exactly where an experiment begins. The question is whether the discontinuity produces a consequential encounter or merely hides a missing connection.

## An association can become a test

What distinguishes this literary practice from a critical essay written after an artwork is the possibility of returning an association to the running system.

A sentence in the Random Definition text imagines a corner of the grid coming loose and becoming a sleeve. That is an artistic association, not a current feature of the bench. But it can be treated as a proposal. Which cubes detach? Which remain connected? What would count as following a wrist? Does a line between cubes merely draw a connection, or can it transmit force?

We can text-simulate several interpretations of that sentence. One might describe connected rigid cubes, another a deformable sheet. Neither textual account demonstrates how an executable scene behaves. A Godot version can then give one interpretation operational form, and the resulting movement can be measured, viewed or encountered in VR.

Perhaps the cubes twist, collide or fall apart. Perhaps the result is boring. Perhaps it suggests a different object altogether. The point is not to make the original metaphor come true. It is to let the experiment answer back, including by contradicting the writing.

We have chosen a smaller first pilot: retain forty-eight values used by a four-by-four colour grid, then interpret those same values as cube heights while keeping their colours. This comparison is mathematically predictable; its job is to establish the round trip between a passage, a reconstructable implementation, observation and revision. The sleeve can remain open until another encounter gives us a stronger reason to build it.

The same method applies beyond randomness. A smooth noise field can become a sculptural surface or a walkable terrain, but the visible surface and the body's permitted passage also depend on geometry, collision and locomotion rules. A literary association about difficult ground can therefore lead to a controlled change of terrain height or slope, a VR encounter and a revision of the original critique. We should distinguish what the code demonstrates, what a person reports, and what we infer from those results.

**Critique can generate a simulation, and the simulation can criticize the critique.**

## Learning time and dissipated authorship

AI has changed how quickly a computational proposition can become a provisional implementation. It can inspect code, propose scene variants, reason through a text simulation and examine screenshots of the game. This does not mean every interpretation is correct, nor that a simulated reader can certify a human encounter. But it changes the amount and scale of material that can enter a working session.

Sometimes a scene will contain a mechanism I do not yet fully understand. Sometimes a passage will introduce a relation proposed by another person or AI collaborator. The gap between what the apparatus has made available and what we currently understand is a form of **learning debt**. Rather than quietly concealing the gap, we can preserve it: the claim, its source, its uncertainty, and a possible route back to it.

This is why I have been saying that the author is not dead; **the author is dissipated**. Writing was always a collaboration across inherited language, other people's knowledge, instruments and time. The new apparatus makes that condition more operational. The book may hold propositions that its initiating author will only understand later, after reconstructing the code or encountering another version of the room.

Responsibility has not disappeared. An unverified scientific assertion must not be published as fact merely because an AI proposed it. An attractive analogy is not evidence. Authorship now includes the work of distinguishing these states, making consequential editorial decisions and leaving the conditions of further investigation visible.

The ghost student can try to reconstruct a mechanism from the tutorial and identify missing prerequisites. A companion ghost reader can encounter the final one paragraph at a time, reporting when a question was created, answered too soon, abandoned or transformed. Neither test establishes that a human reader felt desire, pleasure or productive strangeness. Those need people and editorial judgment.

## A book that can learn

The ambition is not to produce endlessly more text or more procedural variation. A million random images can be generated inside a fixed grammar. A single new connection between two cubes can change what forms are possible. Likewise, a thousand accurate facts can fill a chapter without giving the reader a reason to follow them. One well-placed observation can change the meaning of the entire encounter.

The tutorial teaches us to make an operation understandable and reconstructable. The final looks at what that operation permits, leaves out, privileges and unexpectedly makes us want. The simulated world allows these questions to become experiments. The experiments, in turn, may change the two texts, the museum or the order in which we thought we should work.

The book becomes both a reading path and a larger archive of alternatives: retained explanations, failed simulations, contradictory observations, unfinished experiments and questions that have not yet found a useful form. A published edition can remain fixed while this wider apparatus continues changing.

We may return to a sentence months later and discover that it was waiting for a tool, a collaborator or a kind of attention we did not yet possess. We might discover that the sentence was mistaken. Or that the mistake led somewhere we would not otherwise have gone.

The critical artistic position, then, is not an ability to stand outside an increasingly complex technological system and explain it completely. It is the capacity to work precisely inside that system, find where its operations meet their limits, follow the attachments those limits produce, and reconstruct a world in which the next question becomes possible.

The page can propose a room. The room can answer in a language the page did not anticipate. We return to the page, not simply to correct it, but to find out what else it has begun to ask.

---

*Ada Research · Working blog draft · 14 October 2026. The RGB/height experiment and sleeve are proposals; they are not reported here as completed Godot or VR encounters.*
