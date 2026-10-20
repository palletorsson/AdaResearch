# Tiling — nine lesson summaries

12 October 2026. Current tutorials; editable teaching decisions.

## Pattern_Disco — Keep the pattern, change its colours

Colour gave the familiar point and addressed grid a palette. Return to them in Disco and follow one square while changing palette and phase separately. The receiver stays fixed; a zero or one can acquire another appearance. Make both palette entries equal, advance the rule, then reveal its retained phase with another palette. Reuse the three existing classes; this lesson starts its own declared state. Foundry next replaces the calculated checker with a source we can edit.

**Short AI:** reuse PointBody/GridSurface/Palette; separate phase from colour; equal colours can hide change; no automatic saved-state handoff.

**Carry:** The exact Colour PointBody, Palette and GridSurface classes; calculated value, palette choice and phase remain separate. Code reuse does not persist a running choice.

**Next:** Pattern_Foundry: inspect the current architectural receiver, then edit and retain a small source and repeat it through wrapped row/column addresses.

## Pattern_Foundry — One edit, many appearances

Keep the point, palette and receiver. Store a small asymmetric source as rows of values, then wrap each receiver address back into it. Move the held point over a cell and trigger one edit. Predict every visible occurrence that reads the changed entry before repainting. The larger Foundry machines remain encounters to revisit; the first construction teaches the reach of one source. Carry that source shape and reader into the next lesson, without assuming that a running edit has been saved between halls.

**Short AI:** build source[z][x]; posmod address; edit one entry; repaint readers; predict all affected occurrences.

**Carry:** One editable source with a declared row/column reader and explicit repaint. Keep an asymmetric motif for the next reflected lookup.

**Next:** Tutorial_Pattern: retain the source and receiver, compare forward and reflected read addresses without mutating the source.

## Tutorial_Pattern — Change the reading

Keep the source fixed and reflect alternate whole copies through their read addresses. Compare that operation with reversing the stored rows: one changes how the mark is read, the other changes the mark. Edit through a reflected occurrence and locate the source entry it reaches. A symmetric source can conceal the difference, so choose an asymmetric test. The five-column learner display cuts the six-column reflected period short; use the larger museum comparison to see a full return.

**Short AI:** read reflection != source mutation; diagnostic asymmetry; block parity; period can exceed tile width.

**Carry:** Stored source, read address and visible appearance remain distinguishable. A diagnostic mark makes an operation observable; the tile width need not equal the translation period.

**Next:** Array_Patterns: keep source and reader while defining the receiver origin, axes and cell width in metres.

## Array_Patterns — Give an address a place

Return to Transformation: turn the receiver from table to wall and change its physical cell width while preserving source values and read rule. Use the receiver’s inverse transform to recover an address from the held point. Predict where the same entry can be found in both placements and how many metres one repeat spans. The installed tunnel extends the comparison around corners; shared source data alone does not guarantee a seamless join. This physical frame becomes the receiver inherited by the glide lesson.

**Short AI:** source/rule fixed; table→wall; to_local(hand); cell width in metres; preserve address through transform.

**Carry:** Source values, read rule, receiver frame and physical extent remain distinct. A surface gives row/column directions; inverse transforms recover addresses. A finite display may cut a repeat.

**Next:** Symmetry_Seventeen: compare translation, reflection and glide while keeping a finite receiver and distinguishing a source width from a translation period.

## Symmetry_Seventeen — Compose a reflection and a shift

Extend the previous receiver with a reflection followed by a half-height row shift. Compare P1, PM and PG with the source unchanged; predict the lookup for an even four-row source. A construction button does not prove the complete symmetry classification of every chosen mark. The optional loom adds another distinction: repeated instructions can change while cloth already woven keeps its crossings. SAVE CLOTH explicitly retains that sample for the later cutting table; it is a separate record from the shader studio’s source.

**Short AI:** extend surface reader; reflection+half-height glide; even rows; construction != classification; optional loom record→cutting table.

**Carry:** A composed address rule, an explicit even-height domain, diagnostic source marks and the difference between a construction rule, a sampled field and its complete symmetry classification.

**Next:** Pattern_Temple: inspect how one retained source binds to several architectural receivers before assigning the student edit.

## Pattern_Temple — Agree, then diverge

Compose two receivers using the known source, rules and physical frames. Unlike Foundry’s many readings of one live source, each receiver now owns a recipe. Copy one recipe to make the pair agree, then edit only the other receiver and show what stays local. Deep copying the nested rows makes that independence real. Choose which surfaces should share a decision and when they should diverge. The temple makes the consequence visible across a whole room without requiring the student to rebuild every architectural surface.

**Short AI:** compose independent receiver recipes; deep-copy rows; agreement now != shared future; edit locally.

**Carry:** A selected receiver, its independently owned source/rule record, explicit copying, local repainting, and agreement without a continuing link.

**Next:** Ribbon_Patterns_01: inspect the source layers and distinguish stored zero, displayed pale body, hiding and deletion.

## Ribbon_Patterns_01 — Let height enter the address

Take an optional branch into volume. Stack familiar receivers and store values as layers of rows, values[y][z][x]. Let height shift the column read from the same source; predict a value at an address whose three indices differ. A slice hides other layers while preserving their records. Choose another layer count or shift and account for the result. This develops spatial data; the following surface comparison and fabric shader do not require the volume as a prerequisite.

**Short AI:** optional volume branch; values[y][z][x]; height-dependent lookup; slice hides != deletes.

**Carry:** Height-dependent source reading; independently allocated layers/rows; visible, hidden, occluded and absent are different states.

**Next:** Ribbon_Patterns_02: retain equal values and compare surrounds and flat/curved receiving surfaces.

## Ribbon_Patterns_02 — Keep the value, change its company

Pause to investigate equal colour values against different surrounds and on different carriers. State what changes, what remains fixed and what you observe, without requiring a particular perceptual answer. The optional runnable reconstruction reuses the point and grid and deliberately shares the targets’ material while keeping their surrounds independent. The volume is not a prerequisite. Bring this controlled comparison into the fabric studio, where one source reaches differently mapped bodies.

**Short AI:** observe fixed values/changed surrounds; no prescribed perception; optional shared-material reconstruction; return to surfaces.

**Carry:** Controlled comparison: changed condition, fixed values, observed result. Share and copy according to intended ownership; distinguish appearance from assigned data.

**Next:** Ribbon_Patterns_03: inspect the actual shader/fabric studio; carry source, material sharing and UV-versus-physical-spacing distinctions.

## Ribbon_Patterns_03 — A source reaches a garment

Reuse the address calculation in a small fragment shader inside the supplied museum studio. Follow UV through repeat, offset and sampling, then predict both a sampled colour and its spacing on the wall. After the guided two-to-three repeat edit, choose and predict another count yourself. Saving the studio recipe does not save the changed shader. The optional cutting table can instead load the actual loom record, cut a chosen garment and retain cloth and shape on the wearer. The two save routes remain distinct.

**Short AI:** UV→repeat+offset→sample; texel != fragment != vertex; recipe != interpreter; optional saved loom→cut→wear.

**Carry:** Sampling operation; UV counts versus metres; saved record versus interpreter; shared recipe across differently mapped bodies.

**Next:** Change_Intro: compare a curve at two positions and ask how much its value changes. The existing transition is retained; Change is outside this pass.

