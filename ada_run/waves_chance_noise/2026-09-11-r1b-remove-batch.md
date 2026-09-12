# Batch handback to Astra — R1b: Random_Remove

Fable 5.1, 2026-09-11, late afternoon, from your R1 follow-up ("Next development hall: Random_Remove… carry the thread from rearranging the same sample to choosing the set eligible for removal; keep the operation inside its owned grid"). Status: **implemented on the existing bench and run in both lanes — bare 72 / 0, live 77 / 0, both exit 0, no script errors, nine views; the panel through the push button's own signal path, the desktop rig's pointer pressing REMOVE ONE and RESET — awaiting your acceptance, a person at the bench and a headset walk.** Nothing committed; forum heads-up 260911-pgl8c.

## The room

**Question:** who was eligible to disappear? **Encounter:** the bench that already stood in the working tree (another hand's, uncommitted since 8 September; the card counts it): a pedestal and a board of sixty-four cubes with numerals, slot plates, a status line and a last-removed line, and a tilted panel — RANGE · ROW · COLUMN · ALL / REMOVE ONE · RESET · NEW SEED. Sixteen amber on arrival, forty-eight grey. REMOVE ONE highlights and takes one amber cube; its plate stays; the line names its column and row; sixteen presses empty the square. RESET restores all sixty-four and replays the same seed's order (the seed named on the status, five digits); NEW SEED starts another; ROW, COLUMN and ALL change the rule before the same grid; the same seed under another rule sends the same draws to different cubes. The final reads the filter, the draw and the deletion apart, with the real lines of each, and asks whether a random choice can be fair to what its set excluded; it hands the changing set to Random_Walk.

**Changes:** `RemoveRandom.gd` — `replay_on_reset` (opt-in, default off: the shipped placements keep their stream), `run_seed`, `removal_log`, `initial_eligible`, `new_seed()`, and these in `get_state()`; `remove_random_fixture.gd` — replay on for the bench, five-digit seeds, NEW SEED, the seed on the status, "no eligible cubes remain" after a full run. Map — `artifact_placement: map` and one clear rect; nothing moved. Texts — final revised (excerpts verified), blurb, intent, summary, critical, technical, tutorial reconciled to the real bench (the old ones described a 12×12 arena of stacked cubes, Gaussian and random-walk removal, a drop animation, undo, and a hazards rig logging deletions as gameplay); `field_notes.md` new. Full account: `Random_Remove/report.md` and the map's field notes.

## Evidence returned

| item | state |
|---|---|
| for a full run, every removed index belonged to the initial eligible set and no index repeats | done, through the push button's own signal path: sixteen presses, sixteen distinct indices all in the arrival block (18–21, 26–29, 34–37, 42–45), the forty-eight grey where they stood, a seventeenth press inert |
| reset restores the complete owned grid and the same seeded run repeats | done: all sixty-four transforms back, sixteen eligible, the same five-digit seed, the next sixteen in the same order cube for cube; NEW SEED gives another seed and another order |
| the museum structure is untouched; physical absence | done: the hall's other meshes and bodies as many after the runs as before (1056), the bound MultiMesh the remover's own descendant, the museum's walk not severed; physical absence is not claimed by the map and not tested |
| a fixed-seed replay comparing two eligibility masks | done: seed 777 over RANGE then ROW — eight removals each, the first in the block, the second in row 3, the lists different |
| museum captures, walks, streaming | done: nine views by their intended cameras; past the bench on both sides 1.00, into the pedestal stopped; the streamer frees and rebuilds the hall with the remover bound to its bench again |
| a person at the bench; headset | pending |

## Limitations, stated

The runs are desktop probes: no hand on the panel, no eye at a person's height; the seed comparison across masks in the probe uses `set_random_seed` (a visitor can replay one seed and change the rule under it, not type a seed); "start/stop" stay the remover's timer, not on the panel; the dark sphere at (5,8) carries a body that stops a walking capsule on column 5 beside the bench (column 4 and the east side run; the museum's own cell walk is not severed) — as the map has it, for Palle; the remover's other placements are unchanged by construction (the flag defaults off), not measured.

## One reusable improvement, and its conditions

**A named, replayable seed on a bench whose set can be changed.** Any chance operation over a candidate set can name its seed, replay it on reset, and let the rule change under the same seed — so the visitor sees the same draws land on different members and learns that the set was decided before chance ran. Conditions: a private generator (never the global stream); the seed re-applied at reset before the set is restored; the set recorded at the run's start and the removals logged, so a probe can prove membership and no repeats; the seed short enough to read and repeat; the replay opt-in where the shipped behaviour kept its stream.
