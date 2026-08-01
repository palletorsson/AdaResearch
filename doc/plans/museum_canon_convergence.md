# The Museum Templates and the Composition Canon — where two template lineages meet

> Working note, 2026-07-31. Written after the fourteen-museum corpus, the
> vestibule, the autopilot, and gates E/F landed. The question: how does the
> endless-museum arc relate to the composition thinking of the last two weeks
> (the order-of-operations canon, organization-is-inducibility, the two-loop
> architecture, the Vitruvian corridor)?

## 1. Two provenances of template, one grammar

The project now breeds templates two ways:

- **Bred** — the composition canon (`composition_grammar.json`, wizard,
  tournament, research loop). Templates emerge from search under our own
  rubric, gated by the pathfinder, promoted by rulings. Provenance: measured,
  then ruled.
- **Inherited** — the museum extraction. Fourteen principal spatial programs
  imported from five centuries of tested architecture, abstracted into the
  same cell vocabulary. Provenance: literature + abstraction — on the
  propose-never-bind rung, like everything sourced but unvoted.

They share one grammar (the `/template-maps` cell vocabulary, stamp mode) and
now one gate stack. The endless museum is the room where they meet: inherited
shells, curriculum-ordered content, composed joins (the vestibule is a small
COMPOSED template — the only piece of the museum neither bred nor inherited
but derived from a failure).

The tournament has never judged them against each other. That is the open
match: stamp a museum tile onto a chapter's cast and let the same fitness that
dethroned wfc-rooms say whether Castelvecchio beats the bred room for a soul
map. The `em_order` arc is a heuristic awaiting exactly this outranking.

## 2. Organization is inducibility — the museums are the proof set

The ARC inversion said: a map is organized to the degree a walker can induce
its rule. The fourteen mechanisms are fourteen *maximally inducible*
organizations — that is WHY those buildings are canonical. Each one is a rule
you can name after walking it, without being told:

- serpentine → "there was never a choice"
- spine enfilade → "walking and looking are different rooms"
- field of bays → "no route; the grid is the only law"
- buried cells → "everything is passage; rooms are events"
- void axis → "the thing organizing my walk is the thing I cannot enter"

So the museum corpus doubles as a *benchmark* for the inducibility metric: if
the inverse composer cannot read the serpentine's rule out of the serpentine,
the metric is wrong, not the building. And the em_order arc (directed → free →
argument) is a curriculum OF organizational rules — the walker meets "one
path" before "no path" before "path organized by absence." That is the same
pedagogical shape as the spine itself: constraint before freedom before
critique.

## 3. Valid-by-construction is a claim until a body tests it

The fast loop's founding rule was "valid by construction — no pathfinder at
runtime." This week measured what construction-validity is worth without an
occupant: five of eight validated tiles broke under a body (a museum that was
a DEAD END), the chain between tiles was never walkable at all, and the
dealer's own hero-scale preference physically sealed Chichu's through-room.
None of this was visible to per-template validation. Three lessons, each one
level up from the last, all generalizable to the composition canon:

1. **Test the tile** (gate E's first half) — dims, vocab, pockets, BFS.
2. **Test the JOIN** (gate E's chain model) — maps in a sequence are also a
   chain, joined by teleporters the way museums are joined by vestibules. The
   composer validates rooms; nothing yet validates the seam between
   consecutive maps as a *walked* transition.
3. **Test the OCCUPANT** (gate F) — plan from the data, execute with the
   body, fail where they disagree. The occupant pass (`walk_polish.py`)
   already looks at composed maps first-person but does not *drive a body*
   through them. The autopilot generalizes: BFS over stamped cells + a
   capsule + move_and_slide works on ANY grid-built space, including
   `wizard_compose` output. A universal walkthrough gate for composed maps is
   mostly a matter of pointing the same code at a different builder.

## 4. The Vitruvian body is now an instrument

The corridor width was ruled by the body (13–17 ≈ 2× promise radius). The
autopilot closes that loop: the capsule (r 0.32, eye 1.65, walk 4 m/s) is the
Vitruvian figure operationalized — the body is no longer just the *unit* the
space is drawn around, it is the *measuring device* the space is tested with.
Gate F is a Vitruvian gate: architecture passes when the body it was derived
from can traverse it.

## 5. Concretely next (proposals, none binding)

- **Tournament match**: stamp end-stopped/matrix/axial museum tiles onto 3
  chapter casts; score with the existing fitness + walk_evaluator; let the
  result outrank `em_order` for those chapters.
- **Seam gate for the spine**: a chain_check analogue for sequence map order —
  model the teleporter join, verify every consecutive map pair.
- **Autopilot for composed maps**: lift `_walk_cells`/`_auto_plan`/`_run_autopilot`
  into a shared walker harness; feed it `map_data.json` structure layers; wire
  as a per-map gate beside the pathfinder (the pathfinder plans; this one
  *walks the plan*).
- **Inducibility benchmark**: run the inverse composer on the fourteen museum
  tiles; publish rule-recovered vs rule-named as a table. Cheap, and it
  calibrates the metric on spaces whose rules are historically attested.
