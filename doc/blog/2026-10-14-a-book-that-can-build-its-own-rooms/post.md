---
title: "A Book That Can Build Its Own Rooms"
subtitle: "Notes on a recursive writing apparatus for Ada Research"
date: "2026-10-14"
author: "Ada Research"
sequence: "randomness"
tags: ["writing-process", "artistic-research", "authorship", "learning", "endless-museum", "randomness"]
thumbnail: "/book-images/blog/2026-10-14-a-book-that-can-build-its-own-rooms/glass-close.png"
---

In Ada Research, two grids of coloured glass stand beside each other. They are generated from the same random seed and initially display the same arrangement. REPLAY brings the colours back. With +1 DRAW, the right grid changes while the left remains untouched. The seed is still the same. One number has simply been consumed before the colours are assigned.

The installation demonstrates something about pseudorandomness: a seed does not determine an image by itself. The program also decides how the generated numbers are interpreted. Here, they become red, green and blue values. Nothing in a random number says that it must become a colour.

![Two grids of translucent coloured glass in the Random Definition hall, with the museum visible through their panes.](/book-images/blog/2026-10-14-a-book-that-can-build-its-own-rooms/glass-close.png)

*The seed experiment in its current form: two four-by-four glass grids. An actual Godot capture from inside the museum.*

While writing about an earlier version of this encounter, when the cells were cubes, another possibility appeared. What if the cubes were allowed to leave their fixed positions? What if a corner of the grid could stretch outward, its squares remaining connected until they formed something like a sleeve? What would happen if a visitor tried to put a hand through it?

The sleeve does not yet exist in the installation. It began as a possibility in the text.

We can take such a passage and ask an AI system to interpret it as a computational proposition: choose a way to connect the squares, propose a model of their movement, and construct an experimental version inside the game. Before that version runs, any account of its behaviour remains a conjecture. The object might twist, collapse, catch on the wrist, or behave more like a net than a garment. The point of building it would be to find out.

Whatever happens can become the beginning of another passage.

Ada Research is a growing virtual museum constructed in Godot, with rooms dedicated to algorithms, mathematical structures, procedural systems and artificial life. Each room contains interactive artifacts, a programming tutorial and a reflective literary text. The tutorial gives a student one example they can reconstruct, drawing on knowledge from earlier rooms. The reflection can move through the encounter, its history, its formal conditions and the possibilities those conditions exclude.

It is easy to imagine a familiar division of labour here. Programming constructs the world. Writing explains or interprets what has been constructed. But the process is becoming reciprocal.

**Text proposes a world. Code makes one interpretation operational. The resulting world produces observations that change the text.**

The development tools already let an AI collaborator inspect scripts, read the JSON structures defining rooms, run checks and examine screenshots taken inside the simulation. A claim in a passage can be compared with the rule actually implemented. A proposed construction can be tried, and its consequences examined. These are working parts of the process; the fully connected book imagined here is still something we are making.

A screenshot cannot tell us whether an object feels awkward to hold, whether a passage is comfortable to cross in VR, or whether an encounter interests a student. Those questions require other kinds of evidence. The code, the image and the person inside the headset each give us access to something different. Their disagreements can be useful.

I have been thinking about writing as a collaboration across different moments of understanding.

A text inherits language, concepts, conventions, technical instruments, other texts and the labour of people who may have lived centuries before its author. Even a sentence written alone belongs to an extensive history of contributions. Generative AI changes how quickly material from beyond my present understanding can enter the work, while often making its origins difficult to establish.

A program can be constructed before I understand every part of its implementation. A passage may propose a technical connection or a historical relation that I did not discover. An AI collaborator may suggest a relationship between two artifacts that I had not considered. The material arrives before I have exhausted its implications—and sometimes before I know whether it is sound.

This introduces what I think of as **learning debt**: the distance between what the apparatus has made available and what I presently understand about it.

That distance can become a reason to return. I might encounter a piece of code six months later and investigate why a particular algorithm was chosen. I might read a passage I did not personally compose and find a connection worth pursuing. An earlier description might turn out to be technically mistaken, while its mistake suggests an interesting experiment.

Learning debt needs to remain visible. A claim still needs evidence; an implementation needs testing; a contribution needs whatever provenance we can establish. An uncertainty cannot quietly become a fact because it has survived several revisions. But material does not have to be fully understood at the moment of its arrival to become the beginning of useful work.

The book can contain questions that its author has not yet learned how to answer.

**The author is not dead. The author is dissipated.**

Authorship spreads across collaborators, models, code, observations, historical sources and different moments in time. I remain responsible for selecting, questioning and revising what enters the book. The origins of its contents are more distributed than the name on the cover suggests. Later, I can become a reader of the book I helped produce, encountering something I could not yet follow when it was written.

![The Random Definition writing study, with a shared knowledge pool beside two alternative paragraph timelines and drafts.](/book-images/blog/2026-10-14-a-book-that-can-build-its-own-rooms/writing-routes.png)

*An earlier writing trial: one pool of connections, two routes through it. This is the browser writing desk, showing how the same material can acquire a different order. It is a record of the experiment at that stage, rather than the current hall text.*

The apparatus also moves while we write. Models are updated, tools acquire capacities, and the effort needed to construct an experiment changes. We can sometimes build something faster than we can anticipate its consequences. That makes the relation between making and learning less orderly than a syllabus might suggest.

The tutorial still has a definite responsibility. If it introduces a particle emitter, the learner should understand how particles are created, updated and removed. Earlier code can be referred to rather than printed again, provided the route back is clear. The new mechanism must be intelligible enough to change deliberately.

Then the lesson can create a capacity to investigate further.

In Ada, a particle can begin as a point with position and velocity. Later it belongs to a population, is subject to forces, passes through a noise field and collides with boundaries. Each lesson adds something that can be used in another situation. A student and an AI collaborator might eventually combine these operations in a form neither has examined before.

Perhaps particles establish permanent connections. Perhaps a boundary keeps a record of collisions and gradually becomes permeable. Perhaps the field governing motion changes in response to the traces left behind. These are proposals for experiments. The rules can be specified carefully even when the resulting encounter remains unknown.

This suggests an architecture for the book. A passage could link to the version of the world from which it emerged. An observation could be preserved with its parameters, code and recorded state. A new passage could point back to the experiment that prompted it. A reader could follow the route from an assertion to the conditions under which someone observed it.

The relationship need not produce a single final version. One paragraph might generate several incompatible implementations. One scene might invite conflicting interpretations. A failed experiment may remain worth keeping because it reveals a constraint that had been invisible. The book could preserve those divergences alongside the route selected for its main text.

A passage is not automatically a specification. Turning the sleeve into a scene requires choices the sentence has left open: what a connection permits, how far it stretches, whether it breaks, what counts as contact. The resulting simulation gives us one way to encounter the proposal. It also exposes the decisions made while translating it.

The most interesting moment may be when that implementation refuses our description. The sleeve falls apart. Two supposedly independent controls affect the same hidden parameter. A random variation produces an arrangement we want to keep, but the instrument cannot preserve the relationship that interested us. The failure makes a condition of the apparatus available for inspection.

I am interested in how artistic research can work inside technological systems too complex and changeable for one person to understand completely. We construct partial understandings, encounter their consequences, and propose different conditions. This requires precision, alongside a willingness to follow observations that interrupt the original intention.

Randomness is a useful place to begin. A program may generate millions of colour arrangements while keeping every pane fixed inside its frame. More random numbers will not loosen the frame. To make cells connect, detach or become wearable, we must change the rules governing what is allowed to happen.

The artistic question moves from which result the system produces to why it permits these particular kinds of results. A sleeve is interesting here because it gives the grid another relationship to a body. The body ceases to be only the visitor looking at an arrangement. It might enter the arrangement, carry it, or find itself caught by it.

The same questions return to the writing apparatus. Who decides which passages are preserved? Which interpretation becomes the main text? What happens to a contribution whose origin is uncertain? What disappears when an encounter becomes a measurement, a paragraph or a screenshot?

Our [writing-pattern experiments](/blog/2026-10-13-a-room-of-connections-a-line-of-text) began with a pool of connections and several possible routes through it. Linear writing selects what a reader meets, when they meet it, and what they know at that moment. The other connections need somewhere to remain. They may be the material for a later passage, another reader, or another room.

There is something appealing about making a book that exceeds its author's present knowledge. An apparatus capable of producing almost unlimited material also creates a greater demand for attention and care. Generation is easy to mistake for progress. The useful question is whether something has become available to investigate, understand, contest or enjoy.

Our attention need not be confined to the moment of composition. We can return with different capacities, better instruments or new collaborators. We can reconstruct an experiment, challenge its claims and find a connection that was not apparent when it was written. Some learning debts will be repaid; others will turn out to be promises we should never have accepted.

I do not know how far this method can go. It will produce errors, superficial connections and experiments that lead nowhere. Its growing capabilities leave us with more to investigate, and with choices about what deserves the time.

A text proposes a room. The room is built. Something happens there that the text did not anticipate. We return to the sentence and discover that it can no longer remain exactly as it was.

Then we write again.
