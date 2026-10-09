# Procedural Generation: give the written encounter its place

20 September 2026. Bounded pass using the [received review](../../review-feedback/2026-09-18/proceduralgeneration/01-review.md), current chapters and current museum. [Before/after comparison](../2026-09-19-review-comparison/index.html#proceduralgeneration).

The sequence already has a useful investigative progression: select → guide → branch → connect → make room → sample and cut → compose. Its question changes with each operation. What can a score notice? Which targets contribute? Who can branch? What counts as contact? Is a connected route wide enough for a body? What survives a representation? Does copying a surface connect places?

All seven `final.md` files are preserved byte for byte. This pass repairs the relation between those chapters and their spatial/curatorial support.

## Findings and decisions

| Hall | Finding | Decision |
|---|---|---|
| Genetic Evolution | The body/score distinction is concrete; the uncounted ring and held witness make the limitation investigable. | Preserve. Do not silently repair the deliberately incomplete estimator and erase the experiment. |
| Space Colonization | Known targets, one directional sum, and persistent growth sites provide a clear ladder from strand to forks. | Preserve. No new runtime acceptance claimed for this hall. |
| Branching Growth | The text notices what counting branch records can conceal: coincident positions and different invitations. | Preserve. The shared lesson controller exists locally; its absence from the old bundle is an evidence gap. |
| Percolation Network | The finite experiment distinguishes face contact, signal reachability and collision. | Preserve the chapter. Overstated legacy registry/source descriptions remain a named metadata task. |
| Caves/Mazes | The book begins at a bodily opening, but the maze stood directly ahead of the entrance. Fresh museum captures confirm the mismatch. | Move the cave onto the entrance axis and the maze beyond an open comparison court. Restore cave → maze in ordered curation. |
| Sculpted Forms | The chapter already earns both the sampled pile and Boolean dome. Flat roles already say primary, while ordered roles and the core record omit the dome. | Align ordered roles and core with mound → dome. Preserve the text and collection. |
| Mirrored Patterns | The written comparison between image copying and network connectivity already uses two primary works. Ordered roles and the core record still omit the network. | Align them with mirrored field → network. Preserve the text and collection. |

The review's role finding was partly right: the flat role table was current, but the explicit reading order and core records were stale. Those are different layers. No artifact needed to be invented or deleted to close this gap.

## Spatial change

In `PG_Caves_Mazes`, `caverandomwalk` moves from cell **(9,12)** to **(19,11)**; `maze_generation` moves from **(19,6)** to **(22,19)**. The console remains at (19,3), and the BSP comparison remains at (11,23). Both active museum plans and the derived long-museum/necklace data now carry these placements.

The cave retains its original dimensions, seed, carving rules and collision. Its front mouth now faces the entry approach. The maze occupies the next court, diagonally beyond the cave. An independent aisle passes around the cave and continues between the maze and the retained rear structure. The manuscript's “Across the court” comparison can remain.

No structure cells, spawn/exit utilities, support covers, original rear structures or artifact implementations were changed. Nothing was removed from the collection.

## Verification

- [Runtime report](review-report.json): **23 checks passed** — 13 artifact/placement/control checks, five support rays and five controlled CharacterBody walk segments. The body enters the front cave mouth and reaches the onward aisle/exit approach. TRACE follows the moved cave; CAVE SEED, MAZE STEP, FINISH and RESET still act on the intended works. The completed maze's array connects entrance to exit.
- [Content checks](content-checks.json): **26 checks passed**, including all seven manuscripts unchanged; paired book markers, role order and core records aligned; current core hashes; unrelated records and museum plan rows preserved.
- `long_museum.py --check` and `museum_necklace.py --check` pass after rebuilding their derived data.
- Matched before/after captures use the same map-space camera positions and opening cave seed. The maze is unfinished in both. These are actual rendered museum captures, not concept images.

Scope: button signals were exercised on the actual controls. Walk segments use the museum's CharacterBody with museum input/catch logic paused and start each segment explicitly. This is not an uninterrupted user walk or a headset test. Maze connectivity was tested in its array; exhaustive cave/maze interior clearance and learner understanding remain open.

The existing generic width ruling still warns that this 38-cell hall exceeds its 13–19 range. This pass retains the established hall dimensions and explicit floor interpretation. The existing decorative `horse_hybrid` build also produces a slow-build warning; no general performance claim is made.

## Deferred, without blocking the spine

1. Future review-package source selection should include the actual `pg_workshop_console` lesson controller even though it is not a book-primary algorithm. Its present decorative classification must not hide its executable role. Resolve named global-class/helper dependencies as a separate exporter task; keep the frozen received package intact.
2. Correct legacy Percolation and natural/autonomous growth descriptions against the bounded experiments before another export. The manuscripts already avoid those overclaims.
3. In a headset, inspect the sequence of approaches, console sightlines/reach, and generated interior clearance. The current checks establish specific possibilities, not a guarantee for every seed or body.

Next: **Soft Bodies**. Follow the change from constructing a form to asking which relations let a body yield, hold together or recover. Read its existing review and choose the smallest material gap that matters; do not impose a uniform rewrite on its nine halls.

Evidence: [changed files](changed-files.json), [exact patch](CHANGES.diff), [runtime inputs](runtime-inputs.json), [museum refresh](refresh.json). Before-files are kept beneath `before/`, excluded from Godot's class scan by this folder's `.gdignore`.
