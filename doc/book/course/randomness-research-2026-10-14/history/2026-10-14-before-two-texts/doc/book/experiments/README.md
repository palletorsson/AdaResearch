# Passage experiments

Companion records connect selected writing to interpretations, hypothetical text simulations, executable variants and revisions. Hall files and scenes remain authoritative in their current locations. See [the book architecture](../RECURSIVE_ARCHITECTURE.md).

| Experiment | Read | Reconstruct | Investigate | Current state |
| --- | --- | --- | --- | --- |
| `random-definition.seed-bench-001` | [Hall passage](../../../commons/maps/Random_Definition/final.md) | [Existing seed lesson](../../../commons/maps/Random_Definition/tutorial.md) | [Proposition](random-definition/seed-bench-001/proposition.md), [record](random-definition/seed-bench-001/experiment.json), [text simulation](random-definition/seed-bench-001/text-simulation.md) | Companion authored; height variant proposed, no runtime observations |

The sleeve and remembering-wall alternatives remain [design examples](../course/randomness-research-2026-10-14/text_experiments.json). They are not duplicated here as executed experiments.

## Record contract, version 1

Paths in `experiment.json` are repository-relative. Experiment, passage, interpretation and run IDs are distinct. A source entry binds its passage ID to a source path, exact excerpt and SHA-256 of a recoverable snapshot. A Git revision may supplement this; it must not be invented or assigned to uncommitted content. `sources` and each interpretation's `passage_ids` permit many-to-many relationships. Later observations can reference several interpretation IDs.

`documents` names the proposition, text simulation, observation log and revision log. `interpretations` supplies assumptions, exclusions and operational mapping. `simulation.text` records the hypothetical document separately from `simulation.godot`. An unbuilt Godot variant has a null scene/build, `not_run` execution and no run results. `record_contract` describes future retained state; its `raw_values` is null until an actual baseline is captured. An invented arithmetic fixture is labelled as such and never inserted as observed seed output.

`observations` remains empty until actual evidence exists. An observation must identify its ID, kind, observer/tool, source/build or run, method, interpretation IDs, result and limits; captures point to real files with hashes. Human and automatic evidence are labelled independently. `revisions` links old and new passage/apparatus versions to the observations or source clarification that prompted the change. `learning_debt` and `contributions` retain unknowns without supplying imaginary reviewers or model versions.

`status` describes work state (proposed, in_progress, completed); `disposition` describes editorial placement (experimental, canonical, deferred, abandoned). They answer different questions. A successful experiment can remain noncanonical. Completing the full cycle requires all seven steps and a writing/plan return; unavailable human reconstruction stays not tested. Static record validation does not complete a research task.

## Use and review

1. Select a passage and preserve its source version. State the question and at least one alternative interpretation.
2. Write a hypothetical sequence with assumptions and possible failure. Do not copy a prediction into observations.
3. Build a selected bounded variant in the existing project when that work is undertaken. Link the actual scene, probe, build and retained record.
4. Follow the approved baseline/change/compare/keep/replay/reconstruct/further-change cycle. Record the available evidence and missing stages.
5. Revise the passage, the apparatus or the question; a reasoned disagreement is valid. Preserve old versions and update the task decision.
6. Review reader contributions and editorial disposition separately. An accepted record does not silently alter a frozen edition.

Run `python -X utf8 doc/book/experiments/validate_experiments.py` from the repository root to validate the current companion's provenance, references and proposed-state claims. This is a pilot document validator, not a general runtime importer or a published interchange standard.
