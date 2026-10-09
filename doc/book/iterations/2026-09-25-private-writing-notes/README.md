# Private encounter notes

These are working notes for Palle and the writing collaborators, begun on 25 September 2026. They sit outside the hall manuscripts and are not book copy. “Private” describes their editorial role; the repository and local review page do not provide access control.

The scope is every active hall in `commons/maps/curriculum_spine.json`, following each sequence's current `maps` list. Branches and deferred halls are outside this pass. Read the current manuscript beside a note before acting: another editor may have changed it since the source fingerprint was recorded.

## What the notes do

Each hall gets a provisional route through its own material: what the visitor might want, what an encounter can make noticeable, a possible writing operation, where to explain or linger, and a rhythm to consider beside adjacent halls. These are invitations for the next revision, not verdicts that all current chapters need rewriting. Strong existing passages should survive.

The discipline “observe, inspect, distinguish, limit, open” belongs behind the writing. It is not a required paragraph order. Vary the route when the material warrants it, not to meet a quota of literary devices. A return can do new work when its body, scale, receiver, context, timing or question changes.

Evidence can precede an explanation without every encounter ending in a correction. Leave time for beauty, comedy, desire, frustration and successful use. Keep practical instructions clear when delaying interpretation. A visitor's wish is a proposed invitation, not a claim about what every player feels. A proposed passage or interaction is not proof that it works in VR.

## How to use one

1. Read the hall's `final.md` and this short note. Follow its source and artifact references when a concrete uncertainty matters.
2. Choose a route through the encounter. Keep the questions open enough that testing the space can change the writing's destination.
3. Read the two neighboring notes. Check for repeating openings, mandatory critical turns, body-exclusion endings or constant aphorisms.
4. Restore/promote/reposition existing work before treating a strong unsupported passage as disposable. If an important encounter is missing, identify an artifact-development task. The primary-artifact filter is a curatorial instrument, not a one-artifact ceiling.
5. Revise the note when the encounter changes. It is a working hypothesis, not another rule the hall has to obey.

## Storage

- `halls/<Map_ID>.md`: editable, individually authored notes, one per active hall.
- `sources.json`: spine order, manuscript and map fingerprints, manuscript artifact anchors and authored placement tokens as read for this pass. Placements and prose are evidence of authorship, not runtime acceptance.
- `index.html`: a local reading view with sequence navigation and native browser Find with links to notes, manuscripts and encounter maps. Regenerate it with `python doc/book/iterations/2026-09-25-private-writing-notes/build_index.py` after editing a note.
- `all-notes.md`: generated continuous reading copy; edit individual hall notes, not this assembled copy.
- `coverage.json`: generated coverage and freshness checks. New or changed halls are flagged; notes are never silently rewritten.

The source-reading pass does not certify collision, reach, headset comfort or learner response. No manuscript, artifact, scene, primary designation or sequence order is changed by making these notes.
