# Passage experiments

Companion records connect selected writing to interpretations, hypothetical text simulations, executable variants and revisions. Hall files and scenes remain authoritative in their current locations. See [the book architecture](../RECURSIVE_ARCHITECTURE.md).

| Experiment | Read | Reconstruct | Investigate | Current state |
| --- | --- | --- | --- | --- |
| `random-definition.seed-bench-001` | [Hall passage](../../../commons/maps/Random_Definition/final.md) | [Complete continuation](random-definition/seed-bench-001/tutorial.md) | [Proposition](random-definition/seed-bench-001/proposition.md), [record](random-definition/seed-bench-001/experiment.json), [text simulation](random-definition/seed-bench-001/text-simulation.md) | Scripted cycle passes; tutorial revised, final retained; human trial open |

The sleeve and remembering-wall alternatives remain [design examples](../course/randomness-research-2026-10-14/text_experiments.json). They are not duplicated here as executed experiments.

## Record contract, version 1

Paths in `experiment.json` are repository-relative. Experiment, passage, interpretation and run IDs are distinct. A source entry binds its passage ID and `text_role` (tutorial or final) to a source path, exact excerpt and SHA-256 of a recoverable snapshot. A Git revision may supplement this; it must not be invented or assigned to uncommitted content. `sources` and each interpretation's `passage_ids` permit many-to-many relationships. Either text can initiate alone or both can initiate together. Later observations can reference several interpretation IDs.

`documents` names the proposition, text simulation, observation log and revision log. `interpretations` supplies assumptions, exclusions and operational mapping. `simulation.text` records the hypothetical document separately from `simulation.godot`. An unbuilt Godot variant has a null scene/build, `not_run` execution and no run results. `record_contract` describes future retained state; its `raw_values` is null until an actual baseline is captured. An invented arithmetic fixture is labelled as such and never inserted as observed seed output.

`observations` remains empty until actual evidence exists. An observation must identify its ID, kind, observer/tool, source/build or run, method, interpretation IDs, result and limits; captures point to real files with hashes. Human and automatic evidence are labelled independently. `revisions` links old and new passage/apparatus versions to the observations or source clarification that prompted the change. `learning_debt` and `contributions` retain unknowns without supplying imaginary reviewers or model versions.

`status` describes work state (proposed, in_progress, completed); `disposition` describes editorial placement (experimental, canonical, deferred, abandoned). They answer different questions. A successful experiment can remain noncanonical. Completing the full cycle requires all seven steps and a writing/plan return; unavailable human reconstruction stays not tested. Static record validation does not complete a research task.

`initiation` links each initiating question to its source role and passage version, and names what could make us reconsider the interpretation or work. The seed bench binds both texts as a concrete example. `text_reviews` keeps tutorial and final reviews independent: after evidence, each records revise, retain_with_reason or open_question, with reasons, observations and a successor source if changed. No forced rewrite or agreement is required. `next_experiment` names the evidence behind continue, redirect, defer or stop. Its question and decision remain null while waiting for real observations; the sleeve is not the default second task.

## Use and review

1. Select a question from tutorial, final or both, and preserve each source version. State what could change the question and at least one alternative interpretation.
2. Write a hypothetical sequence with assumptions and possible failure. Do not copy a prediction into observations.
3. Build a selected bounded variant in the existing project when that work is undertaken. Link the actual scene, probe, build and retained record.
4. Follow the approved baseline/change/compare/keep/replay/reconstruct/further-change cycle. Record the available evidence and missing stages.
5. Review both texts separately, allowing revision, reasoned retention or an open question. Preserve old versions and update the apparatus or task decision using actual evidence. The next experiment is selected from what happened; it may also be deferred or stopped.
6. Review reader contributions and editorial disposition separately. An accepted record does not silently alter a frozen edition.

Run `python -X utf8 doc/book/experiments/validate_experiments.py` from the repository root to validate the current companion's provenance, references and scoped execution, source receipts and unresolved human evidence. This is a pilot document validator, not a general runtime importer or a published interchange standard.
