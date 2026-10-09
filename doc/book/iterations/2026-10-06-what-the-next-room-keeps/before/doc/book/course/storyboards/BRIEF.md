# Tutorial storyboards

**Current acceptance rules:** [Can the student make it?](../functional_text/RECONSTRUCTION.md) separates focus, complete printed code, exact continuation, native behaviour checks, deliberate faults, exercise variants and human learning. [The tutorial must run](../../iterations/2026-10-05-the-tutorial-must-run/index.html) explains why. Follow these with the author's latest hall choice; older pilots are historical evidence.

**Reading economy:** show the complete working example once. A small experiment can name the exact edit without repeating an unchanged function or script. Test the edited result as well as the original; keep the complete variant available to download.

**Author correction, 5 October — executable lessons.** Print and explain the smallest complete working example in `tutorial.md`. Run the exact printed code in Godot with behavioural assertions. A test may supply the declared camera, player or library, but must not secretly create the lesson's label, sphere or other object. For a continuation, carry the preceding lesson's actual code: Coordinates gives Point One's same point pickup and reads its coordinates. Explain what is new; print the complete resulting small program. Short AI briefs preserve this contract. `final.md` remains the reflective track. This supersedes earlier edits-only and hidden-production-code approaches.

4 October 2026. Working brief and proposed route through all 25 sequences, for Palle to correct. These paragraphs are not approved lessons. They describe intended learning, not a claim that every transfer between existing museum artifacts is implemented.

## What the tutorial is for

The student walks through the existing Endless Museum and gradually learns enough programming to make work of their own. The artifacts provide encounters and material to think with. A tutorial selects a useful construction or operation from that material and makes it understandable, changeable and reusable. A successful lesson leaves the student able to do something deliberately, beyond following a particular edit.

The museum, tutorial and reflective writing are overlapping sets. Some works belong to both written tracks, some to one, some to neither. The tutorial teaches selected operations. `final.md` develops the critical and poetic inquiry. A reflective hall may deepen a question or let the student compose with known tools without introducing new syntax. The presence of an artifact does not oblige us to explain all its code.

**Author clarification, 5 October: two texts, two jobs.** `final.md` carries the concrete, poetic and critical reflection, with little code. `tutorial.md` supplies the learning context, explains what continues from earlier halls and includes the complete code needed for its selected example. Print the reduced student script and any small supplied helper in the tutorial; links and edit fragments alone do not constitute the full implementation. Full example code does not mean the entire museum or XR toolkit. Name that prepared environment explicitly. Preserve the continuing object and explain the new operation without reteaching every inherited line.

Day Zero establishes the running project, player, camera, lighting and device setup. Later lessons work within that prepared museum. The counter, points and other encounters already exist. Their presence is neither an instruction to add duplicates nor a requirement to march through long production scripts. Reduced code must retain a clear connection to the real artifact and explain what the surrounding system supplies. Where the student makes their own version, decide where it runs and how it relates to the existing work in the storyboard first.

The code should be small enough to understand and substantial enough to use. Create teaching geometry in code when its construction is the lesson; keep direct references to created objects. Do not conceal necessary work behind dollar references, scene paths or unexplained helper calls. Supplied components are allowed: say what goes in, what comes out and what the student can change. A learner should not need to understand the XR player to use a working hold.

The lineage concerns both materials and programming: point, coordinates, line, retained trace, grid address, triangle, connected faces, generated forms. Introduce variables through the point, a one-dimensional list and traversal through Trace, and a function where a small geometric rule can generate positions. Earlier tools return with another purpose. A brief usable introduction can precede a later deep study, such as sine before Waves and a random choice before Randomness.

“Type-safe” is our working analogy for keeping these connections explicit. Name the kind of thing being used: position value, node, mesh, collision boundary, list, function, reference frame. A position is not its sphere; a visible surface is not automatically a physical boundary. Explain a new operation when the student first needs it. In the reflective track, a software fact, a historical claim and an artistic association also need their own kinds of support.

Write plainly, with a concrete action and consequence. Keep explanations close to the code they clarify. Preserve room for curiosity and the critical question; do not force a philosophical conclusion into every instruction. Neither exhaustive explanation nor a succession of trivial parameter edits is the goal.

## How we work from now

Move between project, sequence, map and evidence using [CONTEXT.md](CONTEXT.md). Keep the current purpose while descending; carry consequential findings back up before leaving. Read the [sequence overview](SEQUENCES.md) for global orientation. Existing sequence arcs need their entry, exit, boundary reasons and open choices developed; this remains proposed summary work.

Keep two versions of every summary: a full paragraph in `storyboard` and a compact AI alternative in `storyboard_short`. The short version selects the same teaching, not a different lesson. Use short instructions: **Use → Reuse → Teach/Do → Supply → Carry**. Add **Open** or **Defer** where a decision matters. Preserve dependencies, unresolved choices, supplied support and reflective purpose. Remove narrative padding; use explicit technical names rather than cryptic abbreviations. Shared constraints live here once. The review offers Full / Short AI, and a short-only Markdown export avoids reading both versions.

Palle corrects the teaching selection before a full tutorial is written. These imperatives describe a proposed lesson; they do not authorize implementation. Source reading checks the summary against the existing artifact.

Use the paragraph to distinguish what is encountered, supplied, first taught, reused and later deepened. Keep the detailed subject register behind this readable plan. Do not infer that a concept has been taught because its name occurs in code or in `final.md`. If an earlier skill is required, establish it or supply it explicitly. One map can support more than one short lesson if its learning step needs that division.

**Current pass: learning-element lists and tutorial lineage.** Palle asked on 5 October for the same short subject list across the remaining tutorials, chosen for student progression rather than an inventory of each artifact's code. Add compact labels to existing `tutorial.md` files; name what is inherited, added and carried forward. Flag wrong focus or missing prerequisites. Preserve the existing lesson body until its revision is agreed. Keep `final.md`, runtime logic and map placements separate. The live cards and curated lineage are in `doc/book/course/hall-cards/`; saved author choices override proposed selections.

Include one small variation that lets the student use the idea independently. It may be another pair of positions, another drawing, another rule or an arrangement using known tools. Reflective halls need not become tests. If source behavior differs from a proposed paragraph, name that difference in a short writing note; do not change the code to make the paragraph true.

The [Lines → Trace → Grid notes](LINES-TRACE-GRID.md) distinguish the proposed learning from the current behavior. The summaries remain the work for review.

The paragraphs below cover the current spine. They remain proposals: agree each teaching choice before expanding its tutorial. The existing [curriculum through Randomness](../sketch/CURRICULUM_TO_RANDOMNESS.md) and [subject register](../sketch/SUBJECT_REGISTER.md) provide planning material; their older host instructions and teaching locations are not settled decisions.
