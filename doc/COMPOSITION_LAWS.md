# Composition Laws — what seven rounds taught the composer

> Prose companion to `commons/data/composition_grammar.json` (the machine-readable canon
> the engines run). The canon holds the what; this holds the why. One day, 2026-07-24:
> seven research rounds, a wizard, a track, one real sequence. Written so the next
> session — or the parallel one — inherits the thinking, not just the weights.

## The laws, with their stories

**FIT** — a piece whose envelope exceeds the room belongs to another room (or another
role — see the open problem below). Born when scale_lines' 100 m measurement exploded a
layout into a 190 m corridor. Runs in BOTH directions: the gate grows rooms to fit
artifacts; the track pours artifacts into rooms that already exist. Same law, two arrows.

**REACH** — a high-aspect envelope is reach, not body. Space by the body; aim the reach
along the walk. laser_measure's 50 m beam inflated *every* layout of rounds 1–3 as a
51-cell "footprint"; the round-3 runway that looked like a layout mistake was this law,
unenforced. When the wizard engine enforced it (aspect > 4 → body-sized rooms), the
ribbon died in all ninety round-4 variants at once, without the lever built for it.
*A law enforced beats a lever added.*

**MOAT-AS-HYPOTHESIS** — runtime growth is stochastic; containment is re-tested every
run, never assumed from one clean capture. The mold escaped a 3-cell moat that had held
the run before.

**SEAM** (track) — segment edge rows carry walk at the shared center columns; a wall or
a room on the seam cuts the world. Learned twice in one hour: the yard's wall row severed
the track at reach 0.22; the chamber's full-width room made its own entry a dead pocket.

**LIFT** — no lift without a step: every procession-raised room needs a wp climb at its
mouth. A doorless lifted room strands its artifact. Found because every +4 plan in round
7 failed with the *same* unreach count.

**The floor's hard contracts** — spawn is exactly `s`; teleporters stand on void;
climbing requires `wp`; a door is only a door if it opens onto floor. Flat maps mask
these; the first walled map exposes them.

## The meta-laws (worth more than any metric)

1. **Metrics are hypotheses the eye falsifies.** Round 1's scorer optimized closets.
   Every metric that now exists — enclosure, arrival, compact, tissue, story — is an
   eye-observation formalized *after* the score got it wrong. The loop is:
   score → look → name what the score missed → make it a number → repeat.
2. **The order of operations is itself the design space.** Templates-early (r2) changed
   everything downstream; arrival is *resolved* early but *carved* late (r5 — carving
   the threshold before rooms sealed the spawn). What is included, in what order, is
   the composition. (This was the founding directive.)
3. **A guarantee is not a repair — it is a re-ranking.** Fixing the parapet's position
   accident (r6) didn't rescue weak variants; it revealed that the crescendo courtyard
   had been the better gate all along. Implementation fairness is part of the search.
4. **Never trust a leaderboard whose failures share one number.** Round 7's first run
   said "+4 kin kills, auto is worst" — every failure had unreach 2, and both findings
   were one bug (LIFT). Diagnose the shared number before believing the ranking.
5. **Trust the number that counts, not the label that summarises.** The pathfinder said
   "OK" while 1 of 249 cells was reachable — everything was a WARN. Reach told the truth.
6. **Findings are cast-dependent.** Dense swept the 7-artifact toy cast (r7); auto beat
   it on the real 23-artifact symmetry cast. Toy benchmarks do not transfer; re-test at
   the real scale before believing a policy.
7. **Story pays, measurably.** The same geometry scored 0.613 bare and 0.793 with its
   arc (threshold, prologue, overlook) under a rubric that also pays for tightness.
   Narrative operations are structure, not decoration.
8. **One composer, one memory.** Research runs through the same engine the wizard
   drives, so winners land in the recipe rail automatically. The research loop's real
   product is not the winning map — it is the growing law list in the canon, and every
   standing gate is regenerable from a recipe.

## The open problem: large artifacts (the placement frontier)

The day's deepest recurring discovery: **an artifact is not its bounding box.** It has
a *body* (stand near), a *reach* (beam, aim), an *aura* (viewing distance scales with
size — the gaze_ride law), a *growth envelope* (mold), and — the frontier — an
*enterability*. Current solutions are all containment-shaped: bigger rooms (chamber_big,
then hall_grand for the 8×8 science_screen). That escalation has a ceiling.

The suspected right answer: **at some size, the artifact stops being furniture and
becomes architecture.** A 10×5 pattern gallery should not stand *in* a corridor — it
should *be* the corridor's walls. An 8×8×8 screen is a room you enter, not a thing you
circle. `staging_dna.json` already classifies every artifact into 7 types (specimen /
instrument / performer / terrain / apparition / well / tableau) — and the composer
currently ignores type entirely, routing by size alone. **Type-routed placement** is the
proposed round 8: specimens get rooms, instruments get benches, terrain becomes floor,
tableaux become walls. That would answer the large-artifact question structurally
instead of with ever-bigger boxes.

Second-order upgrades queued behind it: aura as a metric (rooms currently grant
clearance, not viewing distance); kin-fill from artifact-md kin lists instead of coarse
registry categories.

## Where everything lives

- Canon (machine-read): `commons/data/composition_grammar.json` — ops, weights, bands,
  laws, rounds 1–7 history. The engines read it; editing it changes the search.
- Engine: `tools/wizard_compose.py` (gate modes + track mode; REACH/LIFT enforced).
- Track segments: `commons/data/wizard_track_templates.json` (role grammar shared with
  `template_patterns.json`; variable depth).
- Recipes (memory): `commons/data/wizard_recipes/` — every save and every round winner.
- Face: `/map-wizard` in the encyclopedia; Godot live preview via the map-sim bridge.
- Standing gate: `commons/maps/Thread_Gate` (v6, crescendo spiral, regenerable).
- First real-cast track: `commons/maps/Track_Symmetry` (13×164, sequence order intact).
