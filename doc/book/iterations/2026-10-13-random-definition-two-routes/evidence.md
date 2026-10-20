# Evidence and editorial boundaries

Checked 13 October 2026 against the working tree. This is a writing experiment, not an engine change. No new runtime or headset observation is claimed.

## What stands in the hall

`commons/maps/Random_Definition/map_data.json` and the matching `plans` row in `commons/data/museum/em_plan.json` both contain the seed replica grids, textile comparison, number-book page and crank. The seed placement explicitly sets `comparison:replicas`; relying on the artifact's default single-grid mode would describe the wrong hall.

- `algorithms/randomness/seed_replay/seed_replay_demo.gd`: `_regenerate()` resets each column's generator to its seed. The last column can discard `extra_draws` before the three calls used by each RGB colour. `raw_prefix()` uses an independent generator for the displayed strips. `set_grid_side()` changes the matrix without choosing a new seed.
- `commons/artifacts/randomness_space/textile_comparison.tscn` enables textile mode in `dna_comparison.gd`. All three specimens get the same positive seed and different alphabets. In `commons/artifacts/ten_print_textile/ten_print_textile.gd`, `_weave_row()` consumes sample and tint consistently; `_mark()` changes geometry without additional random requests. The block alternatives are a large block and a small block. These panels illustrate marks; the drafts do not call them simulated interlaced cloth.
- `algorithms/randomness/randomnumbergeneration/scenes/random_number_book_page_1955.tscn` loads the script named `random_number_book_page_1995.gd`. The filename's date is not historical evidence. `_on_cell_touched()` toggles freeze. `_cascade_step()` retains frozen cells and shifts other values through the available cells. Departed values have no browsable archive in this implementation. The drafts preserve the freeze exception.
- The crank is placed but reserved in both drafts. Its detailed behaviour was not re-audited for this experiment.

These checks support the described mechanisms. They do not establish current sightlines, comfort, readability, or how a visitor actually experiences the room.

## History and formal precision

The bounded historical episode uses [RAND's own introduction and production account](https://www.rand.org/pubs/monograph_reports/MR1418.html), consulted today. Both drafts refer to that same account; the later museum representation is distinguished from the historical object. No genealogy from the loom to RAND is asserted.

The definition of seeded generation is tied to this deterministic implementation. Same seed alone is insufficient to reconstruct a picture: generator, requests, traversal and assignment matter. The existing tutorial also explains the engine-version condition. The final drafts do not promise a portable, permanent file format.

## Connections across the spine

- `commons/maps/WaveFunctions_John_Cage/final.md` distinguishes the live composition from the **tutorial's kept score**. Both drafts now say “the score from Cage's lesson”, avoiding a claim that the live installation replays or that this is a historical Cage composition.
- `commons/maps/Random_Entropy/final.md` supplies the next encounter: symbol counts and shares can stay while neighbouring relations change. The RGB study and the next hall's categorical dataset remain separate. There is no automatic data handoff in these drafts.
- The sleeve is explicitly imagined. Cube release, wrist following, catching and weight are questions for an extension, not current features.
- The phrase “dress code” is a local literary turn about the garment's conditions. It does not assert that all computational constraints are equivalent to social exclusion. A more explicit queer-historical branch would need its own evidence and space.

## What the comparison can tell us

Both drafts use K1–K9, with R1–R4 reserved. Both keep the title and target 450–700 body words. They vary paragraph order, distribution, bridges and some phrasing. This is an editorial comparison of two pattern adaptations, not a controlled experiment isolating order as its only variable.

If both feel thin at the same point, revisit the pool. If one loses the reader where the other holds them, inspect the bridge and the timing of its explanation. A category count or a model's fit score cannot substitute for this reading.

The source `final.md`, `tutorial.md`, existing saved pattern variations, maps and scripts are unchanged by this experiment. `baseline.md` is a review snapshot of the original final. `study.json` is the editable pool and paragraph map; the two Markdown files are the editable prose.
