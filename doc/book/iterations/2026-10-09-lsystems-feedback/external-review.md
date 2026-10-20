# L-systems — Critical assessment of the eight-hall sequence

Ada Research · 9 October 2026 · Tutorials, reflections and review evidence

My overall judgment: L-systems is one of the strongest sequences so far in terms of conceptual progression. It achieves something that the Fractals sequence began: separating a generative procedure from the interpretation that gives its results a visible, spatial or interactive form.

More importantly, it takes that separation beyond strings and drawing. By the end, students can distinguish rewriting, interpretation, environmental constraints, design parameters, geometric selection and random sampling.

This is not a simple course about producing procedural trees. It is a course about how instructions acquire bodies, and how those bodies acquire possibilities that their instructions do not explicitly contain.

## 1. The eight-hall progression

| Hall                    | Central operation                                          | New conceptual capacity                                          |
| ----------------------- | ---------------------------------------------------------- | ---------------------------------------------------------------- |
| 01. Grammar Lab         | Rewrite a string, then interpret it                        | Separate symbolic production from drawing                        |
| 02. Growth              | Save and restore turtle state using brackets               | Understand inheritance, branching and state                      |
| 03. Grammars and Curves | Interpret one sentence through different readers           | Distinguish instruction from execution                           |
| 04. Architecture        | Turn paths into footprints, floors and walls               | Make a symbolic route physically inhabitable                     |
| 05. Competition         | Give two trees turns in a shared resource field            | Investigate order, environmental constraint and unequal outcomes |
| 06. Living              | Change parameterized designs while preserving a witness    | Distinguish continuous editing from discrete structural changes  |
| 07. Shape Grammars      | Replace and extrude selected mesh faces                    | Transfer rewriting from symbols to geometry                      |
| 08. Assemblage          | Retain random samples while changing their visual alphabet | Separate selection, appearance and perceived relationships       |

The progression is much more interesting than simply increasing algorithmic complexity. Each new hall asks what additional decisions are needed to make the previous operation matter in a new context?

## 2. What works exceptionally well

### The distinction between sentence and reader

The transition from Grammar Lab through Growth to Grammars and Curves is excellent.

A sentence can remain unchanged while its interpretation changes. The same `F` might draw upward in one reader and sideways in another. A change in turning angle may have no immediate effect until a turning instruction is actually encountered.

That makes a fundamental computational distinction available through observation: the data alone does not contain the full behavior of the system interpreting it.

### Architecture is the decisive spatial transformation

The fourth hall asks:

> Can a line admit you?

This is an effective question because the answer is not automatically yes.

A turtle can draw a route through space without producing a corridor. The architectural generator must add footprints, shared floor cells, boundaries, walls and entrances.

The interesting operation is not merely extruding a line. It is deciding which spatial relationships are to become physically consequential.

This develops the bodily inquiry already present in Menger Sponge, where a geometric opening was not necessarily a passage for a human-sized collision body.

### Competition brings history and environment into the grammar

This is perhaps the most important conceptual extension.

Two trees use the same branching instructions, but their roots draw upon overlapping soil resources. Whichever acts first receives a different starting condition from the second.

The order of execution therefore matters.

It is a good demonstration that unequal outcomes need not originate in unequal internal instructions. They can emerge because the environment is modified by earlier actions.

And unlike the more deterministic examples, this begins to introduce the possibility that one generated structure changes the conditions under which another can develop.

## 3. Living introduces an important problem: a parameter change is not necessarily a structural change

The depth control advances continuously, but the generation count is rounded to an integer. Several movements of the control can therefore produce the same structure before a threshold is crossed.

This is a valuable lesson about the relationship between interface, parameter space and generated form.

It also reveals a more general limitation: the available controls define which kinds of variation are possible.

The tutorial states that the generated sentence can request 4,964 commands, while the reader displays at most 200. This means a tree can look complete while the program has only interpreted part of the generated description.

That is a strong distinction between what was requested, what was computed and what was actually constructed.

## 4. Shape Grammars is an appropriate expansion, not a departure

I agree with the decision to extend beyond string rewriting.

Students have already worked with cubes, triangles, arrays and transformation hierarchies. Replacing selected mesh faces is a natural transfer of that knowledge.

The particularly interesting operation is selection.

The generator must decide which faces remain eligible for further modification, how their identities survive changes to the mesh, and how their descendants are handled.

This makes the lesson more than a geometry exercise. It asks how a program maintains the identity of something while transforming its structure.

However, I see a pedagogical risk: the concepts of mesh topology, stable selection and reverse-index replacement arrive together. Even at this advanced stage, I would make sure students can identify the selection operation before examining the complete mesh-building implementation.

## 5. Assemblage is an excellent ending

This is perhaps the strongest philosophical conclusion of the sequence.

A field of independent marks produces apparent lines, routes, enclosures and other relationships.

The program has not constructed those paths as connected objects. The visitor finds them.

The reflection asks:

> When you see a path in this textile, who connected its pieces?

That is a particularly effective question for Ada Research, because it does not reduce the answer to either the algorithm or the human observer.

The algorithm generated individual marks. Their spatial arrangement makes relationships perceptible. The observer follows a connection that the generator never explicitly stored.

This leads to an important distinction:

The structure a program generates is not necessarily the structure a visitor experiences.

The final independent exercise is also considerably stronger than many earlier assignments. Students must choose an unprescribed modification, predict a result, identify an invariant, run the comparison and preserve evidence of what happened.

This is close to the experimental research practice your reflections advocate.

## 6. My main criticisms

### A. The breadth of the sequence creates a problem of disciplinary identity

Only the early lessons are straightforwardly about L-systems.

Architecture adds occupancy grids and collision geometry. Competition introduces resource allocation. Shape Grammars operates directly on mesh faces. Assemblage uses independent random samples rather than recursive symbolic rewriting.

The documents explicitly acknowledge those distinctions, which is good.

I would not remove these lessons, but I would make the sequence's broader proposition more visible:

L-systems introduces a separation between generating instructions and interpreting them. The later halls investigate what happens when that separation is transferred to other computational systems.

That makes the progression coherent without pretending everything is an L-system.

### B. Competition is powerful but its ecological interpretation must remain limited

The order-of-execution experiment is excellent. The model shows how two identical branching systems can receive unequal resources because they operate sequentially on overlapping soil.

But this is not a general ecological model of competition.

For example, the supplied experiment notes that reversing the execution order changes which tree receives the larger allocation, while the soil remaining after both turns is identical.

That is an exact property of this particular consumption model, not a general principle about competitive systems.

The tutorial is careful about this, and I would preserve that precision.

An interesting additional experiment would be to let resource use affect later geometry, thereby creating feedback between the tree's growth and the environment from which it draws resources. That would extend the model, rather than merely adding more visual detail.

### C. The reflection is sometimes ahead of the physical encounter

The strongest reflections allow a visitor to discover a material difference before interpreting it.

Architecture does this well: an abstract line becomes a wall that can stop the visitor.

Competition is also strong: changing turn order produces an observable inequality.

Some other passages make sophisticated distinctions that may be easier to understand from the text than from the immediate encounter.

The question I would apply to each hall is: Can the student discover the main conceptual distinction through action before reading the explanation?

If not, consider strengthening the comparison rather than adding prose.

### D. The final independent task is promising but not yet learner-validated

The review package provides tested learner programs and historical test receipts. The supplied validation report also confirms code parity, reference consistency and archive integrity.

But the current editorial revision was not subjected to a new complete runtime test, browser layout was not tested, and no actual student learning assessment is provided.&#x20;



The independent Assemblage assignment is a good test design. Whether students can formulate and execute a meaningful variation remains an empirical question.

## 7. Comparison with the earlier sequences

| Sequence          | Distinctive pedagogical contribution                                                    |
| ----------------- | --------------------------------------------------------------------------------------- |
| Forces            | Interaction, physical causality and unintended consequences                             |
| Wavefunctions     | Repetition transformed across movement, space and sound                                 |
| Cellular Automata | Local rules, collective behavior and experimental observation                           |
| Fractals          | Generating structures through repeated replacement across scales                        |
| L-systems         | Separating instructions, interpretations, constructed forms and conditions of execution |

I would place L-systems alongside CA and Fractals as one of the strongest structured programming sequences.

It also has a particularly good transition from Fractals. In Fractals, students learn to describe a construction through its seed, operation and stopping condition. L-systems makes the intermediate symbolic description explicit and allows different readers to interpret that description differently.

## 8. A concrete independent variation I would choose

The review package asks the ghost student to propose an independent change rather than simply repeat an existing exercise.

I would choose Grammar Lab, rather than Assemblage, to test whether the student can transfer the method back to the sequence's origin.

Keep the same string and rewrite rules, but create a third turtle reader that reverses every turn instruction while leaving forward movement unchanged.

My prediction:

- The generated string and number of drawing steps remain identical.
- Corresponding segment lengths remain equal.
- The geometry is reflected relative to the starting heading's axis, provided the reader consistently reverses every turn and preserves the same initial orientation.
- The original and modified readers can be compared without generating a new sentence.

The key invariant would be the sequence of segment lengths and connectivity. The meaningful difference would be the spatial orientation of their turns.

This is a proposed experiment, not an executed test. It also transfers the idea of independent variation into a place where the causal mechanism is easy to inspect.

## Final judgment

I would preserve the eight-hall structure, including the excursions beyond formal L-systems.

The revised reflections are more concentrated, the tutorials clearly identify inherited concepts and new operations, and the final assignment asks students to make a genuine independent decision.

My most important recommendation is not to add more examples. It is to make the sequence's central conceptual transformation unmistakable:

In Fractals, a rule constructs a form.

In L-systems, a rule can first construct a description, which another system interprets into a form.

That separation makes it possible to change the instruction, the interpretation, the environment or the material construction independently.

And the final Assemblage lesson adds something crucial: the observer can discover relationships that none of those procedures explicitly represented.

This is the strongest contribution of L-systems to the larger artistic research project: computation does not simply generate objects; it establishes layers of possibility between an instruction, its material realization and the interpretations that become available afterward.