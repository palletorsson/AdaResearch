> Update, 2026-09-17: this comparison preceded the requested expanded route. The implemented first pass is recorded in [the current implementation record](../../space/regularity-split-2026-09-17/RESUME.md): five monochrome array/regularity halls before Color, then a coloured disco return and architecture controls in Tiling.

# Regularity: from one body to a rule

2026-09-17. Reading and curriculum proposal; no sequence, map, role or manuscript changes applied.

## Recommendation

Keep the current walk: Primitives → Transformation → Arrays → Color → Patterns → Change. Treat Arrays, Color and Patterns as a connected part of the book, provisionally **Regularity: from one body to a rule**. Preserve the three sequence IDs and their separate purposes for now.

Arrays and Patterns are related, but merging only those two would put nine Color halls inside the resulting chapter or require moving Color elsewhere. Color's new opening explicitly gathers primitives, transformations and arrays; Patterns' current encounters use coloured source cells and palette indices. Keeping Color between them makes those dependencies available. This is a pedagogical recommendation, not a technical necessity: monochrome patterns could be taught earlier.

An array supplies indexed storage. Its values need not be repetitive. A placement rule can display it as a regular row or grid, but index and physical position are different things. A pattern concerns relations among elements and their repetitions or variations. A loop performs repeated work. These three ideas should become distinguishable through encounters.

Color adds measurement, perception, context and association. Calling the larger part Regularity must not reduce Color to a chapter about filling squares.

## What was read

The supplied PDF is the chapter **Regularity**, printed pp. 63–103, from *10 PRINT CHR$(205.5+RND(1)); : GOTO 10*, by Nick Montfort and nine coauthors, MIT Press. Local source: `C:/Users/palle/Downloads/c000800_9780262305501.pdf`. The file has 44 PDF pages, including its cover/section information and publication matter. Printed p. 63 corresponds to PDF page 1.

Publisher DOI: `10.7551/mitpress/9040.001.0001`. Official project and author information: https://10print.org/.

The complete chapter was text-read; printed pp. 68, 72 and 99 were also inspected as rendered pages. This proposal does not treat every historical generalisation in the chapter as independently established. Historical examples below describe the chapter's argument; the museum design recommendations are ours.

### Five useful distinctions

1. **Space, time, process** (p. 66; pp. 87–98). A repeated image, a returning beat and repeated instructions are related but not identical. A grid can stand still after the loop which built it has finished. A clock can repeatedly read an unchanged array.
2. **A sequence becomes a field through a placement convention** (p. 68; figure 30.5 on p. 70). Removing the semicolon from the BASIC example changes the output arrangement. The comparison makes the supporting display rule visible. In Ada, expose the mapping from index to coordinates rather than presenting a spatial grid as the array's natural shape.
3. **One unit can become a larger unit** (pp. 70–75; figure 30.6 on p. 72). The Truchet examples develop combinations of an oriented tile into larger repeats. This supplies a concrete bridge from transformation to composition: turn one marked unit, combine units, repeat the combination. The discussion of textiles and craft also resists making computation the sole origin of procedural design.
4. **Regular support can carry irregular content** (pp. 71, 80–81). An orderly lattice and fixed procedure do not require every tile to look alike or the whole image to have a repeating period. A single deliberate exception is enough to investigate this before teaching random generation.
5. **A repeated instruction has a bodily performance** (pp. 99–103). The discussion of Acconci and Childs/Glass/LeWitt distinguishes prescribed repetition from performance, documentation and changing experience. For Ada, this connects the first walk along a line to the disco and later catwalk. The claim is not that the headset captures every difference; those measurement limits are part of the investigation.

The PDF is especially helpful as a writing method: remain with a small executable construction, vary something precise, and follow the consequences into material and cultural questions. Its chapter order is not automatically the best teaching order for our existing museum.

## Current position in the spine

Checked `commons/data/spine_order_effective.json` and the current source sequence definitions:

| Position | Sequence | Current halls | Distinct contribution |
| --- | --- | --- | --- |
| 2 | transformation | Seven, ending in Trans_Pit | Place, turn and scale a body; compare passage and invariants. |
| 3 | array_tutorial | Array, Tutorial_Disco | Address a value; distinguish stored arrangement from reading it over time. |
| 4 | color | Nine, Color_Context_Placed through Chamber_Color | Give values material, perceptual and associative consequences. |
| 5 | tiling | Seven, Pattern_Foundry through Ribbon_Patterns_03 | Compose a source, transform its repetitions, map it to surfaces and bodies. |
| 6 | change | Follow-on to be retained | Investigate how state changes and at what rate. |

The row uses the same pickup-cube scene introduced in Transformation. That continuity is the opening, rather than a new anonymous cube. The row script already places copies with `cube_instance.position = Vector3(i * 1.0, 0, 0)` and records collection separately from index.

## Proposed encounter ladder using the existing halls

| Hall or passage | Encounter to foreground | What becomes newly possible |
| --- | --- | --- |
| Trans_Pit → Array | Recognise the pickup cube; follow its copies across a row; inspect how the index supplies each displacement. Then collect one. | Address one member of a collection; distinguish slot, value and displayed position. |
| Array | Row → grid → volume, using the already placed row, 2D grid and 3D grid. Keep a simple location task across them. | Use additional indices without mistaking a cube's physical thickness for another data dimension. |
| Tutorial_Disco | Write a small arrangement and let the playhead read it; change tempo while retaining the cells. | A stored spatial arrangement becomes a score; repetition in time has an explicit reader. |
| Color_Context_Placed → Chamber_Color | Keep the current Color progression. Its columns gather prior constructions; its later grid permits individual edits and rule-driven replacements. | Investigate what a stored colour value does with illumination, neighbours, materials, bodies and receiving rules. |
| Pattern_Foundry | Edit a small source, see it recur, then try to keep one repetition different. Introduce the loom through one flat/curved comparison. | A local decision becomes shared across many appearances; distinguish source from receiver. |
| Tutorial_Pattern | Keep an asymmetric motif while comparing repetition and reflection/glide operations. | The transformation of a copy becomes part of a pattern rule. |
| Array_Patterns | Follow the motif around the actual corridor and compare its mapping across floor, walls and seams. | Pattern becomes an environment; appearance and collision can be compared. |
| Symmetry_Seventeen | Classify operations after encountering them and their spatial consequences. | Recognise a bounded classification: the seventeen groups concern doubly periodic plane patterns, not every possible pattern. |
| Ribbon_Patterns_01 | Return to the familiar volume; compare repeating layers with shifting the source lookup by height. | The third index now participates in a rule. This is a development of Array, not a duplicate introduction to 3D. |
| Ribbon_Patterns_02 | Keep values while changing surround and lighting/material conditions. | Revisit Color under a new question about the appearance of a pattern. |
| Ribbon_Patterns_03 | Carry a source onto shader specimens, dress and procession. | A repeat becomes wearable and performed; connect to Change through the already moving bodies. |

The proposed route keeps all current halls. No existing artifact needs to be deleted to make this first reading legible. Additional controls and investigations can remain available as deeper encounters.

## Where the present text needs work

- **Array:** 521 words, anchored only to `row_3_x` and `grid_2d_4x4`. Its opening question about an absent occupant is worth keeping, after recognising and constructing the repeated cube. Add actual code and a short encounter with the already placed volume. Its closing still promises a room which slows collection; the actual next hall is Tutorial_Disco.
- **Tutorial_Disco:** the existing distinction between stored score, moving reader and independently animated floor is valuable. Keep it. Do not claim footsteps write into the score. A brief return to the bodily question from Walk This Line would make repetition felt without inventing a new interaction.
- **Color:** preserve the recently rewritten opening and its scientific/associative argument. Strengthen references back to a familiar slot or repeat when useful rather than restart the explanation of arrays.
- **Pattern_Foundry:** 1,684 words, including many linked-surface, hold, save, restore, grouping and ownership operations. Its strong opening gets buried under a long control walkthrough. First reading: source → repeat → exception → one receiving-surface comparison. Keep advanced operations as optional material or later encounters; retain their working artifacts.
- **Ribbon_Patterns_01:** keep its distinction between hidden cells and erased data, and between added depth and a rule which actually uses that depth. The return to arrays earns its place.
- **Planning records:** Array's intent still describes its retired position inside Color; the sequence JSON retains historical retired fields alongside its active two-map list. Tiling's description overstates the seventeen groups as all ways a plane can repeat. Update these when implementing the editorial pass, without using stale notes to move rooms.

## One new experiment worth prototyping

**Keep the list; change how it becomes space.** Start with a fixed list of marked units. Compare a row with that same list wrapped into a grid. Then keep the grid and turn just one unit. Finish by repeating a small group as a larger motif.

Use an asymmetric mark, a diagonal face or a wedge: a uniformly coloured cube can conceal its own quarter-turn. This recovers Transformation's question of sameness rather than silently assuming every rotation will be visible.

The PDF's example combines randomness with a regular display. For the first Ada experiment, use a fixed list and one deliberate edit so the changed relation can be followed. Return to the same construction in Randomness and vary the choice rule while retaining the grid. This is a proposed experiment, not an interaction currently verified in Array.

Keep separate records for the array, placement, motif orientation and repetition rule. Otherwise the display can appear to prove a claim about arrays when it only demonstrates one visual mapping.

## Alternatives considered

- **Merge Arrays and Patterns before Color:** technically possible, but current coloured motifs and the new Color precondition would need rewriting. The large studio would arrive before its colour relations have been examined.
- **Move Arrays after Color and merge there:** weakens the accepted accumulation from primitives and transformations through indexed stacks into Color.
- **Create one large sequence containing Arrays, Color and Patterns:** could match an editorial part, but combines eighteen halls and three distinct questions. An overarching book part can do that work without changing room IDs, progression or navigation yet.
- **Move Disco to the end of Patterns:** would give a space-then-time climax, but removes the early, concrete distinction between stored state and execution and competes with the existing shader/mirror/catwalk close. Retain Disco early and return to performance later.

## Next implementation

First revise the Array chapter around the familiar pickup cube, the placement loop, slots and values, and the dimensional ladder; fix its handoff to Disco. Then edit the first-reading route through Pattern_Foundry. Prototype the fixed-list placement comparison only after checking where it fits spatially. These are scoped next steps; none was applied as part of this reading.
