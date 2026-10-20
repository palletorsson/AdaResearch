# Writing as critical and associative inquiry

14 October 2026 · Specification extension · ready-for-agent as planning input

This extends the [research specification](SPEC.md), [recursive architecture](../../RECURSIVE_ARCHITECTURE.md) and [voice study](../../VOICE_STUDY.md). The two [supplied notes](imports/2026-10-14-writing-composition/manifest.json) are preserved exactly. They motivate this revision; their accounts of earlier editorial success are not new reader-test evidence.

## Problem Statement

The existing loop can take a passage into an implementation and return an observation to the writing. It does not yet give `final.md` a sufficiently concrete method for choosing what knowledge belongs, arranging a reader's developing questions, or testing a critical association against the apparatus that prompted it. A technically successful experiment can still produce an unnecessary explanation or a predetermined interpretation.

The research is a network; reading takes time in an order. Selecting that order is consequential artistic work. The book must make room for an exact definition, a historical detour, an unresolved image and a difficult transition without turning every paragraph into an experiment proposal.

## Solution

Keep two equal, distinct research practices. `tutorial.md` develops operational capacity: construct, understand, test and modify. `final.md` develops situated critical and associative attention: what the apparatus reveals, conceals, privileges, excludes or makes desirable. Both can initiate experiments and both receive an independent review afterward. Neither exists merely to justify the other.

Add the **Knowledge–Desire–Composition Loop** alongside the Text Simulation Loop:

**Research pool → knowledge selection → paragraph cards → competing reading routes → draft → ghost reading → editorial review → final.md → experimental return.**

Return observations, rejected interpretations and unused connections to the pool. A reading route is a selection from that pool, not its replacement. A published edition still freezes a particular selection with recoverable versions.

The first writing pilot remains **Random Definition and its 48-value seed bench**. The hall sequence and five particle tutorials keep their existing order. A new source apparatus, including the separately requested lava wall, does not replace this writing pilot or count as completed reader evidence.

## User Stories

1. As a writer, I want a research pool larger than a chapter, so that unused knowledge remains available without overloading the encounter.
2. As a writer, I want each candidate connection to retain its source and evidence status, so that an attractive association cannot quietly become a finding.
3. As a reader, I want an encounter to give me a reason to pursue an explanation, so that information arrives in response to developing attention.
4. As a writer, I want to state each paragraph's job and reader gain, so that correct information still has to earn its place.
5. As an editor, I want competing routes through the same pool, so that I can compare changes in attention rather than unrelated quantities of research.
6. As an editor, I want to retain friction or interruption with a reason, so that coherence testing does not enforce seamless prose.
7. As a researcher, I want critique to name a specific operation, boundary or encounter, so that theory does not predetermine the artifact's meaning.
8. As a researcher, I want an interpretation to generate an operational difference, so that an experiment can challenge my criticism as well as illustrate it.
9. As a contributor, I want a weakened or rejected association retained, so that the record shows what changed our thinking.
10. As a writer, I want edge, leak, technical bias and attachment available without quotas, so that chapters do not repeat a critical template.
11. As a reader, I want history and artistic association to change how I see an earlier encounter, so that a detour has consequences.
12. As an editor, I want a ghost reader to encounter only the current prefix, so that its expectations are not manufactured with knowledge of the ending.
13. As an author, I want AI coherence reports separated from human responses, so that simulated attention cannot certify pleasure, desire or discovery.
14. As a learner, I want tutorial reconstruction assessed separately from literary movement, so that neither successful code nor compelling prose substitutes for the other.
15. As an editor, I want the authority to select, combine, revise or defer routes with recorded reasons, so that a model's preference does not automatically publish a chapter.
16. As a returning researcher, I want both texts reviewed after an experiment, so that a changed interpretation can revise the tutorial, final, apparatus or future task plan.

## Implementation Decisions

### Research pool and knowledge selection

Each candidate has a stable ID, a claim or question, recoverable source versions, evidence kind/status, relations to other candidates, uncertainty and a possible reader question. Keep technical facts, reported observations, historical claims, interpretations and speculation distinguishable. Known contributors and unknown origins remain explicit. Link to the existing experiment record instead of copying its results into a second authority.

Before selecting a connection, ask what makes the reader want to know it here. Consider whether it is situated, desired, transformative or generative. These are editorial questions across a passage, not numerical scores or four requirements for every paragraph. Record why selected material belongs and why other material is parked.

### Paragraph cards and reading routes

Use the six existing fields and two optional dimensions:

| Field | Editorial question |
| --- | --- |
| Information | What enters, and what supports it? |
| Job | What does this paragraph do here? |
| Attitude | How does it approach the object? |
| Reader's gain | What becomes intelligible, perceptible or questionable? |
| Bridge | Why does the next connection arrive now, including a deliberate interruption? |
| Size | How much reading time and space does it deserve? |
| Critical pressure | Which specific edge, leak, bias or attachment matters, if any? |
| Experimental potential | What might be changed or observed next, if anything? |

The last two fields may be null. Size is an initial editorial budget, not a rigid word count. Cards name candidate IDs; routes order card IDs and explain the sequence of questions. A route can leave cards out. Unused cards remain recoverable. Do not append every possible association to the chapter.

Compare a consequence-first opening with a route that braids encounter and history. Retain a possible hybrid. The supplied note reports an earlier preference for A's opening and B's structure; record that as a reported precedent, not a newly verified choice. Keep literary route A/B separate from both the physical source-versus-Entropy hall-order trial and the bench's mapping comparisons.

### Four ways of applying critical pressure

| Lens | Ground it in | Possible experimental return |
| --- | --- | --- |
| Edge | An exact threshold, permitted action, discontinuity or boundary | Vary that boundary while naming what remains fixed |
| Leak | Something a particular measurement or representation omits | Preserve the omitted relation or compare another measurement |
| Technical bias | A sampling, coordinate, category, default or mapping choice that favours an outcome | Change that choice without treating it as natural necessity |
| Attachment | A situated wish to keep, avoid, inhabit or transform something | Let that wish propose a change; do not invent a visitor's response |

These are optional instruments of attention, not four mandatory chapter sections. Technical bias names a consequential choice; it does not by itself establish a moral judgment. For example, a **frequency-only** entropy calculation omits adjacency; this is a claim about that measurement, not every use of Shannon entropy.

A critical proposition records its technical anchor, association, alternative reading, proposed intervention, comparison and what would make us revise or abandon it. A fixed grid might suggest enclosure; it might also support orientation and revisiting an address. Neither interpretation is proven by the grid. Making cells detachable tests a selected operational interpretation, not the truth of a whole political theory. A contradiction, an unhelpful change or a wish to keep the original can all alter the writing.

Scientific/technical, critical and associative/artistic attention should transform one another. Art is not a decorative third layer applied after the mathematics.

## Testing Decisions

Use one shared seam: a **versioned passage–encounter record**, linked to the existing experiment companion. It contains the selected pool items, cards, route/draft version, exposed reader prefixes, scoped responses, editorial decision and any experimental return. Keep each observation's kind and limits. Do not create a separate runtime pipeline for literary review.

| Review | What it can establish | What it cannot establish alone |
| --- | --- | --- |
| Technical simulation | Behaviour under a stated intervention | Literary consequence or human understanding |
| Tutorial reconstruction | A named reader or tool can rebuild and investigate under recorded assistance | That another person learned, or that the final is compelling |
| Ghost reading | A model's prefix-local understanding, expectations, questions and transition difficulties | Human desire, pleasure, strangeness or lasting memory |
| Human editorial/reader review | A particular person's situated response and selection reasons | A universal audience response or automatic technical correctness |

For ghost reading, supply only the draft prefix available at that step. Before revealing the next paragraph, retain the model's understanding, expected continuation, unanswered question, changed view of an earlier encounter and any unmotivated transition. Log input versions, assistance, model identity when known and exposure limits. Use a fresh context for each route comparison; a model already shown the full route cannot be described as a blind reader. Keep original responses rather than rewriting them after the ending. A future prompt or task is not a completed ghost-reader run.

An editorial decision can accept, revise, combine, defer or reject a route. It cites concrete passages and reasons, including why a difficult transition is worth retaining despite a negative model report. The task cannot invent human approval. The chapter must also work as prose without opening Godot. “Does this next encounter make the earlier one more interesting?” is a review question, not an automated metric.

When a critical proposition becomes an experiment, retain the approved seven-step cycle: baseline; one change; comparison; preservation; replay; independent reconstruction; further change. Keep artifact, experiment-cycle and specified cross-hall checks separate from loading, stability, performance and physical VR. Record what would contradict the interpretation before running it. Review both texts afterward with revise, retain-with-reason or open-question; no rewrite quota applies.

Static validation checks recoverable sources, pool/card/route references, dependency order and honest unrun states. It cannot pass a chapter's literary quality or complete a human review.

## Out of Scope

This revision does not rewrite every hall, publish an edition, install a new reader interface, score literary value, require a new apparatus for every association, or claim that the proposed A/B readings have happened. The existing first pilot and its unfinished human reconstruction remain visible.

## Further Notes

The [concrete pilot plan](WRITING_PILOT.md) demonstrates this method without asserting reader outcomes. New tasks W006–W010 extend the existing tracker; W001–W005 retain their identities and evidence. Start with the pool, then cards/routes, then drafts and separate reader review. A critical return and explicit editorial decision precede the existing edition task. Local writing work can begin before completion of the particle curriculum.
