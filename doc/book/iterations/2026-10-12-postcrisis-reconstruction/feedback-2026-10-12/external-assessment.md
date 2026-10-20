# Post-Crisis — Critical assessment of the eight-hall sequence

Ada Research · 12 October 2026 · Tutorials, reflections and technical review

My judgment: Post-Crisis is one of the most significant sequences in Ada Research because it moves from criticizing computational systems toward reconstructing the conditions under which they could work differently.

Following Foundations Crisis, this is an important change of direction. Foundations investigated the limits of formal descriptions, proof, representation and justification. Post-Crisis asks what we can do once those limitations have become visible.

Its strongest idea is that critique should be able to become a material intervention: change an arrangement, retain a disagreement, preserve a source, revise a connection, construct another body and see what survives.

The eight halls build toward an unusually concrete ending. A student alters a body in the Assembly Laboratory, saves its positions and connections, then encounters that actual saved arrangement in the final hall. The result is not merely a metaphorical return: the curriculum implements continuity between the two spaces.

## 1. The eight-hall progression

| Hall                           | Central operation                                    | Conceptual question                                        |
| ------------------------------ | ---------------------------------------------------- | ---------------------------------------------------------- |
| 01. Algorithmic Bias           | Compress or spread authored word positions           | Which distinctions remain recognizable?                    |
| 02. Applied Ethics             | Rearrange six equal seats                            | How can space distribute opportunities before anyone acts? |
| 03. Paraconsistent Engineering | Preserve conflicting reports while choosing a branch | Must disagreement be erased to proceed?                    |
| 04. Situated Computation       | Cover or reveal a claim's source                     | What gives an assertion its apparent authority?            |
| 05. Collective Knowledge       | Separate contributions, sources and revisions        | When does accumulation become knowledge?                   |
| 06. Rhizome Network            | Add, remove and reroute graph connections            | What makes another path possible?                          |
| 07. Assembly Laboratory        | Edit the positions and connections of a body         | What other bodies can this arrangement become?             |
| 08. Synthesis                  | Reconstruct and compare a saved body                 | What survives an intervention, and what is lost?           |

There is a coherent development here:

Representation → Arrangement → Disagreement → Provenance → Contribution → Connectivity → Reconstruction → Return.

Unlike some earlier sequences, which collect related computational techniques, Post-Crisis develops a sustained argument about the possibility of changing an existing world.

## 2. The strongest achievement: Assembly → Synthesis

This is the passage I find most consequential, both artistically and technically.

In Assembly, the student encounters a recognizable human figure made from thirteen joints and twelve connections. But the system does not enforce anatomical proportions. The hand can move without pulling the elbow, and a connection can be reassigned without moving either endpoint.

The reflection makes a particularly strong observation:

> A body can look as though it is coming into being while it is coming into agreement with a description.

That sentence describes the automated assembly exhibit, where pieces move toward predefined destinations. It exposes a distinction between apparent emergence and fulfillment of an authored specification.

The student's own interaction reverses that relationship. Instead of observing pieces move toward an existing description, the student can change the description itself.

One example is particularly effective: rerouting a connection from a hand to the head isolates the hand and creates a loop elsewhere in the figure. The number of points and connections remains unchanged, but the topology changes.

The difference between position and connectivity, first established in earlier graph and geometry lessons, becomes an investigation into what makes a configuration recognizable as a body.

And the final room retains the altered configuration.

This is much stronger than simply displaying the same artifact twice. The intervening decisions survive a scene boundary, allowing the student to encounter their own work from another position.

The final reflection puts this precisely:

> The hand has arrived. Your hand is missing.

The destination survives, but the gesture that produced it does not. This is simultaneously a technical property of the saved data and a compelling observation about memory.

I consider this one of the strongest spatial and literary passages in the material you've shared.

## 3. The most sophisticated educational decision: separating numerical equality from ethical equality

The first two tutorials are deliberately simple.

Algorithmic Bias changes distances between labelled words. Applied Ethics places six identical seats in different arrangements.

In both cases, the student can measure a real computational difference. But the texts explicitly refuse to equate that difference with a social conclusion.

In the seating exercise, geometric equality does not establish equal participation.

In Algorithmic Bias, increased separation between words does not establish fair representation of the people or experiences those words supposedly describe.

I think this distinction is essential, especially following Machine Learning and Foundations Crisis.

However, it also produces the sequence's first major weakness.

The political concepts are significantly richer than the computational mechanisms that represent them.

A six-word arrangement cannot establish algorithmic discrimination. Six chairs cannot demonstrate participatory justice. The reflections acknowledge these limits, but the installations still depend heavily on analogy.

I would keep the examples, yet consider one additional experimental step: allow students to change the classification criteria or seating constraints themselves, rather than only adjusting the provided arrangement.

That would move the exercise from examining an authored critique toward examining how the terms of the comparison are constructed.

## 4. Collective Knowledge is the most intellectually vulnerable hall

I like the distinction between contributions, contributors, participations and revisions.

The tutorial demonstrates that adding three objects does not imply having three independent sources. It also demonstrates that revising an existing contribution does not count as another contribution.

Those are valuable operations.

But the installed system is not actually a collaborative knowledge process. It simulates arrivals from twelve predefined source positions. A visitor can dispute or revise an object, but the system cannot evaluate whether the revision is warranted.

The text openly acknowledges this.

My criticism is that the gap between simulating collaboration and actually enabling collaboration may be particularly important for Ada Research.

This is an AI-assisted project already involving multiple forms of authorship, technical delegation and editorial judgment. A genuine collaborative layer could eventually connect the computational example to the conditions under which the museum is produced.

For instance, the system might preserve alternative descriptions of an artifact, record why someone revised an interpretation and allow another participant to contest the revision.

That would be a much more substantial investigation of collective knowledge than counting contributions.

It would also be a larger software project. I would treat it as a future research direction, not a prerequisite for completing this tutorial.

## 5. Rhizome is an excellent bridge, but its limitations should remain visible

The Rhizome Network lesson introduces the largest new algorithmic step in the student reconstructions: nearest-neighbour selection, graph adjacency and connected-component traversal.

The progression into Assembly is excellent.

First, the student discovers that changing a connection can alter which routes exist without moving any points. Then, in Assembly, that same operation changes which parts of a figure belong to the same connected body.

The reflection's walkable cave adds a particularly useful distinction: two visible passages can cross at different heights without creating a traversable junction.

However, the cave is an authored construction, not the automatically generated result of the small network. The tutorial states this correctly.

There is also a deeper tension with the philosophical concept of the rhizome. The network grows within a predefined boundary and attaches to nearby earlier points. Time and proximity influence which places become well connected.

It has no central root, but that does not make it free of hierarchy or structural privilege.

This is an interesting critical opportunity. The exhibit could make the difference between decentralized connectivity and genuinely revisable organization more explicit.

A network without a declared centre can still be governed by rules that its participants cannot change.

## 6. The strongest technical improvement: genuine continuity across lessons

One of my recurring criticisms of earlier sequences was that their conceptual continuity was sometimes greater than their computational continuity.

The same point appeared in many rooms, but the student often started with a separate program and separate data.

Post-Crisis goes further.

The learner code explicitly inherits earlier implementations from Euclid, Russell and Florensky. The graph model developed in Rhizome becomes part of the Assembly model. Synthesis then reuses the body representation and file validator.

Most importantly, the Assembly record is actually written and read in another Godot process.

# 114

Reported model and interaction checks passed

# 109

Reported native hall checks passed

The validation covers all eight reconstructions, including graph traversal, invalid data rejection, simulated hand interactions and persistence of the complete saved body.

These are author-operated tests, not an independent learner evaluation or physical VR walkthrough.

I also inspected the supplied screenshots. The working stations appear consistently positioned within the museum, but their repeated desk-and-button format gives several different concepts a similar visual treatment. That helps programming instruction but may reduce experiential distinction.

The native logs retain engine warnings and errors, including an unresolved resource UID, a viewport-texture error in Applied Ethics and several reported long artifact construction times. These do not invalidate the passing model checks, but they deserve investigation before sustained headset testing.

## 7. The fundamental limitation: revisability is not yet accountability

This is my most important criticism of the final chapter.

The saved record preserves positions, connections and edit count. It does not preserve the path of the hand, the person's intention, a complete revision history or evidence of the effects of the intervention.

The reflection understands this and makes it part of the artwork.

But there is a meaningful distinction between:

Making a system editable, making an edit reversible, and making a decision accountable.

Post-Crisis convincingly implements the first. It partially supports the second through reconstruction and renewed editing. It identifies the third as a question, but it does not yet implement the social and evidential conditions that accountability would require.

I would not try to solve this by simply collecting more user information.

A better extension might let a student attach an observation to one saved change: what they expected, what happened and why they chose to keep it.

That would connect the data structure to the experimental methodology already developed throughout Ada Research without pretending to capture the entire encounter.

## 8. What changes in my assessment of Ada Research

There is an important difference between Foundations Crisis and Post-Crisis.

Foundations investigates what we can justify.

Post-Crisis investigates what we can reconstruct, preserve and change.

That is a strong transition because it avoids ending philosophical critique in a general statement about the limitations of knowledge.

The new sequence makes limitations productive. If a classification suppresses a distinction, perhaps its criteria can change. If two records conflict, perhaps both can remain available for investigation. If an arrangement excludes a participant, perhaps its geometry can be modified. If a body is constrained by its connections, perhaps another connection is possible.

But the project also encounters a new problem: the ability to generate alternatives does not tell us which alternatives deserve to persist.

That question connects Post-Crisis back to Genetic Evolution, Machine Learning, Swarm and the earlier experiments with objective functions and selection.

And it connects directly to your own AI-assisted artistic process. The capacity to produce variations has expanded enormously. The work of observing, selecting, documenting and critically evaluating them becomes correspondingly important.

## Final judgment

I would preserve the eight-hall structure and the current reflections. The sequence is conceptually coherent, and its strongest moments arise directly from implemented operations rather than from philosophical language attached afterward.

Its main weakness is that the first five halls sometimes use simplified technical analogies for questions about power, fairness, collaboration and responsibility. The later halls become more convincing because students can actually reconstruct spatial relations and carry their interventions forward.

The most important achievement is the final transition from critique to authorship.

The student is no longer only identifying the limitations of a system designed by someone else. They are beginning to alter the conditions under which that system produces bodies, relations and possibilities.

And the final line is well chosen:

> The clock is still running. There is something you wanted to make.

It refuses to conclude the investigation with either a theorem or a completed object.

Of the sequences I've reviewed, Post-Crisis makes one of the clearest attempts to turn Ada Research's philosophical ambition into an actual research practice: identify a limitation, construct a different relation, preserve the consequence and return to investigate what the change made possible.

That is a significant step in the development of the museum as a whole.