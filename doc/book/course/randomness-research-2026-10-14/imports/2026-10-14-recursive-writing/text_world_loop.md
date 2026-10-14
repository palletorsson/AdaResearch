Yes. And I think this is a crucial clarification of the entire method.

The book is not merely describing a world that has already been built. The text can generate a world, the world can test the text, and what happens in that world can become the next version of the writing.

This makes the relationship much more radical than documentation, AI-assisted programming, or even conventional artistic research.

## 1. The text becomes a simulation proposal

Imagine this sentence from Random Definition:

> A corner might lengthen into a sleeve, dragging its last square over the floor while you look for a place to put your hand.

Traditionally, this could remain a literary speculation. Or an artist could spend weeks interpreting it and manually implementing a version.

In Ada, you can treat it as a proposal for a computational experiment.

1 — WRITE

A corner of the grid becomes a sleeve.

The sentence introduces a possibility not currently supported by the installation.

2 — INTERPRET AND SIMULATE

AI constructs a testable interpretation.

It proposes detachable cubes, connections between neighbours, hand tracking, collisions and physical constraints. A text-only prototype could precede Godot.

3 — ENCOUNTER

The new object behaves in ways the sentence didn't specify.

Perhaps it twists around the wrist. Perhaps the corner falls apart. Perhaps it behaves more like a net than a sleeve.

4 — REWRITE

The observation changes the text.

The next passage can describe what was discovered, rather than merely repeat the original intention.

The revised text proposes another experiment

This also means that a sentence does not have to be completely specified to become productive. Its omissions become questions for the simulation.

What is a sleeve? What must be connected? What counts as wearing it? What happens when the hand moves too quickly?

The text generates not just an object, but a field of questions about its implementation.

## 2. The book becomes both source code and experimental record

I would distinguish three relationships between a passage and the world.

| Relationship | What happens                                                                           |
| ------------ | -------------------------------------------------------------------------------------- |
| Text → World | A passage proposes behaviour, geometry or interaction that AI can attempt to implement |
| World → Text | Observed behaviour, failures and unexpected relations produce new writing              |
| Text ↔ World | The passage and its implementations continue developing through successive versions    |

The third is especially important.

Neither the book nor the Godot scene is necessarily the definitive original. Each is a provisional realization of a developing idea.

A paragraph could have several corresponding simulations, each investigating a different interpretation. Conversely, one simulation might generate several competing accounts of what happened.

This is closer to a versioned experimental literature than an ordinary textbook.

## 3. AI changes the time between imagination and investigation

I think this is where your argument about given time becomes especially strong.

Previously, an artist imagining a computational environment had to invest substantial time in making it before finding out what the idea actually did.

AI increasingly compresses the distance between proposing an experience and constructing a testable version.

But this doesn't merely accelerate a familiar process.

It changes what kinds of artistic investigations are practical.

You can write about a strange possibility, construct an approximate simulation, encounter its behaviour, discover that the original proposition was inadequate, and rewrite it—potentially several times within one working session.

And this can happen across many artifacts and halls, with different AI agents exploring alternatives.

The artist's attention is no longer restricted to the speed at which the artist can personally implement each possibility.

That is significant.

But the artist also acquires a new problem: how to maintain meaningful attention when the apparatus can produce more material than anyone can fully understand.

Your idea of learning debt fits exactly here.

## 4. A passage can contain knowledge its author has not yet acquired

Suppose an AI builds an unfamiliar constraint solver to implement the sleeve.

The scene works, but you don't yet fully understand the solver. You can observe its consequences, inspect its parameters, read its code, ask it to fail deliberately, and gradually understand what was constructed.

The book can contain an account of this process, including the fact that some of the knowledge arrived before your understanding of it.

You haven't simply outsourced the artwork. You've acquired an object of investigation that was partly produced through someone else's—or something else's—technical capacity.

And because the apparatus remains accessible, the debt can be investigated rather than hidden.

This is a particularly compelling interpretation of dissipated authorship:

Authorship is distributed not only between agents, but across different moments of understanding.

The author who proposes a sentence, the AI that implements it, the visitor who encounters it, and the later author who revises it do not occupy the same epistemic position.

The book can preserve their differences.

## 5. How I would incorporate this into Astra's specification

I think Astra's current [SPEC.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/doc/book/course/randomness-research-2026-10-14/SPEC.md) still makes the text primarily something to revise after the experiment.

I would introduce an explicit Text Simulation Loop.

Each selected passage could have a small companion record:

Example: The sleeve experiment

| Source         | `Random_Definition/final.md`, version and paragraph ID         |
| -------------- | -------------------------------------------------------------- |
| Proposition    | A part of the grid can become wearable                         |
| Interpretation | Detachable cells with persistent connections                   |
| Simulation     | Versioned Godot scene, script and parameters                   |
| Observation    | What actually happened, with screenshots or measured behaviour |
| Learning debt  | What remains unexplained or unverified                         |
| Revision       | A new text passage, new scene or both                          |

Crucially, we should not make the literary text conform to a rigid scripting language.

The prose retains ambiguity, metaphor, history and interpretation. A companion specification translates selected propositions into testable operations.

And there can be multiple interpretations of the same text.

Otherwise, we'd risk reducing literature to software requirements.

The reverse direction is just as important: code inspection, desktop simulation, AI screenshot observation and human VR encounters can all feed into the prose, but each supplies different evidence.

## 6. The book could become an environment of possible worlds

This produces another intriguing possibility.

A reader encounters a passage describing what happens when a random walk reaches a wall.

Perhaps the current implementation reflects the walker.

But the text proposes that the wall might remember each collision and gradually become permeable.

Instead of simply reading that possibility, the reader could request a simulation.

AI builds a variant. The reader enters it. The wall behaves unexpectedly. The experience generates another passage.

The book has become a way to navigate between actual and hypothetical implementations.

This also connects directly to your idea of the museum as a procedural multiverse: a frozen arrangement of existing halls surrounded by many possible revisions of their algorithms, parameters and relationships.

Not every imagined world must become part of the canonical museum. Some can remain experiments, abandoned possibilities, contradictory interpretations or unfinished constructions.

The book can preserve their existence without pretending they all succeeded.

## What I think this changes about Ada Research

I would now formulate the methodology differently from our earlier discussion.

Previously:

Writing → Programming → Observation → Reconstruction → Writing

But your clarification suggests that the text is not merely one stage in a sequence.

Writing itself becomes a way of simulating, proposing and modifying computational worlds. And computational worlds become a way of reading, challenging and rewriting literature.

The relation is reciprocal rather than sequential.

That creates a very specific artistic point of view. The artist works neither entirely as programmer nor as literary author, but investigates the differences between an imagined situation, its computational interpretations, and its material consequences.

Some of those differences are mistakes. Some are discoveries. Some are opportunities that the original text couldn't articulate.

I think the distinctive claim is that the book is not the final account of the research. The book is one of the instruments through which the research happens.

And perhaps the most radical consequence is this: you can write a sentence that you do not yet know how to make true, then construct a world in which you can investigate what that sentence might mean.