# Writing-pattern library

[Scientific and poetic attention — authors' strategies](AUTHOR_STRATEGIES.md) is the reusable collection developed with Palle on 15 October. Start with the passage's actual need, then choose an operation: questioning an assumption, inhabiting a measured space, attending to an object, recording a difference, locating a viewpoint, or gathering unfinished encounters. It begins with Bachelard and has expanded to twenty authors with concrete uses and limits. These are editorial proposals, separate from the bounded source studies and existing interactive route cards.

The [composition pilot](../../iterations/2026-10-15-composition-pilot/README.md) assigns provisional operations and counterpoints to Random Definition's five selected artifacts, separately from implementation evidence. It retains a map score, directed relationships and complete chapter candidates, with a Literary view in the writing wall. The record distinguishes assembly reproducibility, factual checks and reader judgement. It is not an automatic style-transfer system or an adopted book-wide narrator.

[Open the interactive library](http://localhost:3003/writing-patterns).

[Read the first full prose comparison: Random Definition, two routes](http://localhost:3003/book-review/doc/book/iterations/2026-10-13-random-definition-two-routes/index.html). A shared, categorised knowledge pool sits beside two final.md drafts, with paragraph instructions, source checks, reserve branches and downloadable reading notes. This is an experiment; no chapter baseline has been selected.

The library holds alternative reading orders for Ada texts. Start with a route, adapt it for a particular hall and text, then record what happens when someone reads the actual passage. The starting routes are proposals; a finished plan does not establish an approved prose baseline.

## Use it

1. **Library:** compare thirteen starting routes, filter tutorial/final, or search by attitude. **Read route** shows instructions, reader gains and bridges. Sources distinguish original Ada proposals from adaptations of our readings of Ahmed, Shiffman and *10 PRINT*.
2. **Compose:** choose **Use this order** to make a separate variation. Change its title and purpose, move nodes with the arrow buttons, and edit each node's information, job, attitude, instruction, reader gain and bridge. The attitude field accepts your own words. Several paragraphs can belong to one movement.
3. Record prerequisites under a node's details. Moving a dependent explanation or construction ahead of its prerequisite produces a review notice. The notices do not invent prerequisites or judge prose quality.
4. Give each movement a provisional prose allowance. Code and actions are separate reading events. Reserve branches preserve possibilities that do not belong in this route; returning them adds them to the end so you can choose their position.
5. **Compare:** put two routes side by side, including the open draft. Compare both knowledge and attitude; their movements need not align row for row.
6. **Reading trial:** name the hall and text version, record observations, choose a local judgement and say what to try next. “Keep for this hall” is deliberately narrower than a universal best pattern.
7. **Save to project** adds or updates the variation in `experiments.json`. **Download writing brief** exports its instructions, prerequisites, reserves and reading notes as Markdown. JSON export retains the structured data.

## Where work lives

- `catalogue.json`: thirteen reference routes. The interface always copies these before editing.
- `experiments.json`: saved variations, available to Palle and later writing sessions. Created on the first save.
- `history/`: previous experiment-library snapshots, written before each save.
- Browser local storage: recovery for one unsaved draft. It is not a shared project save; save or download before replacing it. A save conflict preserves the open draft.
- [PATTERNS.md](PATTERNS.md): the original three Ada proposals and short prose samples.
- [REFERENCE_READINGS.md](REFERENCE_READINGS.md): source readings and their actual textual movements.
- [Writing roles and decisions](../WRITING_ROLES_AND_DECISIONS.md): role distinction, individual trees, timelines and provisional scope budgets.

The page edits plans and observations. Applying a plan to student-facing prose remains a separate writing pass, checked against current maps, inherited lessons and sources.

## Implementation

The encyclopedia serves `/writing-patterns` and `/api/writing-patterns`. It reads the course directory using its configured `ADA_RESEARCH_PATH`. Saves validate the document, check a revision, take a lock, preserve the previous file and replace the experiment library atomically. Only a same-origin JSON request can save. A stale revision is rejected rather than overwriting newer work.

## Paragraph moves and author studies

**Paragraph moves** holds six small structures. Start a draft with one or add one to the end of an open route. In Compose, each movement also has an “Inside this movement” editor: choose a paragraph pattern, change its small instructions and attitudes, reorder steps, add custom steps and rewrite the transitions. Read-route, Compare, Markdown export, JSON and project saves retain these nested steps. The parent word allowance includes their prose.

**Author studies** holds six readings with edition and passage locations. Select an author, open the source and compare the observed timeline with the proposed Ada instructions. “Try an Ada adaptation” creates an untested draft, keeping the source study unchanged. Some rows group adjacent paragraphs; Carroll deliberately selects two episodes and marks the intervening omission. These are local interpretations, not universal author styles.

- `craft.json`: six paragraph presets and six author studies with separate Ada adaptations.
- [PROVENANCE.md](PROVENANCE.md): verified Ada Writer harvesting workflow, limits of the preset provenance, source list and study method.

The earlier source readings remain available. All new routes and adaptations remain untested on student prose until a reading trial records evidence.
