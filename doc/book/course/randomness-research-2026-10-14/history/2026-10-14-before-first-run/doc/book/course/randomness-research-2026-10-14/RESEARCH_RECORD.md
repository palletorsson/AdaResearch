# A record that can change the next experiment

**Proposed contract, 14 October 2026; not an implemented storage system.** Start with one local seed-bench record, then a CPU particle record. Add fields only when needed for a declared replay or transfer. Preserve the existing canonical scenes and implement adapters around their relevant state.

## Three linked kinds of work

The tutorial is a reconstructable kit: named incoming program, complete new operation, prediction, run, one-condition change, comparison, reset and independent rebuild. The final text is a situated encounter: an object, a history, a bodily consequence or a question can change what the author thought the work was doing. Field notes record what happened, what remains untested and why another experiment is worth trying. These should cross-reference one another without making final prose narrate every instruction.

The later supplied texts make dissipated authorship an explicit methodological direction: understanding can arrive at different moments from composition or implementation. Learning debt includes what a collaborator does not yet understand, as well as what lacks evidence. [The Text Simulation Loop](TEXT_SIMULATION.md) lets writing initiate an apparatus and observations revise both its prose and its future tasks. AI can produce a plausible sentence or implementation before its maker understands it. That creates work to do: inspect, reconstruct, attribute, revise or withdraw. Record that debt without treating assistance as disqualification or as proof. Preserve relevant source and license notices and name the person responsible for accepting a published claim.

## Minimal record and conditional state

| Group | Required information when applicable | Contract |
| --- | --- | --- |
| Identity | schema, run/parent ID, map/artifact, engine/build and apparatus version | A changed experiment creates a child; the preserved parent stays unchanged. |
| Source | source kind, provenance/acquisition ID, validation status, generator/version, seed, draw roles/order and state | Replaying stored values never silently reacquires; an unavailable or unvalidated source stays labelled. |
| Baseline and intervention | parameters, a named changed condition, before/after values and operation order | The first comparison holds other recorded conditions fixed; hidden coupled changes are reported. |
| Replay payload | retained samples or initial/entity state, fixed tick and tick count, birth schedule/accumulator, next IDs, boundary events, receiver/rule version | Only fields required by the chosen replay are stored. A seed alone does not reconstruct event order or variable-frame births. |
| Observation | prediction, observed difference or lack of difference, measurement/units, evidence link and who judged it | A surprising failure or an inconclusive result can be retained. Aesthetic interest is not an automatic score. |
| Next action | open question, proposed/implemented further change, reason and related task | The seven-step cycle ends here; a replay-only result is incomplete. |
| Evidence | artifact/cycle/transfer scope plus separate loading, stability, performance, headset and learner status | Use pass/fail/not tested/inconclusive with evidence. Do not derive human understanding from automation. |

Export/import, clear and restore are explicit operations. Every receiving hall has a usable local baseline. On import failure the visitor can preserve the original and deliberately choose that baseline. Do not silently discard roles, change rule versions or reseed. Apply size/version validation before accepting a record. An application restart is in scope only where persistent retention is promised.

No raw headset pose, microphone or body stream is stored by default. For a force replay, prefer a minimal synthetic or voluntarily recorded target trace in apparatus coordinates over full tracking data. State its necessity and retention choice at capture. CPU reference runs define exact/toleranced guarantees explicitly; physical throws and GPU effects do not inherit them.

## Learning-debt and contribution entries

An entry identifies a claim or passage version, its basis, linked evidence, contributors/assistance, status, responsible reviewer, next test and the decision that follows. Use clear basis labels: source inspection, measured capture, human observation, hypothesis, borrowed/AI-proposed, or untested. A claim can have more than one basis, and a source inspection is not a headset capture. No automatic novelty score is needed.

Here is a real open question grounded in this specification's source audit, not an invented experimental result:

| Field | Example |
| --- | --- |
| Claim | Does the curl-particle comparison replay after a boundary exit? |
| Basis/evidence | Source inspection in FINDINGS.md: initial seeding, global respawn draws and frame-delta updates; source hashes in inventory.json. |
| Status | Simulation replay untested; no headset or independent learner evidence. |
| Contribution | Existing implementation and this source review; the proposed fixed-tick/recorded-respawn comparison is design work. |
| Next test | Same retained births, one fixed tick schedule, local recorded respawns; compare traces before/after an exit over a declared interval, then vary render cadence. |
| Decision | If records diverge, keep the failure and isolate input/update ordering before asserting replay. If they agree, publish only the tested scope and pursue a meaningful field comparison. |
| Responsible reviewer | Assigned when the implementation task is claimed; currently unassigned. |

## Versioned prose and the experimental ending

For the selected pilot or a later hall trial, keep apparatus A, its evidence and passage A beside apparatus B, its evidence and passage B. Identify the concrete behaviour that makes a sentence accurate in one version and false or incomplete in another. Do not manufacture an observation to make the literary experiment work. Keep unbuilt possibilities conditional and preserve the old record when the room contradicts the writing.

The first pilot still needs only a short observation and next change. The five writing tasks extend that practice into an editorial charter, linked ledger, paired passages, terminology/source review and a named decision to accept, revise or defer. The ledger supports the encounter; it need not become a compulsory worksheet in the visitor's path.


## A passage can start the experiment

Selected records also link a stable passage ID and exact source version to several interpretations, each with its own assumptions and apparatus variants. Preserve the many-to-many relation: several worlds can respond to one paragraph, and one world can generate competing accounts. The prose remains literature; its companion interpretation supplies the operational decisions needed for reconstruction. See [two unbuilt design examples](text_experiments.json).

Extend learning-debt entries with the collaborator or position to which understanding is missing. Distinguish unverified claims, unfamiliar working mechanisms and unresolved meanings. Mark unknown origins rather than assigning them an author. Keep text-only reasoning, executed simulation, AI image interpretation and human encounters separate. A later return can revise the question without closing the debt.

After the first pilot, preserve the old task graph and record a decision to continue or change it. The final record can therefore yield a revised passage, a new apparatus, a different task dependency or a retained disagreement. [Plan revisions](plan_revisions.json) keep the reason and before/after identities. This is a proposal for research practice, not an automatic loop that executes whatever a passage suggests.

## Book companion and edition identity

The [concrete companion](../../experiments/random-definition/seed-bench-001/experiment.json) links a source snapshot/excerpt to two explicit interpretations, a hypothetical text simulation, open debt and future runs. Its [record contract](../../experiments/README.md) defines repository-relative paths and distinct passage/interpretation/experiment/run IDs. No sampled baseline or observation has been invented to fill it. The existing generic run record remains the place to preserve actual apparatus state; the companion refers to that record rather than making a second copy.

A source hash detects a difference but cannot recover missing text. Preserve the source bytes or a reachable immutable Git object. Keep the hall's current source in place and bind each experiment to the version it actually used. Reader contributions remain proposed until a named review distinguishes the observation, interpretation and publication decision.

A frozen edition selects an ordered set of recoverable passage/tutorial, image, code and experiment versions, and identifies its readable output and change record. It can expose unresolved learning debt without including every branch. Subsequent changes produce a new edition. The [architecture](../../RECURSIVE_ARCHITECTURE.md) specifies this contract; the current documents do not constitute a published or frozen edition.

## Two initiating texts and two independent reviews

An initiating source has a `text_role` of tutorial or final, a passage ID, an exact source version and the question it contributes. Either role can initiate alone; both can initiate together. Keep the two questions separate even when they meet in one experiment. The seed-bench pilot binds both current texts: changing RGB assignment from the tutorial, and questioning the jobs assigned to values from the final.

Before execution, record what result or difficulty could change the interpretation or planned work. After execution, `text_reviews` contains a separate tutorial and final entry with source version, observation references, decision, reason and successor version if revised. Allowed decisions are revise, retain_with_reason and open_question; pending is not a completed review. A speculative passage need not be turned into a technical instruction or rewritten to claim agreement with the result.

The companion's next-experiment decision remains empty until actual evidence can support continue, redirect, defer or stop. Link the selected question to that evidence in W005. Unexpected behaviour and reconstruction difficulties can motivate it; a mostly predictable first comparison is still useful for testing the method. Do not record the proposed second experiment as already run or require every cycle to generate a new hall.
