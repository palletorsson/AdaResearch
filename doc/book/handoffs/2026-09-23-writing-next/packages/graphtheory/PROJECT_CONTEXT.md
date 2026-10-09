# The invitation, the journey, the return

Editorial scaffold · 23 September 2026 · Working drafts for Palle's revision.

## Publication order

1. [Before the first point](preface.md): a short preface, naming the audience, desire, tutorial method and the relationship between page and museum. Introduce QFEP briefly; leave its full argument for the return.
2. **The complete active spine:** each hall's `commons/maps/<Map>/final.md`, following `commons/maps/curriculum_spine.json` and the ordered `maps` array in each active sequence JSON. Preface and afterword are book matter, not museum maps or additional sequences.
3. [What must a world change so difference can do more than fit?](afterword-qfep.md): a substantial afterword developing QFEP through the encounters, including their consequences for the maker and the museum. It follows the final Post-Foundations Crisis hall, not just the QFEP Laboratory chapter.
4. **Publication apparatus to prepare:** consolidated references, glossary where useful, code/build provenance and contributor/AI collaboration credits. Existing hall footnotes stay with their chapters. These additional apparatus items are proposed, not yet written.

The opening reader is someone who wants to understand code as a means of making space and the conditions of bodily action. The tutorial supplies the means to investigate; aesthetic attention, desire and critical reflection help determine what to investigate next.

## The afterword's argument

| Passage | Work it should do | Material already available | What the next pass must supply |
| --- | --- | --- | --- |
| Return to the first arrival | Define QFEP and the change of perspective after the journey | Point One; QFEP reading note | A return from a later encounter that actually changes an early assumption |
| Tolerance needs somewhere to go | Separate admission from facilitating difference | Target's 0.45 m region; tolerance note | A sustained comparison where reach, time or support changes participation |
| What a measurement keeps | Explain how a useful measurement remains selective | Trace, Grid, entropy meter | Clear distinction among the measures used in the later chapters |
| When a description becomes a demand | Follow the passage from representation to intervention | F Term; entropic morality | One worked case with the allocation, affected parties and authority specified |
| A boundary can make room | Allow protection, refusal and conflicting needs to complicate openness | E Term; entropic morality | A difficult case where commitments pull in different directions, with no guaranteed winner |
| Pleasure is part of the work | Keep desire, drag, ornament and the digital grotesque material to the argument | Lines, Trace and Grid; later form-making corpus | Select and verify a later-spine case, considering time, computation and who does the work |
| Keep the formula answerable | Explain the FEP relationship and status of the project expression | Current QFEP halls; research dossier | A separate technical model specification before any new numerical or universal claim |
| Self-Q reaches the book | Apply the method to authorship, selection, sequence and revision | Primary-role decisions; spine; research history | Reader/player responses that can change the argument, with permission for quotation |

This is a scaffold with developed prose, not an accepted final essay. The full revision should earn its length through specific cases, including at least one from the middle of the spine. Repetition of a general claim about exclusion will not substitute for those cases.

## Evidence and source work

Distinguish current implementation, observed encounter, reader interpretation and proposed experiment. A scene check does not establish understanding, comfort or political freedom. The afterword's proposed tests remain visibly proposed. A numerical tolerance and an ethical condition can be related through an argument; neither proves the other.

The current ethical basis is [Q: An Entropic Morality](../research/qfep/entropic-morality.md) and the [QFEP reading note](iterations/QFEP_READING.md), including its 22 September tolerance clarification. These qualify older shorthand in skills and historical manuscript frames. QFEP names the **Queer Free Energy Principle**, not a four-word expansion of the initials.

The FEP paragraph's narrow account was checked against Friston, Thornton and Clark, [Free-Energy Minimization and the Dark-Room Problem](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2012.00130/full) (2012), especially the opening exchange and model-conditioned surprise, on 23 September 2026. Before substantially extending the theoretical discussion, revisit the primary works already linked in the QFEP dossier. The afterword's internal notes currently provide a research route; they are not a finished external bibliography.

## Revision order

Read the preface for invitation and burden: can a newcomer begin without already agreeing? Then choose one later-spine case for the afterword and let it test a claim made here. Develop the conflict case and record what would revise the argument. Only then expand the literature discussion and complete publication credits and references. Keep an author's voice pass distinct from implementation verification and independent reader/playtesting.

## Reading copy and integration

The [framing preview](iterations/2026-09-23-book-frame/index.html) places both drafts around links to the active spine. Rebuild it after manuscript edits:

```text
python doc/book/iterations/2026-09-23-book-frame/build.py
```

Canonical manuscripts are `doc/book/preface.md` and `doc/book/afterword-qfep.md`. The preview's source files are dated reading snapshots with hashes, not a second editing home. Its manifest records active sequence membership and the source fingerprints used for this edition.

The existing `/book` editor has a separate older `book.json` index; some active halls are absent. This scaffold does not regenerate that index or the legacy `tutorial_authored`/`manuscript_frame.json` exporter. Use `/museum-progress` for active order, and the live final-text source links supplied for the endpoint halls. Integrating the complete final.md book into an export remains a separate implementation task.
