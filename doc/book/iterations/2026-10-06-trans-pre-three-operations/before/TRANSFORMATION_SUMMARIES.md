# Transformation — move, turn, change size

6 October 2026 · Revised after the author's focus correction and review of all seven Transformation comic plates. Lesson plans, ready for one-at-a-time expansion.

## The sequence in one paragraph

Bring the familiar cube into the next museum hall. Move it without turning it, turn it without changing its dimensions, then change its size. Compare what each operation preserves and what happens to the space around it. A moving surface can carry you; a turn can align a crossing; an enlarged doorway can admit the same body that could not enter before. Learn to choose displacement, axis, pivot and scale, then let time or proximity vary those choices. At the end, combine the three operations into a passage. Keep the tutorial forms in black, white and grey. Programming develops because it gives the student control over these transformations, while the reflective text follows the possibilities and exclusions they create.

## What leads the teaching

**Spatial operation → what changes and what remains → small working code → a deliberate variation.**

A transformation need not be animated. Start with a changed pose; add animation when following intermediate poses helps explain the operation. Use a clock, list, event or flag when the chosen experiment needs it. Do not add a second programming syllabus to every hall. Several comparisons can use the same object without becoming simultaneous requirements.

| Hall | Core comparison | Further step, after the core works |
| --- | --- | --- |
| Trans_Pre | Position, orientation and size are three different changes. | Animate one operation, then combine known ones. |
| Trans_Introduction | Travel, turning and growth make different crossings. | Move the bank; connect one control to the changed parameter. |
| Trans_Translation | Change position along an axis or a combined direction; keep facing and size. | Follow a short stored route. |
| Trans_Rotation | Change axis, angle or pivot; keep the body's internal distances. | Reverse two turns and inspect the marked result. |
| Trans_Scale | Equal factors preserve proportions; unequal factors change them. | Scale a group while keeping an outside witness fixed. |
| Trans_Body | Replace time with proximity as the driver of turn or size. | Compare a returning response with a deliberately retained change. |
| Trans_Pit | Combine operations; inspect the space left between moving bodies. | Choose a different timing or opening rule. |

## 1. Trans_Pre — move, turn, change size

Follow the plate's still cube, rising cube, added turn and pulse. Reuse CubeBody and first set its position, orientation and scale separately, returning to the same starting pose between comparisons. Identify translation, rotation and scaling by what changes: centre, facing or dimensions. Translation keeps size and orientation; rotation keeps internal distances; positive uniform scaling keeps proportions. Then use elapsed seconds to animate one of these changes, before adding the others as the hall does. Explain assignment and delta where they become useful. Predict which corner, edge length or face mark will change in a new pose. Collection remains supplied. Carry three distinct operations on the same construction.

## 2. Trans_Introduction — three ways to make a crossing

Compare the plate's travelling surface, growing cube and quarter-turn plank. Reuse the three operations in a small complete model beside the existing crossings: translation carries a surface between banks; scaling extends its reach about a fixed centre; rotation aligns its length with the gap. Hold a chosen pose and inspect whether the surfaces meet before adding travel, turning time or a pause. Move the far bank while keeping the plank's length and pivot fixed, then predict why the old angle no longer guarantees a crossing. Explain the supplied control's event connection only as needed to change that parameter. Rider transport and physical collision stay supplied. Carry transformation as a spatial relation between bodies.

## 3. Trans_Translation — choose a displacement and a journey

The plate's carrier follows a sloping path while its top stays level: translation changes position without requiring a turn. Move the familiar cube along X, Y and Z, then combine components into a diagonal displacement. Reuse Lines to distinguish direction from distance and name the coordinate frame. First assign the destination; then interpolate between start and finish while retaining orientation and size. Compare a direct diagonal with a journey that rises before moving sideways, as in the two exit handles. A further step uses a short waypoint list: Trace kept movement as data; here data directs movement. Carry the ability to choose both displacement and route; the museum supplies rider carrying.

## 4. Trans_Rotation — a turn needs a centre and room

Use the plate's marked cube to distinguish a repeated outline from a returned orientation. Set an angle around X, Y or Z, then move the pivot and compare spinning in place with travelling around another centre. Reuse local coordinates and a small returning function for centre plus rotated offset; explain angle units at their first use. Follow a corner through intermediate poses to see why the swept space exceeds one resting pose. Predict a quarter-turn and verify that the body's dimensions remain fixed. Once this is clear, reverse a chosen X/Y turn pair and compare the face mark. Rider orientation and sweep drawings are supplied. Carry control of axis, angle and pivot.

## 5. Trans_Scale — the same proportions, another possibility

The plate's small doorway becomes usable while the visitor stays the same size. Begin with the familiar cube beside a fixed sphere: multiply all dimensions by one positive factor, then change only one axis and compare proportions. Make the distinction visible before introducing a group. Put two familiar cubes beneath one created parent and scale it; predict their world sizes and spacing while their local positions stay unchanged. Keep the sphere outside the group. Return to the museum's enlarged room and its separate visitor relocation: scaling the surroundings did not scale the visitor or walking speed. The bottle and physics remain supplied. Carry deliberate control of size, proportions and which objects share the change.

## 6. Trans_Body — let distance turn into size or angle

Follow the plate's opening slats and shrinking blocks. Reuse a known rotation or scale, replacing elapsed time with the visitor's distance in a named frame. Give the familiar cube a bounded size response, then use the same input range to turn it instead; predict what happens at near, middle and far positions. The calculation and any reach condition now have an immediate spatial purpose. Leave and see the transform return. Compare this with the lattice's missing cells: removal changes the collection, rather than simply changing a surviving body's pose. A retained flag is an optional way to keep one response after departure. Tracking and collision remain supplied. Carry a transformation driven by bodily relation.

## 7. Trans_Pit — compose an opening

The plate returns to translation, rotation and scale as changes in available space: a block arrives, a slab sweeps past, a cube grows into a gap. Inspect an intermediate pose, not just the beginning and end. Then reuse two CubeBody instances to make a small model of the hall's opening leaves, coordinating displacement, angle and scale through one bounded progress value. Keep the frame fixed and predict which operation produces each part of the opening. Supply occupancy and physical contact; choose a new timing or sequence of known operations and compare the resulting gap. Add no required syntax topic here. Carry an authored composition that Arrays can repeat and vary across many bodies.

## Programming foundations: present, then developed through use

Primitives already explains initialization, values and references, PointBody/CubeBody classes, arrays and indices, loops, conditions, parameters and returning functions. It offers practice and tested programs, not proof of human mastery. Transformation can reuse these foundations rather than finish every programming subject before beginning its own work.

Elapsed seconds help animate a transform. Events connect a control to a chosen value. A route needs an index that survives updates. A proximity response needs a calculation and possibly a condition. Parent-child relationships explain which bodies a scale reaches. Explain these where needed; keep general state-machine theory, exhaustive input design and matrix algebra outside this sequence. Sine may remain a short optional timing comparison once linear movement is understood; its derivation waits for Waves. Arrays and Colour provide further work with collections, functions and independent instances.

The older foundation plan's first-class-in-Colour claim is superseded: PointBody now begins in Lines. Likewise, seeing the supplied timer in Godot Primitives does not establish an ability to author a timing rule. Keep the concept's role explicit: supplied, introduced or practised.

## Writing and testing contract

- Select a spatial capability first: what can the student transform, predict and explain? Begin from the existing museum encounter and declare where the reduced study runs.
- Print the smallest complete resulting program once in tutorial.md, identifying inherited classes and supplied support. Initialize lesson objects. A source link or unexplained scene lookup cannot replace the needed code.
- Test the printed code, exact exercise variation and a relevant deliberate fault. Lead with the transformation claim: a displacement preserves orientation and size, a turn preserves internal distances, or a chosen scale changes the expected dimensions. Check timing, bounds and reset where the program uses them; the test harness need not become a second lesson.
- Keep final.md's reflection distinct. Illustrations can connect both readings without turning every depicted artifact into a coding requirement.
- Offer one small closing transfer to PointBody using a learned operation. If animation and grabbing coexist, declare which controls the transform; do not introduce an entire ownership framework merely to complete the chapter.

## Illustration review and next step

All seven [Transformation plates](http://localhost:3003/illustrations?plate=final-Trans_Pre) were inspected. Their strongest comparisons are the separate operations in Pre; the three crossings; level orientation on a diagonal journey; the marked face and swept space; a larger doorway beside an unchanged body; transformation versus removal; and the fixed frame around a changing opening. These illustrate final.md with imagined staging, not captures proving runtime behaviour. Several retain earlier coloured surfaces and overlays; future tutorial depictions should follow the current grayscale choice. The art remains intact in this pass.

These summaries and the seven editable execution-plan entries now share this focus. The existing tutorial.md files still need complete tested reconstructions. The seven-hall order remains; it can change if writing or testing gives a reason. Begin with Trans_Pre's three operations, then add a clock. No tutorial manuscript, reflective text, illustration or museum code changed in this planning revision.

[Illustrations beside these summaries](../../iterations/2026-10-06-transformation-first/index.html) · [Edit the live plan](http://localhost:3003/tutorial-plan?view=summaries&seq=transformation&map=Trans_Pre) · [Current spine order](../../../../commons/maps/sequences/transformation.json) · [Primitives takeaways](PRIMITIVES_TAKEAWAYS.md) · [Reconstruction rules](../functional_text/RECONSTRUCTION.md)
