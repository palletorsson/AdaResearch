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

## 5. The match was run (2026-07-31, `tools/museum_match.py`)

Five museums vs the full bred field, three sequences, identical casts (read
from the surviving bred champions), same pathfinder gate, same judge. Reports:
`doc/reports/museum_match_{randomness,transformation,color}.json`.

| seq | bred champion | best museum | museum rank in merged field |
|---|---|---|---|
| randomness | halls 6.63 | uffizi-spine 5.53 | 2nd of 18 |
| transformation | wfc 6.61 | grande-galerie 6.27 | 3rd of 18 |
| color | wfc 8.00 | kanazawa-matrix 7.00 | 2nd of 18 |

What it says:

- **Bred keeps all three crowns — on home rules.** The museums arrive with
  zero tuning (cast dealt row-major into extracted slots) and still take
  2nd/3rd/2nd, beating 10-12 bred recipes every time. Search that optimizes
  the judge beats inheritance that never met the judge; not by much.
- **Grande Galerie is the general-purpose program**: top-4 in all three
  sequences (5.47 / 6.27 / 6.70). The axial rhythm is close to
  register-neutral — which is presumably why the Louvre uses it for
  everything.
- **Kanazawa's tau = 1.0 on color**: the no-hierarchy room matrix, dealt
  row-major, produces PERFECT encounter-order agreement — the anti-spine is
  the best order-preserving architecture in the whole field, and color
  (pattern/composition register) is its natural chapter.
- **The judge has a curatorial position.** Sainsbury posted the largest hero
  presence in every field (heroDeg 74/53/90, rank1 = 1.0 twice) and still
  landed low, because `promise` pays only a hero visible by step 1 —
  the integrated-hero contract. The literature's OTHER contract (bury the
  masterpiece, withhold then pull) is structurally unscoreable by the current
  metric. Castelvecchio (promise 0 in all three) has the same complaint. The
  match's sharpest output is not a ranking but this: the edge fitness encodes
  ONE of the two hero contracts as if it were the definition of composed.
  A `patience` term (late hero climax weighted by its magnitude) would let
  both contracts compete honestly.

Register proposals from the match (propose, never bind): color -> kanazawa
matrix, transformation -> grande-galerie axial, randomness -> uffizi spine.

**RULED 2026-08-01** (Palle: "rule patience in and adopt the 8 museum
crowns"): patience is in the binding score (`max(promise, patience)` hero
point; pre-ruling number preserved as `score_promise_only`), and the eight
classic-score crowns are adopted as `commons/data/museum_crowns.json` —
walked live by the endless museum, which now opens with primitives inside
the Sainsbury. Kanazawa's patience-only isosurfaces win was NOT adopted (its
bred baseline was never rescored under the ruled judge). Standing caveat for
every future tournament: bred baselines predate the ruling — rescore before
comparing.

## 6. Remaining next (proposals, none binding)
- **Seam gate for the spine**: a chain_check analogue for sequence map order —
  model the teleporter join, verify every consecutive map pair.
- **Autopilot for composed maps**: lift `_walk_cells`/`_auto_plan`/`_run_autopilot`
  into a shared walker harness; feed it `map_data.json` structure layers; wire
  as a per-map gate beside the pathfinder (the pathfinder plans; this one
  *walks the plan*).
- **Inducibility benchmark**: run the inverse composer on the fourteen museum
  tiles; publish rule-recovered vs rule-named as a table. Cheap, and it
  calibrates the metric on spaces whose rules are historically attested.
