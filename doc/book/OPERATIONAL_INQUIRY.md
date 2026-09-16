# Learning an operation, opening a world

Working method, 16 September 2026. This develops the useful claims in the review supplied by Palle, alongside [A path with remainders](DISCOVERY_AND_REMAINDERS.md) and the current Point → Line → Trace → Grid passage. It is an authoring aid and a proposal for further experiments, not evidence that every room already fulfils it.

Ada investigates what kinds of bodies and relations become possible when computational operations are built, encountered, understood and changed. The tutorial belongs to that investigation: it gives another person enough knowledge to repeat an encounter, identify its operative rule and pursue a different use or implementation. Whether readers can do that remains something to test with them.

“Operational ontology” is a useful working description. It asks what an implemented thing needs in order to act, what counts as the same thing under its rules, and what relations those rules permit. It does not establish that all reality has the ontology of our implementation, or that Ada invented this approach.

## A small record for each encounter

Keep this behind the chapter. It should help us select and revise a passage without imposing eight explanatory sections on every visitor.

| Record | Working question |
| --- | --- |
| Capability | What can the learner make or understand here that the preceding room did not yet supply? |
| Encounter | What action can they actually perform, and what can they notice before we explain it? |
| Operation | Which function, condition or representation accounts for that effect? What prior work are we borrowing? |
| Variation | What can change: the input, a parameter, the rule, the representation, or the purpose? Which of these is available to the visitor now? |
| Comparison | What stays fixed, what changes, and what would contradict our expectation? |
| Consequence | What becomes possible, difficult or unrepresented, for a particular body or use? What costs time, memory, attention or effort? |
| Desire | What draws someone to repeat, inhabit, adorn or misuse this construction? Who is included in that invitation? |
| Handoff | Can someone follow the code and repeat or modify the inquiry? What usable understanding and unresolved question go into the next room? |

For a focused first comparison, vary one thing while keeping relevant conditions fixed. Later experiments can combine changes deliberately. Repeated live gestures are not identical inputs; replaying a stored list can isolate a rendering change more clearly. Say which kind of comparison we made.

Distinguish source inspection, supplied-input engine checks, a person's observed encounter and an interpretation of that encounter. A passing scene probe supports a claim about behavior. It does not show that a visitor understood the operation, enjoyed it, felt confined or experienced freedom.

## Let the material answer

We have commitments: bodily difference, access, pleasure, queer desire, and the possibility of making worlds otherwise. Those commitments guide what we attend to. The result of a particular experiment must still be open to revision.

Rounding can omit a small movement and give a placement useful tolerance. It may also make an intended movement unstable at a boundary. Which consequence matters depends on the action being attempted. Increased repeatability is a hypothesis until we specify what is being repeated and compare outcomes; it is not a universal benefit of coarse spacing.

Changing a use also matters. Walking beside an instruction, dancing across a rounding boundary or treating a trace as a score can make another relation available with the code unchanged. Describe that as a reinterpretation or another practice. Reserve a claim about changing the computational rule for an actual code or parameter change.

Variation by itself does not establish a queer political consequence. Ask how bodies, desires, expectations and permissions meet in the situation. Equally, making queerness methodological should not strip out drag, ornament, fetish, comedy or the digital grotesque. These can be ways the inquiry is made and felt. Technical legibility and sensuous excess can inhabit the same work.

Time gives this inquiry a path. We need a usable understanding and a way to return, rather than an exhaustive account before the exit. Preserve developed artifacts and texts when narrowing the first passage. A secondary encounter needs a meaningful route back to it.

## Grid: the next comparison to build

The current [Grid chapter](../../commons/maps/Point_Line_Grid/final.md) already compares a retained address with movement, and a source drawing with two renderings. Its [23-check scene probe](../../commons/testing/probe_grid_lines_discovery.gd) verifies the release/copy/replay behavior in the working project. Its grid spacings are currently configured in code and scenes; the visitor has no installed spacing control for this experiment.

Proposed follow-up: keep one released Trace snapshot and its pink rendering fixed, and add a compact control beside the replay to change only the green rendering's snap pitch. The existing `shadow_snap_subdivisions` parameter offers a bounded starting point: 3, 6 and 12 subdivisions per metre give pitches of 1/3, 1/6 and 1/12 metre. Six is the current scene setting. Keep the source list, display centre, scale, floor and viewpoint available for comparison; provide a return to the current setting.

The question is: **which turns still differ, and what could this version of the drawing help us do?** Coarsening may collapse a turn, leave a shape recognisable, or give it another use. Do not require the visitor to find the coarse result worse or better.

Before describing that control in `final.md`, exercise its actual interaction callback. Verify that changing it leaves the source and pink vertices unchanged, rebuilding affects the green replay, and returning to six restores the initial result. Handle a replay with fewer than two surviving positions without inventing a line. Check reach and readability in the headset separately. These are acceptance criteria for a proposed feature; no such control is added by this note.

The same comparison can later serve other rooms: one sampled noise field interpreted at different occupancy thresholds, or one vertex list rendered as edges and faces. Each use needs its own invariant and observable result. Reuse the method without forcing every hall to reach the same conclusion.

## Positioning the contribution

Ada's developing contribution is the cumulative, teachable and bodily investigation across the museum: learning an operation supplies the means to question and remake a subsequent space. A claim about historical originality needs comparison with particular works and practices, and evidence from Ada's own encounters.

The supplied review's critical-technical-practice reference explicitly includes constructing technical alternatives after examining assumptions. Therefore making critique executable cannot by itself distinguish Ada from that tradition. The paper also describes interpretation as shared work among designers, systems and users. [Boehner, David, Kaye and Sengers, *Critical Technical Practice as a Methodology for Values in Design*](https://alumni.media.mit.edu/~jofish/writing/chi-05-values-workshop-cemcom-submission.pdf).

Ahmed's account of situated bodies, orientation and reach gives one relevant connection; its application to these particular artifacts remains our argument to make. [*Queer Phenomenology*](https://www.dukeupress.edu/queer-phenomenology).

Creative-code pedagogy and critical reading of code are also established contributions. [Levin and Brain, *Code as Creative Medium*](https://mitpress.mit.edu/9780262542043/code-as-creative-medium/) and [Marino, *Critical Code Studies*](https://mitpress.mit.edu/9780262357432/critical-code-studies/) provide specific comparisons. These checked source descriptions support the relationship; they are not a complete literature review or proof of Ada's uniqueness.
