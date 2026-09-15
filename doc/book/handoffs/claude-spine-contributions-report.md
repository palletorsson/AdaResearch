# Claude report to Astra: spine contributions pilot

15 September 2026. Reply to [`claude-spine-contributions.md`](claude-spine-contributions.md).

**Stages 1–3 are built, and Stage 4's evidence is below. Classification was not expanded.** The Primitives sample waits for your review and Palle's. No game behaviour, map, role ruling, registry, sequence, brief or prose file was changed by this work.

Pilot: <http://localhost:3003/map-curator?view=contributions&sequence=primitives&map=Point_One>

## Review these first

1. **The four calibration rows.**
   [player_trace in Point_Lines](http://localhost:3003/map-curator?view=contributions&sequence=primitives&map=Point_Lines&c=Point_Lines~player_trace~walk-beside-instruction) ·
   [player_trace in Point_Trace](http://localhost:3003/map-curator?view=contributions&sequence=primitives&map=Point_Trace&c=Point_Trace~player_trace~samples-constitute-trace) ·
   [interactive_point_origin_force in Point_One](http://localhost:3003/map-curator?view=contributions&sequence=primitives&map=Point_One&c=Point_One~interactive_point_origin_force~move-the-watched-point) ·
   [wireframe_threshold in Point_Triangle_Context](http://localhost:3003/map-curator?view=contributions&sequence=primitives&map=Point_Triangle_Context&c=Point_Triangle_Context~wireframe_threshold~expose-mesh-after-triangles)
2. **One complete hall:** [Point_One](http://localhost:3003/map-curator?view=contributions&sequence=primitives&map=Point_One). Original text sits beside a proposed summary. Eight anchored works have contributions; seven placed works without an anchored passage are deliberately left without one.
3. **One artifact along the spine:** [player_trace](http://localhost:3003/map-curator?view=contributions&sequence=primitives&map=Point_Lines&artifact=player_trace&tab=artifact), with its knowledge record, controls by lane and both contributions.
4. **The queue:** [Primitives](http://localhost:3003/map-curator?view=contributions&sequence=primitives&map=Point_One&tab=queue).

Every record in the sample is **proposed by claude (agent)**. No review decision or comment has been posted to the real overlay.

## Calibration

| row | result |
|---|---|
| `player_trace` · Point_Lines | **Supported, in the working tree.** Placed at x2,z0 with an explicit primary ruling; the approved passage is quoted. The recorder cell and the stripe (x9,z7) are not adjacent, but the trail is drawn where the body walks, so the comparison still works by eye. Nothing computes a deviation. The placement, the ruling and the walker-following code are all uncommitted. |
| `player_trace` · Point_Trace | **A resolution interaction is not supported by source.** player_trace has no visitor input hook: all thirteen hook patterns count zero in its script. It is not placed in this hall. Recorded as a candidate: visitor action "walking is the only input" (inspected absence), observable result unknown, and a proposed action that says explicitly to write no resolution instruction. The uncertainty quotes the approved `@draw_dot` line that already carries resolution in this hall. |
| `interactive_point_origin_force` · Point_One | **Supported in the museum lane only; corrected after review.** The frame, the readout and the point share `point_one_main`. In the museum lane the map-authored hall passes `#floating_point:0` as the string "0", so the frame follows the held point. In the grid lane `floating_point` is not in `CONFIG_PARAM_NAMES`, so the same pair is read as rotation shorthand and `true`: the frame builds its own point and the guides and card follow that one. Static readings, not runtime observed. Five records carrying the claim are now rev 2 with this qualification (see "Content revisions"). |
| `wireframe_threshold` · Point_Triangle_Context | **Placed (x6,z20, secondary, uncommitted) but without prose.** Recorded as a candidate reading of "exposing mesh construction after triangles", citing field notes and the encounter reference. Capability gained is unknown; the headset renderer is unverified. Its deferral from Point_One is preserved as its own record (below). |
| `wireframe_threshold` · Point_One (deferral) | **Evidence found and cited:** `encounter-reference.md:17`, `fable-final-discovery-voice.md:95`, the space pre-selection archive, the current map and roles absence, and `tests/museum/test_contracts.py:51`. The HEAD placement (0f805e2d6) is written as authored text, because git history cannot be an evidence anchor. The written deferral records are untracked files. |

## What was built

**Three things kept apart.**
- **Subjects**: several parents, aliases, see-also links.
- **Artifact knowledge**: capabilities, controls per lane (visitor at runtime, map config per grid lane and museum lane, exports no token reaches), subjects, application layers, registry disagreements, unknowns with what would resolve them.
- **Contributions**: artifact + sequence/map + an optional pinned instance (cell and raw token). Each holds visitor action, observable result, technical principle, prerequisites, capability gained, an optional critical question, why here, proposed action, an editable reason and uncertainty.
- **Hall records** hold a proposed purpose/brings/does/learns/prepares, always shown beside the original text.
- **Application layers** (object, player, other agents, floor/terrain, wall/material, whole room) are separate from subjects.

**Four states kept apart on every card.** All are computed when a page is read; none is stored as a claim.

| state | values | read from |
|---|---|---|
| placement | placed · candidate · removed/deferred | the hall now: interactables cells, ruled or tagged utility cells, configured museum-entrance fittings, plus evidence-backed history |
| role | recorded ruling · default (no ruling) · none | `artifact_roles.json` now. A candidate never has a role. |
| review | proposed · accepted · deferred · rejected | the append-only review log |
| evidence | documented · source inspected · runtime observed, each current · drifted · stale · unverifiable | fingerprints of the cited file and of the anchored passage, cell, JSON pointer or pattern count |

**Every sourced value carries a basis** that may not exceed its evidence: quoted, paraphrase, documented, source inspected, inspected absence, runtime observed, authored, unknown. "Authored" is allowed only on editorial fields such as reason, why here and uncertainty. Unknown is stored as unknown. "Drifted" means the file changed but the anchored part did not; it shows amber, never green.

**Where it lives.** `AdaResearch_46/doc/book/contributions/`, which the pck excludes. The first forum notice named `commons/data/`; that changed after the inventory.
- `records.json`: records with their prior versions, a per-record `{rev, digest}` guard and a cross-process lock.
- `reviews.jsonl`: append-only decisions and comments. It does not exist yet, because nobody has reviewed.
- `suggestions/<generator>.json`: generated hints, overwritten on regeneration.
- `export/primitives.sample.json`: the sample export.
- `README.md`: the rules.

**Who may decide.**
- Record edits and comments: any declared name.
- Proposed, accepted, deferred, rejected: only a human name on an allowlist in code (`ada_encyclopedia/src/lib/contributions/vocab.ts`). It currently holds only **palle**.
- **Your name is on a pending list.** Nothing in the repo says whether Astra is a person or an agent. A decision under "astra" is refused with `reviewer_pending_ruling` until Palle rules; comments under your name are accepted.
- Reviewer names are declared, not authenticated. The encyclopedia has no login, and the page says "declared".
- A decision binds to one version. A later edit shows "accepted on rev 1; rev 2 unreviewed".
- Origin, meaning who proposed a record, is fixed at rev 1. Each editor is recorded separately.

**Suggestions cannot become decisions.** Two generators exist, both producing hints only. `roles-stale-ruling` flags a ruling in a hall that nothing places. `subject-links` flags a registry tag equal to a subject id or alias. Regeneration rewrites only `suggestions/`. A decision about a suggestion is a review event under its deterministic id, so it survives regeneration. Adopting a suggestion creates a record marked generated, which is still only proposed.

**Interface.** It hooks into `/map-curator` through a new `layout.tsx`; the dirty `map-curator/page.tsx` was not touched.
- **Left:** the 24 spine sequences in `curriculum_spine.json` order, each with its halls in membership order, including empty, missing and unreviewed halls.
- **Centre, Hall tab:** brief or "No brief in spine_briefs.json", `final.md` regions by tag with line ranges, documents with compose hashes, beats marked as hypotheses with their mismatches, the proposed summary, brings/does/learns/prepares, and a link to `/compose/sources?map=`.
- **Centre, Artifact tab:** every registry definition, collisions and case twins, knowledge, controls by lane, instances along the spine with raw tokens and config chips, contributions elsewhere, suggestions.
- **Centre, Queue tab:** grouped by type, with no numeric priority.
- **Right:** filters (subject broad or specific, application layer, placement, evidence, review, text, include unclassified); the hall's placed works; candidates "alphabetical, not ranked"; registry-wide results over every registry token.
- **Per record:** an editor with an editable reason, a review panel, a conflict panel and a copyable handover.

## Evidence

**Acceptance tests.** No test framework existed, so the tests use `node:test` through the `tsx` already installed. They call the production route and library against temporary fixture repositories.

```bash
cd ada_encyclopedia && npx tsx --test tests/contributions/*.test.ts
```

220 tests, 220 pass, 0 fail, twice in a row.

| file | brief test | pass |
|---|---|---|
| `01-spine-order` | 1 · canonical order incl. fractional, membership order, empty rooms, missing maps | 10/10 |
| `02-roundtrip-instances` | 2 · two subjects and two contributions survive save and a fresh-process reload; configured instances stay distinct; multiple parents followed in search | 17/17 |
| `03-honest-fallbacks` | 3 · collisions, case twins, unknown ids, missing image, README, role, contribution | 20/20 |
| `04-subject-candidates` | 4 · subject finds placed and unplaced; candidates never get a role or suitability; no score keys anywhere | 8/8 |
| `05-staleness-conflict` | 5 · every verdict path; decision kept with "evidence changed since decision"; parallel and cross-process edit and review races give reviewable 409s with no lost update | 24/24 |
| `06-regeneration-selfaccept` | 6 · regeneration leaves records and reviews byte-identical; decided suggestions stay decided; every self-accept attempt fails | 14/14 |
| `07-byte-identical` | 7 · 60+ write and read operations leave map_data.json, artifact_roles.json, final.md and `.git/index` byte- and mtime-identical | 11/11 |
| `08-handover` | 8 (API half) · the handover alone is enough to find and check every source | 14/14 |
| `09-origin-permanent` | origin fixed at rev 1 | 2/2 |
| `10-review-fixes` | the confirmed review findings | 15/15 |
| `11-ui-logic` | draft restore, filter wording, placement chips | 16/16 |
| `unit-store`, `unit-sources` | lock, digests, fold, grammar, placement, registry, roles | 38/38, 31/31 |

Each review fix was shown to bite: its test failed against a pre-fix copy or a targeted mutation, and passed after the fix.

**Brief test 8 in the browser.** Run on a disposable copy of the content served on port 3043, so that no test edit or test decision reached the real overlay. The real `records.json` hash was unchanged afterwards.
- Direct navigation with sequence, map, artifact and contribution parameters.
- A subject filter updates the URL and survives reload. Registry-wide search finds an unplaced work by subject.
- Save as Palle gave rev 2, persisted across reload.
- A deferral as Palle was recorded. After a later edit it read "deferred by palle (declared) on rev 2; rev 3 unreviewed".
- A stale second tab got a 409 conflict panel with expected and actual rev and the field-level difference. Nothing was written or merged.
- Copy handover: the success path copied 13,203 characters with ids, rev, "no role in this hall", the declared reviewer, source links, evidence paths and the non-mutation sentence. The failure path showed a read-only, pre-selected textarea with the same text.
- An agent actor sees only "comment" enabled.
- `wireframe_threshold` shows "no image on disk".
- At 400 px nothing inside the view overflows. The page's horizontal overflow is the site header's.
- `/map-curator` without the parameter still renders the board.
- After the fixes, an autosaved draft typed on rev 3 opened beside rev 4 without overwriting it. "Does and learns" under a filter reads "1 of 9 contributions match the filters (8 hidden)" and still lists all nine.

**Screenshots** of the real pilot, read-only, in `ada_encyclopedia/captures/contributions/` (gitignored evidence folder):
- `hall-point-one-1440.png`
- `hall-point-one-400.png`
- `artifact-player-trace-1440.png`
- `candidate-point-trace-1440.png`
- `force-point-one-1440.png`
- `queue-primitives-1440.png`
- `triangle-context-1440.png`

**Sample export:** `doc/book/contributions/export/primitives.sample.json`. It holds 12 subjects, 3 knowledge records, 1 hall, 12 contributions, 61 suggestions and 287 queue items.

**Staleness gate on the real repo:**

```bash
cd ada_encyclopedia && npx tsx scripts/contributions-check.ts --sequence=primitives
```

28 records; 283 evidence items current, 5 drifted, 0 stale, 0 unverifiable; exit 0. The five drifted items are other sessions' edits to `registry/primitives.json` and `Point_Lines/map_data.json` outside the anchored values. That is the mechanism working.

**Guarded files.** `artifact_roles.json` and the four calibration halls' `map_data.json` and `final.md` were hashed before and after seeding, before and after the content revisions, and before and after regeneration. They were identical every time.

## Review findings and fixes

After the build, six reviewers examined the write path, the views, the Point_One content, the calibration content, the tests and the UI. For each dimension a separate skeptic tried to refute every finding. **28 were raised, 24 confirmed, 4 refuted; all 24 are fixed.** Three more defects were found by me in the browser check and in follow-up, and are fixed too.

| severity | finding | fix |
|---|---|---|
| blocker | Restoring an autosaved draft overwrote a newer version with no conflict | The draft opens beside the current version; fields are adopted one at a time; Save targets the current head |
| major | Placement counted only interactables cells, so utilities (`tc`, `sc`, `rc`), special cells (`gridagent:copy`) and the lobby's Folding Past got false "ruling without placement" items and no role | One hall placement set, derived as the role system derives it, with the source named on each instance. Whole-spine `ruling_without_placement` went from 55 to 48, `anchor_without_placement` from 6 to 1 (`two_point_ruler` in Point_Lines, a true positive) |
| major | The Point_One shared-point claim was stated for every lane | Qualified as a museum-lane reading, with a grid-lane uncertainty (content revisions below) |
| major | Search placement was one value per token, so "candidate" missed works placed elsewhere | Placement matched hall by hall, with per-hall states returned |
| major | Under a filter, "Does and learns" said the hall had no contributions | Built from the unfiltered hall; hidden rows are marked |
| major | Search rows said "placed here" for spine-wide placement | Separate chips for this hall and for the spine |
| major | Proposing from a filtered search could seed a placed work as a candidate | Seeded from unfiltered data; the server now refuses a `placement_at_proposal` that contradicts the live hall |
| major | Test 06 still asserted mutable origin | Test corrected to the permanent-origin rule |
| minor | Adoption guards ran outside the lock; untested review-append lock and digest guard; flaky interleave assertion; `prepares` matched by substring; a re-proposed record left the queue; generator hints could set card placement; `walked_length` described too broadly; two filter wording bugs | Each fixed with a test |
| found by me | Editing an agent's proposal relabelled its origin as the editor | Origin fixed at rev 1 |
| found by me | The roles generator still counted interactables only and hinted Folding Past as removed | The generator uses the hall placement set; 19 suggestions became 18 |
| found by me | The handover said "no role in this hall" when only a pinned cell had gone | It now says the role was not read for the pinned instance |

### Content revisions (rev 1 → rev 2, posted as claude through the API)

- `Point_One~interactive_point_origin_force~move-the-watched-point`
- `Point_One~CoordinateSystem3M~guides-separate-a-movement`
- `Point_One~coordinate_readout~an-address-for-the-held-point`
- `hall:primitives~Point_One`
- `knowledge:interactive_point_origin_force`

Each technical principle, observable-result note and proposed action is now a museum-lane reading. A new uncertainty (source inspected) states the grid-lane reading. A second new uncertainty notes that the museum's fallback, the `em_plan.json` snapshot, lacks the link. Quoted text is unchanged.

`knowledge:player_trace` rev 2: `walked_length()` accumulates only while `show_discarded` is on, so it returns 0.0 by default.

## Not done, not run, and known limits

- **Not run:**
  - `next build`, which would overwrite the shared `.next`. The project already has 276 type errors in other files; none in this feature's files.
  - `python -X utf8 tests/museum/run.py`, because no game or content behaviour was touched.
  - Any Godot or headset check. Every lane reading here is static.
- **Museum lane modelled narrowly.** Only a map-authored hall's string config and the lobby fitting are modelled. The plan builder was not traced, so most museum-lane cells read "unknown".
- **Not counted as placements:** artifacts nested inside another's config tail (`exhibit_furniture#mount`, `curation_station#artifacts`, `fontana_puncture#embed_artifact`).
- **Queue items that still read interactables cells only:** `missing_knowledge`, registry collision and case-twin items, and lane items.
- **Editing gaps in the UI.** There is no editor for subject or knowledge records; they were seeded through the API. A subject-link suggestion cannot be adopted in the UI. The editor may offer utility or lobby instances as pin targets, which the server refuses.
- **Evidence limits.**
  - Git history cannot be an evidence anchor, so git-history facts are authored notes.
  - A change of line endings alone reads current.
  - Most evidence was captured from uncommitted files, so more amber is expected as those files change.
- **Concurrency and identity.** The lock is not fair: a writer looping without pause can starve another into a 503 after 5 s, without losing an update. Reviewer names are declared, not authenticated.
- **The throwaway fixture was damaged.** During review, a reviewer deliberately deleted files in the disposable fixture (allowed for that copy). One later chip check therefore relied on the real server instead.

## Unresolved content questions

For Palle, and for you where you have a view:

1. **Is Astra a person or an agent?** Until that is ruled, your name can comment but not decide.
2. **How the grid reads these config keys is the grid owner's call.** In the grid lane these keys are rotation shorthand:
   - Point_Line_Grid: `seam_grid`, `seam_sample_hz` and `show_discarded` (player_trace), so its lattice is probably off outside the museum.
   - Point_One: `floating_point`, `adopt_external_point`, `labels` and `panel` (CoordinateSystem3M), so the shared point does not link.

   The museum reads them as strings. Primitives has 82 such items, many of them the museum staging keys `plinth` and `pin`. Should the keys go into `CONFIG_PARAM_NAMES`, get word values, or stay as they are? Nothing was changed.
3. **Three calibration rows rest on uncommitted working-tree state:** player_trace in Point_Lines, wireframe_threshold at Point_Triangle_Context, and the `point_one_main` link. A checkout or stash would make their evidence stale. Should they be committed as they are?
4. **Point_Trace:** is `draw_dot` the intended carrier of resolution? If so, the player_trace candidate there can be deferred or rejected.
5. **Point_Lines:** the stripe stands at x9,z7 and the recorder at x2,z0. Is "walk beside the instruction" still the relation you want?
6. **`two_point_ruler`** is ruled primary and anchored in Point_Lines `final.md` but placed nowhere. It is the one true anchor without placement on the spine. Is it pending the ruler handoff, or removed?
7. **Empty region tags.** Primitives has 37 empty `<!-- @ -->` tags, 12 of them in Point_Triangle_Context, so most of its works cannot be tied to prose. Who names them?
8. **18 rulings in Primitives have no placement,** for example `spore_mushroom` in Point_One. Are they deliberate records of removal or leftovers? And whose are the ~960 uncommitted rulings? The page labels them "recorded ruling (no author in file)".
9. **Seven placed Point_One works have no anchored passage:** you_are_here, street_talker, 3t, comment_box, fontana_puncture, floating_sphere_field, grab_sphere_point_snap. Should any receive a contribution for beauty, orientation or a detour, or stay as they are?
10. **The 12 subjects and their aliases.** coordinates, trajectory, mesh, lattice, movement and computing drive 360 subject-link hints across the spine. Please check the aliases before trusting those hints.
11. **Should nested mounts and museum fittings count as placements everywhere?** Folding Past now counts, sourced as "configured, not runtime verified".
12. **Is `doc/book/contributions/` the right home for the overlay?**

## Changed files

**`ada_encyclopedia`** (all new):
- `src/lib/contributions/`: `types.ts`, `vocab.ts`, `canonical.ts`, `root.ts`, `git.ts`, `evidence.ts`, `validate.ts`, `overlay-store.ts`, `fold.ts`, `spine.ts`, `token-grammar.ts`, `placements.ts`, `registry.ts`, `roles.ts`, `hall-sources.ts`, `links.ts`, `views.ts`, `handover.ts`, `generate.ts`, `generators/roles-stale-ruling.ts`, `generators/subject-links.ts`
- `src/app/api/contributions/route.ts`
- `src/app/map-curator/layout.tsx` and `src/app/map-curator/_contributions/` (the view components)
- `tests/contributions/`: 13 test files, `_fixture.ts` and `_worker.ts`
- `scripts/contributions-seed.ts`, `scripts/contributions-seed/primitives-pilot.json`, `scripts/contributions-suggest.ts`, `scripts/contributions-check.ts`

**`AdaResearch_46`** (all new):
- `doc/book/contributions/`: `README.md`, `records.json`, `suggestions/roles-stale-ruling.json`, `suggestions/subject-links.json`, `export/primitives.sample.json`
- `doc/book/handoffs/claude-spine-contributions-report.md` (this report)

To re-run the seed, dry run first; re-running is idempotent:

```bash
cd ada_encyclopedia && npx tsx scripts/contributions-seed.ts --dry-run
```

To regenerate hints:

```bash
cd ada_encyclopedia && npx tsx scripts/contributions-suggest.ts --generator=roles-stale-ruling
```
