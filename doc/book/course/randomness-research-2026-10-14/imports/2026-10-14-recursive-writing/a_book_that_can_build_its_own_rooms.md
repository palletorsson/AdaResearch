# A Book That Can Build Its Own Rooms
*Notes on a recursive writing apparatus for Ada Research*

In Ada Research, two grids of coloured cubes stand beside each other. They are generated from the same random seed and initially display the same arrangement. Press REPLAY and the colours return. Press +1 DRAW and the right grid changes while the left remains untouched. The seed is still the same. One number has simply been consumed before the colours are assigned.

The installation demonstrates something about pseudorandomness: a seed does not determine an image by itself. The program also decides how the generated numbers are interpreted. Here, they become red, green and blue values. Nothing in a random number says that it must become a colour.

While writing about this encounter, another possibility appeared. What if the cubes were allowed to leave their fixed positions? What if a corner of the grid could stretch outward, its squares remaining connected until they formed something like a sleeve? What would happen if a visitor tried to put a hand through it?

The sleeve does not yet exist in the installation. It began as a possibility in the text.

But something has changed in the relationship between writing and programming. We can now take such a passage and ask an AI system to interpret it as a computational proposition, simulate its possible behaviour, and construct an experimental version inside the game.

The resulting object might twist, collapse, catch on the wrist, or behave more like a net than a garment. We don't know. The point of building it would be to find out.

And whatever happens can become the beginning of another passage.

## The text is part of the apparatus

Ada Research is a growing virtual museum constructed in Godot, with rooms dedicated to algorithms, mathematical structures, procedural systems and artificial life. Each room contains interactive artifacts, accompanying programming tutorials and a more reflective literary text.

Until recently, it was relatively easy to imagine this as a familiar division of labour. Programming constructs the world. Writing explains or interprets what has been constructed.

But the process is becoming reciprocal.

A text can describe a situation that does not yet exist. An AI system can translate that description into a provisional model, first as a textual simulation and then, where possible, into an executable scene. The scene can be entered, observed, tested and altered. Its behaviour may contradict the initial description. The discrepancy returns to the writing.

The movement is not simply from text to code.

**Text proposes a world. Code makes one interpretation operational. The resulting world produces observations that change the text.**

In the current development environment, AI can inspect the game's scripts, read the JSON structures defining its rooms, and examine screenshots taken inside the simulation. It can compare what the text claims with what the implementation actually does. It can suggest another construction and examine the consequences.

This does not replace being inside the world. A screenshot cannot tell us whether an object feels awkward to hold, whether a passage is comfortable to cross in VR, or whether an encounter produces the interest we hoped for. But it introduces another observer and another timescale into the research.

The text, the code and the environment can increasingly examine one another.

## Writing across different moments of understanding

I have been thinking about writing as a collaboration of given time.

Writing was never a completely isolated activity. A text inherits language, concepts, conventions, technical instruments, other texts and the labour of people who may have lived centuries before its author. Even a sentence written alone belongs to an extensive history of contributions.

Generative AI makes this condition newly visible, and changes its practical consequences.

A program can now be constructed before I fully understand every part of its implementation. A passage may contain a technical connection, historical reference or theoretical proposition that I did not personally discover. An AI collaborator may recognize a relationship between two artifacts that I had not considered. The resulting material can enter the work before I have exhausted its implications.

This introduces what I think of as **learning debt**.

Learning debt is the distance between what the apparatus has made available and what I presently understand about it.

It need not be concealed or immediately eliminated. It can become a reason to return.

I might encounter a piece of code six months later and investigate why a particular algorithm was chosen. I might read a passage that I did not personally compose and discover a connection worth pursuing. I might find that an earlier description was technically mistaken, but that its mistake suggested an unexpectedly interesting experiment.

Such material cannot simply be treated as established knowledge. Claims still need evidence, implementations need testing, and the contributions of collaborators need to remain traceable. But not understanding something completely when it first enters the work does not necessarily make it useless.

The book can contain questions that its author has not yet learned how to answer.

**The author is not dead. The author is dissipated.**

Authorship is distributed across collaborators, models, code, observations, historical sources and different moments in time. The author remains involved in selecting, questioning, revising and taking responsibility for the work, but is no longer necessarily the sole origin of its contents.

This also changes the role of reading. The author can become a reader of a book they helped produce, encountering knowledge that was not fully available to them at the time of its construction.

## When the apparatus moves while we write

Technological systems have always changed, but the speed and scale of their current transformation create a peculiar difficulty for artistic research.

The environment in which we are working may change while we are describing it. AI models are updated. Tools acquire new capacities. An implementation that required considerable effort a year ago may now be produced in an afternoon. A technique that seemed out of reach may become an ordinary operation.

This changes what learning time means.

In a conventional educational sequence, we establish what is already known and organize a route through that knowledge. The student learns a principle, reconstructs an example, and eventually applies it independently.

There is still a need for this. A programming tutorial should make its mechanism intelligible and reconstructable. If it introduces a particle emitter, the learner should understand how particles are created, updated and removed.

But learning need not end at the boundary of established knowledge.

What happens when we can construct an experiment faster than we can fully anticipate its consequences? What if a student and an AI system build a version of something that neither has previously examined in that form?

The question is no longer only whether the student has understood the lesson. It is whether the lesson has created the capacity to investigate something further.

In Ada, a particle can begin as a point with position and velocity. Later it belongs to a population, is subject to forces, passes through a noise field, collides with boundaries and forms relationships with other particles.

At some point, the tutorial can stop explaining a known outcome and begin asking what would happen if the rules were changed.

Perhaps particles are allowed to establish permanent connections. Perhaps a boundary remembers previous collisions and gradually becomes permeable. Perhaps the field governing their motion is modified by the traces they leave behind.

These become research proposals rather than exercises with predetermined answers.

We construct them because we do not yet know what they will do.

## The book as an experimental environment

This suggests a different architecture for the book.

A passage can be connected to the version of the world from which it emerged. A proposed behaviour can be simulated. An observation can be preserved with the relevant parameters, code and recorded state. A new passage can be connected to the experiment that prompted it.

The relationship need not produce a single final version.

One paragraph might generate several incompatible implementations. One scene might invite several conflicting interpretations. A failed experiment may remain interesting because it reveals a constraint that had previously been invisible.

The book can preserve these divergences instead of forcing them into a continuous account of progress.

In this sense, writing becomes another interface to the game's possibility space. A passage is not necessarily an instruction, but it may contain something that can be turned into an experiment. The simulation does not prove the passage correct; it gives us a particular way of encountering what the passage proposes.

The most interesting moment may be when the simulation refuses our description.

The sleeve falls apart. The noise field fails to produce the expected structure. Two supposedly independent controls turn out to affect the same hidden parameter. A random variation produces an arrangement we want to keep, but the instrument has no mechanism for preserving the relationship that interested us.

These are not only technical problems. They are moments in which the apparatus reveals the limits of its present construction.

And those limits can become the subject of the next experiment.

## An artistic method inside the technological apparatus

I am increasingly interested in how artistic research can operate within technological systems that are too complex, distributed and changeable for any individual to understand completely.

The artist cannot simply assume an external position from which the apparatus becomes transparent. Nor is it sufficient to use technical systems as instruments for producing predetermined aesthetic results.

There is another possibility: to enter these systems, construct partial understandings of their operations, encounter their consequences, and use those encounters to propose different conditions of possibility.

This requires technical precision, but it also requires a willingness to follow observations that interrupt the original intention.

Randomness is a useful starting point. A program may generate millions of different colour arrangements while keeping every cube fixed inside its cell. More random numbers will not change that restriction. To make the cubes connect, detach or become wearable, we must modify the rules governing what is allowed to happen.

The artistic question moves from which result the system produces to why the system permits these particular kinds of results.

The same question can be directed toward the writing apparatus itself.

Who decides which passages are preserved? Which interpretations become canonical? What happens to a contribution whose origin is uncertain? What is excluded when a complex encounter is reduced to a description, a measurement or a screenshot?

The recursive method does not eliminate these questions. It creates ways of returning to them.

## A book we have not yet learned to read

There is something appealing about making a book that does not remain entirely within the knowledge of its author.

Not because obscurity is desirable, or because the accumulation of machine-generated material has value in itself. On the contrary, an apparatus that can produce almost unlimited material creates an even greater need for attention, discrimination and care.

But our attention need not be confined to the moment of composition.

We can encounter the same material later, with different capacities, better instruments or new collaborators. We can reconstruct its experiments, challenge its claims, and find connections that were not apparent when it was first written.

The book becomes a place where knowledge is not only presented but also produced, questioned and transformed.

I don't know how far this method can go. There are real limitations in AI-generated code, automated observation, simulation and the relation between virtual experience and the world beyond it. The apparatus will produce errors, superficial connections and experiments that lead nowhere. Its growing capabilities do not remove the responsibility to investigate what it does.

But that uncertainty belongs to the work.

A text proposes a room. The room is built. Something happens there that the text did not anticipate. We return to the sentence and discover that it can no longer remain exactly as it was.

Then we write again.

**The book is no longer only what we know about the world we are building. It is one of the ways through which that world—and our knowledge of it—can continue to change.**