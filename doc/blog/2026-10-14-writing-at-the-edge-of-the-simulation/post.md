---
title: "Writing at the Edge of the Simulation"
subtitle: "How technical knowledge, critical attention and speculative writing become part of the same experiment"
date: "2026-10-14"
author: "Ada Research"
sequence: "randomness"
tags: ["writing-process", "critical-writing", "artistic-research", "pedagogy", "randomness", "endless-museum"]
thumbnail: "/book-images/blog/2026-10-14-writing-at-the-edge-of-the-simulation/five-spatial-views.png"
---

Two grids of coloured glass stand beside each other in Ada Research, four panes across and four high. They begin with the same seed and the same arrangement. REPLAY brings the colours back. With +1 DRAW, the right-hand picture changes while the left remains as it was. The seed has not moved. One random value was requested and discarded before the next values were assigned to red, green and blue.

This is a small, precise lesson about pseudorandomness. A seed does not name a picture by itself. The generator, the order of requests and the interpretation of each value are part of what makes the image. Nothing in a draw says that it is red.

But perhaps an orange square beside a violet has become a relation you want to keep. Perhaps the new arrangement is more pleasing than the successful replay. The instrument compares two procedures. The visitor may begin comparing pictures for reasons the instrument does not measure.

The literary work begins here, while the mathematical explanation is still changing what we can notice.

![Translucent coloured panes in the Random Definition hall, with other instruments visible through the glass.](/book-images/blog/2026-10-14-writing-at-the-edge-of-the-simulation/glass-close.png)

*The seed instrument's glass grids. The colour arrangement can change; the panes remain within their frames. Godot capture from the museum.*

Ada Research is a programmable, inhabitable museum of algorithms. Its rooms offer encounters with geometry, forces, chance, noise, cellular automata and artificial life. Two kinds of writing accompany them. The tutorial gives a reader the means to construct and investigate an operation, building from the knowledge of previous rooms. The reflective text, called `final.md` in the project, develops the encounter through observation, history, criticism, association and possible futures.

I increasingly think of the final as a **critical instrument** in its own right. Four ways of looking seem especially useful: **edge, leak, technical bias and attachment**.

An *edge* is where an operation reaches a limit. On the colour bench, the random values can recolour a pane, but cannot move it out of its cell. Thousands of seeds can produce thousands of arrangements without changing this geometric restriction. We can locate the rule, alter it and see what happens. The criticism acquires a particular object to work on.

A *leak* is what a description, measurement or representation fails to carry. In the next randomness hall, a Shannon entropy meter gathers symbols into counts. Sorting a sequence changes which colours are neighbours without changing their frequencies. The reading stays the same because this calculation uses the symbol shares and does not include adjacency. Its answer remains correct. The relationships it leaves unanswered become newly interesting.

*Technical bias* concerns the choices built into the apparatus: sampling intervals, distributions, coordinate systems, thresholds, fixed geometry, controllers, default values and the vocabulary of permitted outcomes. These choices shape what the system can recognise and do. They are not automatically evidence of social prejudice. A political argument needs to establish the relation: which bodies an interface accommodates, who can act through it, or which alternatives its design repeatedly excludes.

An *attachment* is harder to specify. It may be a pleasure, discomfort, fascination, recognition or desire to keep something the apparatus treats as disposable. It may begin as a wish to put a hand through a diagram. Such a wish can make us want to understand how the diagram was constructed.

These ways of looking can interfere with one another. An attachment exposes an edge. A measurement's omission draws attention to a design choice. A limitation makes another form desirable. A chapter might follow only one of these movements, or discover something this vocabulary cannot yet name. Requiring all four would make the writing predictable.

A computational artifact stands among more relations than a chapter can hold. One random-number generator connects to probability theory, the engine's draw order, histories of preparing numbers, RGB colour and a visitor's wish to preserve a particular arrangement. A reader encounters these relations one sentence after another. Writing chooses a path through them, leaving others unvisited.

We have been developing a method around that difficulty. Beside the prose sits a research pool containing specific claims, evidence, technical observations, historical sources, critical associations and unbuilt proposals. It preserves more than the chapter will use. A useful fact can wait there until a passage gives it a reason to enter.

Each paragraph has a provisional card: information, job, attitude, reader's gain, bridge and size. The new strategy adds two questions: what critical pressure becomes visible, and what experiment might this suggest? These are prompts for composition. They should disappear into the finished prose, leaving the reader with a discovery rather than the form used to plan it.

The central editorial question is **why should the reader want to know this now?**

Consider RAND's *A Million Random Digits with 100,000 Normal Deviates*, first published in 1955. Its tables made prepared numbers available for repeated consultation; their introduction describes production, testing and use with punched-card machines. After an encounter with a pattern that returns, this history can answer a question the reader has just acquired: how did chance become something researchers could preserve and retrieve? The historical episode changes what the bench means. [RAND's online edition](https://www.rand.org/pubs/monograph_reports/MR1418.html) lets the reader follow the connection further.

A formal definition can enter in the same way. A reader who has watched the right grid change under an unchanged seed has a reason to distinguish initial state from draw order. The definition gives that discrepancy a form they can investigate. Placed before the encounter, it would perform another job; it might establish trust, or it might answer a question nobody has yet asked.

Different routes through the same knowledge pool therefore need different bridges. Merely shuffling complete paragraphs is often insufficient. One route might begin with the mismatch and follow its cause. Another might begin with a desired colour relation, visit the history of stored chance, then return to what the instrument can preserve. Both must earn their transitions.

Some transitions should remain difficult. A collision between a mathematical definition and an unexpected bodily desire may be where an experiment begins. The question is whether the leap produces a consequential encounter or conceals a connection we have not worked out.

In [A Book That Can Build Its Own Rooms](/blog/2026-10-14-a-book-that-can-build-its-own-rooms), I described a possible loop between prose and the running museum. A sentence imagines a corner of the grid coming loose and becoming a sleeve. The proposal began when the cells were cubes. The sleeve remains unbuilt, but the sentence leaves us with concrete questions: which pieces detach, which remain connected, and what would count as following a wrist? Does a line merely draw a connection, or can it transmit force?

We can describe several interpretations before building one: connected rigid cubes, perhaps, or a deformable sheet. Those accounts remain hypotheses. An executable scene gives one interpretation operational form, allowing its movement to be measured, viewed and eventually encountered in VR. It might twist, collapse or suggest an entirely different object. It might also be dull. The experiment needs room to answer back.

The first pilot is smaller and already has a working implementation. It retains forty-eight values as sixteen ordered triples and shows them in five trays: flat colour, neutral bars, coloured bars, scaled cubes and rotated pieces. All five use the same stored inputs. Colour takes the three channels directly; height, size and turn use their mean.

![Five framed trays in the museum show the same stored values as flat colours, neutral bars, coloured bars, scaled cubes and rotated rectangular pieces.](/book-images/blog/2026-10-14-writing-at-the-edge-of-the-simulation/five-spatial-views.png)

*One retained set, five spatial assignments. Actual Godot capture of the seed study: flat colour, bars and their combination across the back, scale and rotation in front.*

This introduces another omission we can inspect. Red `(1, 0, 0)` and green `(0, 1, 0)` have the same mean. The colour view distinguishes them; the height rule gives them equal bars. A representation keeps some differences and collapses others. Changing the receiver of the numbers changes which differences matter.

The pilot's records include desktop runs checking the assignments and the preservation of values through saving and replay. There are museum captures and scripted interaction checks. Independent learner reconstruction and physical headset use remain open. The experiment has made part of the question executable; it has not established what a visitor will understand or enjoy.

The human return has already changed the apparatus in a more specific way. Requests for closer cells, bars with fixed bottoms and simultaneous views changed how the comparison is presented. Those decisions are preserved alongside the versions they prompted. An observation can revise the instrument without obliging both accompanying texts to reach a new conclusion.

**Critique can generate a simulation, and the simulation can criticise the critique.**

The same method can travel beyond randomness. A noise field might become a sculptural surface or walkable ground, but the body's passage also depends on geometry, collision and locomotion rules. A literary association about difficult ground could lead to a controlled change of slope and a new encounter. The account would then need to distinguish what the code demonstrates, what a person reports and what we infer.

AI changes how quickly such propositions can acquire provisional implementations. It can inspect code, propose variants and examine images of a running scene. More material can arrive in a working session than I presently understand. We have been calling that gap **learning debt**. The claim, its source, its uncertainty and a route back to it need to remain available.

The author is dissipated across this work: inherited language, collaborators, instruments, models, observations and different moments of understanding. Responsibility remains with the decisions we make about what to keep, question and publish. An attractive analogy still needs to be distinguished from evidence. A passage can be worth investigating before it is ready to be asserted.

The two texts also need different reading tests. A ghost student tries to reconstruct an operation from the tutorial and identifies missing prerequisites or hidden dependencies. The proposed ghost reader receives the final one paragraph at a time, with later passages withheld. It reports what has become imaginable, what it understands, what question remains active and whether the next paragraph changes an earlier encounter.

The editor's paragraph cards would be shown only after that first reading. Then we could compare the intended job with what the simulated reader actually made of the passage. A transition that seems obvious to its writer may depend on knowledge the reader has never been given.

This is a proposed editorial test, with limited authority. A model can flag a possible gap or an abandoned question; it cannot certify that a human reader felt pleasure, discomfort or productive strangeness. A difficult route may be worth keeping. The purpose of the comparison is to understand where knowledge entered and what it changed, so a person can make a better editorial decision.

A million random images can be generated inside a fixed grammar. A single new connection between two cells can change what forms become possible. Likewise, a chapter can contain a thousand accurate facts without giving the reader a reason to follow them. One observation, placed where it matters, can change an entire encounter.

The book can hold both a selected reading path and a larger archive: alternative explanations, failed simulations, contradictory observations, unfinished experiments and questions still waiting for a useful form. A published edition can stay fixed while that surrounding work continues.

We may return to a sentence months later and discover that it was waiting for a tool, a collaborator or a kind of attention we did not yet possess. We might discover that it was mistaken. Or that the mistake led somewhere we would not otherwise have gone.

The page can propose a room. The room can answer in a language the page did not anticipate. We return to the page to find out what else it has begun to ask.
