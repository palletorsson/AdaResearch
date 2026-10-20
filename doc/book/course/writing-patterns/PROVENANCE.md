# Where a writing pattern comes from

## Strategy collection · added 15 October 2026

[Authors' strategies](AUTHOR_STRATEGIES.md) is a separate set of editorial prompts for scientific and poetic attention, grounded in the current touch-line encounter. It records which entries have primary-text checks, which draw on publisher/work descriptions, and which continue Palle's supplied comparison. Its original Ada uses are hypotheses for reading trials. It does not expand the six bounded passage studies in craft.json or retroactively supply provenance for older presets.

13 October 2026. [Open the writing desk](http://localhost:3003/writing-patterns).

## What the Ada Writer project establishes

Palle remembers supplying existing writing for analysis. The project contains exactly that capability: `src/app/api/rules/harvest/route.ts` accepts pasted text or a map file, calls a selected model, and asks for four to eight short, imperative, testable writing rules. A user can then save a candidate in the rule library. Records distinguish `manual` and `ai_harvest`.

That confirms the workflow existed. It does not establish the origin of every rule. The five whole-text patterns and six paragraph moves imported here are adaptations of presets in `src/lib/writing/rule-library-shared.ts`. Their seed records do not identify an author, passage, edition or extraction session. The application labels seed records `manual`; that label alone does not prove human authorship. The available source and Git history do not tell us which supplied texts, if any, led to these particular presets. No live database audit was performed.

The journal page `src/app/blog/writing-moves-and-formulas-as-rule-vectors/page.tsx`, dated 18 March 2026, describes adding twenty moves and twenty-nine formulas as a craft layer alongside theorist orientations. They are present in Git commit `179857c` of 6 April. These are a journal date and a repository date, not verified dates of extraction. The current source also contains four additional final-specific move rules; those were not imported.

All paths above are relative to `C:/Users/palle/Documents/GitHub/ada_writer_pro/ada_writer`. That project was inspected without modification.

The old harvesting prompt jumps directly from source text to reusable commands. It does not require paragraph locations, the observed order, evidence for transitions, or a distinction between what the author did and what Ada should try. Our new workflow preserves those missing steps.

## Three different records

1. **Preset:** a useful compositional proposal whose original passage evidence is unknown. The five imported routes and six paragraph moves have this status.
2. **Source study:** an editorial reading of a particular passage in a named edition. Its observed order is retained. Attitudes and rhetorical jobs are interpretations, not declarations of the author's intention.
3. **Ada experiment:** new instructions adapted for a particular hall, with a word allowance, inherited knowledge, bridges and a reading trial. A source study can inspire it without licensing the source's factual claims or philosophical commitments wholesale.

The page keeps source studies separate from editable adaptations. “Try an Ada adaptation” copies the proposed movement into Compose. The source reading remains intact. Paragraph moves can be placed inside any larger movement, reordered, rewritten and combined with custom small steps. Their words are already included in the parent movement's allowance.

## How we study an author passage

Choose a short passage with a verifiable source and edition. Mark real paragraph boundaries, paragraph groups and omissions. Treat dialogue, epigraphs, code, lists and images as distinct events where they matter. For each unit record:

- **Information:** what enters here?
- **Job:** what does it do to the developing thought?
- **Attitude:** how does the passage approach its subject or reader?
- **Bridge:** what makes the next move possible or necessary?

Record alternative readings where a passage could do several jobs. Only then generalise a possible route. Build an original Ada passage using it, check every artifact claim against the map, and see what a reader can understand, reconstruct or question. A graceful diagram is not evidence of learning. “Keep for this hall” is a local judgement, not a universal best formula.

Preserve what a route leaves out in the reserve branches. A long chapter asks for a scope review; it does not automatically require another map. Tutorial prose must explain its new example with the needed code and prerequisites. Final prose can travel through history, formal thought, criticism, pleasure and uncertainty, returning where that return earns its place.

## Initial source studies

The page contains six bounded studies, not six complete accounts of an author's style. Locators, observations, attitudes and original Ada adaptations are stored in `craft.json` and displayed together under **Author studies**.

| Author | Passage | Source |
| --- | --- | --- |
| Donna Haraway | *Situated Knowledges*, pp. 580–581: transition into The Persistence of Vision | [Journal article PDF](https://terra-world.github.io/pdfs/haraway_situated_knowledges.pdf#page=7) |
| Gilles Deleuze and Félix Guattari | *A Thousand Plateaus*, Introduction: Rhizome, opening three prose paragraphs, pp. 3–5; Massumi translation | [Excerpt PDF](https://manoftheword.com/wp-content/uploads/2013/05/deleuze-guattari-rhizome.pdf#page=1) |
| Sara Ahmed | *Queer Phenomenology*, pp. 3–4: orientation and the writing table | [PDF](https://www.thequeermathematicsteacher.com/wp-content/uploads/2021/10/Ahmed-Queer-Phenomonology.pdf#page=9); checked using the previously downloaded copy when the public link returned 403 |
| Friedrich Kittler | *Gramophone, Film, Typewriter*, Introduction, first seven paragraphs; Stanford course transcription | [Introduction](https://web.stanford.edu/class/history34q/readings/Kittler/GramFilmTypwriter/Kittler_Intro.html) |
| Gaston Bachelard | *The Poetics of Space*, Chapter I, first six prose paragraphs after the epigraph, pp. 3–5; Jolas translation | [PDF](https://whslearningcommons.com/wp-content/uploads/2014/05/gaston-bachelard-the-poetics-of-space.pdf#page=39) |
| Lewis Carroll | *Through the Looking-Glass*, Chapter II: opening path episode, then the approach to the Red Queen; intervening dialogue omitted from this study | [Chapter transcription](https://en.wikisource.org/wiki/Through_the_Looking-Glass,_and_What_Alice_Found_There/Chapter_II) |

These writers have different philosophical projects. Reading their structure does not make them all OOO writers. We borrow a possible movement of attention, investigate its costs, and write in Ada's own voice.
