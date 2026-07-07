# Sieve pass — catalyst activation verbs

_Recorded 2026-05-11T19:25:26_

**Target:** the ten catalyst-mode activation verbs as captured in `research_orb_activations.gd` and rendered on `/gesture-dna`. Each capture encodes a *design intent* for what that mode DOES on contact. The question this pass answers: do the chosen verbs hold under the sieve, and do they match what the production projectile actually does?

This pass combines two tasks: (1) the sieve applied to each verb, (2) a side-by-side with the live projectile script in `commons/hazards/becoming_catalyst/modes/<mode>_projectile.gd`. Where the two disagree, the recommendation is recorded.

---

## Verb-by-verb table

| Mode | Capture verb | Production behaviour (script header) | Match? | Recommended canonical |
|---|---|---|---|---|
| primitives | conversion (creature tints toward palette) | "glowing sphere that bounces off walls and slowly shrinks to nothing" — bounces between foes, transforming each | drift | **bounce-and-tint** (keep bounce, keep tint, drop "conversion" — that's the system verb, not this mode's) |
| chromatic | paint splash (mode-coloured spheres around impact) | "permanently colors grid cubes it hits, colors + transforms + fractal-spawns" | aligned (capture is thin) | **paint** (production is overloaded — see foreclosure below) |
| forces | push back (creature offset away from rest) | "calming field that slows, tames, focuses — force as care, not destruction but harnessing" | **inverted** | **gather** — force as care, drawing close, not pushing away |
| transformation | rotation (creature spun 30° around Y) | "purple sphere that shrinks targets on hit — metamorphosis, not destruction" | drift | **shrink** (rotation reads as kinetic, shrink reads as change-of-being) |
| waveform | oscillation (creature on sine arc) | "continuous double helix — two glowing trails spiral around forward axis. Wave-particle duality as identity — always oscillating, never fixed" | partial — orb-shape matches, creature-effect doesn't | **oscillate** (correct verb, but the effect needs to be shown on the *orb's path*, not on the creature) |
| chaos | randomisation (creature jittered + tilted) | "Tesla coil spark — branching electric arcs that crackle and fork. Unpredictable paths, random impulses, flickering lightning" | drift | **arc** (lightning verb — production is electric, not random-jitter) |
| fractal | split (smaller orb fragments) | "splits into 3 smaller copies, recursion depth 2 max → up to 9 sub-projectiles. One becomes many — self-similarity across scale" | **aligned** | **split** (keep) |
| cellular | grid spread (3×3 cube pattern around impact) | "slow cube with 3×3 CA grid that evolves as it travels" | **aligned** | **evolve** (sharper than spread — emphasises the CA, not the impact pattern) |
| branching | tendrils (thin cylinders extending outward) | "L-system seed that branches repeatedly. At terminal depth or on hit, grows a real DNA-based tree via TreeMorphology" | **aligned** | **grow** (tendrils captures the shape, grow captures the act) |
| swarm | multiply (six small orbs orbiting main) | "8 boid spheres that flock and independently seek nearby targets. Collective intelligence — the swarm hunts together" | partial | **flock** ("multiply" implies cloning; production is independent agents) |

Three strong alignments (fractal, cellular, branching). Three sharp mismatches (primitives, forces, transformation). Four drift-cases (chromatic, waveform, chaos, swarm) where the verb is in the right neighbourhood but the production has a more specific reading.

---

## 1. Does this thicken the cognitive water?

> What relational handles does the verb-grid add?

The verb-grid did something the per-mode docs alone couldn't: it surfaced that **the verbs don't share a frame**. Some are *what happens to the creature* (conversion, push back, rotation). Some are *what the orb does in flight* (split, oscillate). Some are *what appears in the world* (paint splash, grid spread, tendrils, swarm). The verbs as written sit at three different scopes.

That's a thickening — the question *which scope should the verb sit at?* is now askable. Without the capture-grid the verbs were ten independent paragraphs in ten files. With it they read as a chord, and the chord is partially dissonant.

The cleanest framing the table points toward: **verb = what the orb DOES as agent, observable from outside its target.** Under that constraint:
- bounce-and-tint, paint, gather, shrink, oscillate, arc, split, evolve, grow, flock.
- All ten land at the same scope. All ten name an *orb activity* the player can predict before contact.

That's a richer grammar than "what happens to the creature" because it makes the orb itself the verb-carrier, which matches the design rule that the orb is matter, not a UI trigger.

## 2. What is foreclosed?

> What does the verb collapse?

Each rename collapses what was visible in the previous wording. The collapses worth keeping vs. paying back:

- **forces: push → gather.** Push had a long muscle-memory of game-violence (grenade, knockback). Gather loses that legibility for first-time players who expect catalyst = weapon. *Foreclosure-as-feature* — same logic as the orb-gesture pass: the friction is the induction into "this is not a gun."
- **transformation: rotation → shrink.** Rotation read as motion; shrink reads as change-of-state. The cost: a frozen capture of "shrunken" looks ambiguous without comparison. The capture needs to show *before-and-after* in the same frame, or it lies about the production.
- **chromatic: paint splash → paint.** Loses the splash visual, gains alignment with how production permanently re-colours grid cubes (not a transient splash, a permanent paint). The capture currently shows the wrong duration.
- **swarm: multiply → flock.** Multiply suggests reproduction-from-one; flock suggests N-agents-from-the-start. Production is the latter. The capture's six-orb pattern is correct; only the verb-word is wrong.
- **The whole table now requires a re-capture pass.** Five of ten captures encode a verb the production doesn't do. Shipping these to gallery without correction would teach the wrong design intent.

Foreclosed by adopting the production-verbs as canonical: the freedom to write verbs as design-poetry independent of mechanics. The verb becomes a contract with the projectile script. That's a useful constraint — it means a verb-change is a code-change, and a code-change is a verb-change, in either direction.

## 3. What lives in the dark spot?

> What does the verb-table not encode?

Three things the verb-table can't reach but the system needs:

- **The relational asymmetry between modes.** *gather* and *grow* are gentle. *arc* and *split* are sharp. *evolve* and *oscillate* are temporal. Reading the verbs as a chord, some modes feel *like care* and some feel *like force*. The verb-table doesn't say which is which — and the question *which catalyst modes are care-modes and which are force-modes?* is one of the highest-value design questions in the project. The sieve refuses to answer it; it can only refuse the answer to be premature.
- **What the creature receives.** All ten verbs name the orb's act. The creature's experience of being-orb'd is the dark spot. *Gathered* by a catalyst is one inner experience; *shrunk* is another; *grown-into-a-tree* is the strangest of all. The verb-table doesn't address the creature's side, and probably shouldn't — that's where the catalyst's care-vs-violence ambiguity has to stay opaque, per the orb-gesture-detector sieve pass.
- **The verb-mode-mode interactions.** What does *grow* do when the agent is already *shrunken*? What does *paint* do to a *flocked* swarm? The verb-table is single-mode; the game is multi-mode. The interactions are the habitat of the dark spot — the place experience exceeds the encoding.

**Generative — fragile.** The verb-table stays habitat if and only if we don't legibilise the asymmetry too soon. No "care vs force" label on the bracelet. No "this mode is gentle" tooltip. The chord stays a chord; the player learns which modes are which by holding them.

---

## Recorded design rules

1. **Verb scope: orb-activity, not creature-effect.** All ten verbs name what the orb DOES as agent, not what the creature undergoes.
2. **Verb ↔ projectile script is a contract.** Changing a verb in `manifest.json` requires reading `<mode>_projectile.gd` and confirming alignment. Drift between them is a bug, not a feature.
3. **No verb labels the orb's *valence*.** Care vs force, gentle vs sharp, slow vs fast — these stay implicit. The chord is read, not declared.
4. **Re-capture five modes.** primitives → bounce-and-tint. forces → gather. transformation → shrink. chaos → arc. swarm → flock. Update both `research_orb_activations.gd` decoration and `manifest.json` capture-table.

---

## Pass result

The verb-table passes the sieve **under correction**. Three modes are aligned, two are partially aligned, five drift or invert. The recommended canonical verbs sit at one scope (orb-activity) and align with production scripts. The path forward is a re-capture, not a discard — the structure is right, the words are partially wrong.

Next action: a second pass on `research_orb_activations.gd` with the corrected verbs, then a manifest update with the canonical list. The corrected list also opens the question *should the production scripts borrow their verbs from this table?* — a possible direction for the next sieve pass once both sides have settled.

---

## Closure — 2026-05-11T21:35

The re-capture landed. `research_orb_activations.gd` now spawns:
- `_spawn_bounce_trail` + `_spawn_tint_halo` for primitives (bounce-and-tint)
- `_spawn_gather_halo` + cardinal inward arrows for forces (gather — force as care)
- `_spawn_ghost_outline` beside a 0.5× creature for transformation (shrink)
- `_spawn_lightning_arc` with sideways bow + two forks for chaos (arc)
- `_spawn_flock` with 8 boids on independent headings for swarm (flock)

The five corrected captures sit on `/gesture-dna` under the `activations` pill. Forces, transformation, chaos, and swarm read cleanly. Primitives reads partially — the trail spheres are visible only when rendered with `no_depth_test = true` to defeat hand/orb occlusion from the FPV camera; a wider camera angle would carry the bounce verb more crisply but would break the FPV constraint. Filed as known sieve-pass-2 candidate.

Manifest `catalyst_activations.behavior` updated to use the canonical verbs and dropped the drift-apology pointer (drift is resolved).

The opened question — *should the production scripts borrow their verbs from this table?* — remains live. Most production headers already use poetic prose ("Wave-particle duality as identity," "One becomes many — self-similarity across scale"). Standardising a single-line `verb: X` on line 2 of each `<mode>_projectile.gd` would let tools scrape the verb without parsing prose; whether the production scripts should be edited to match is a follow-up.
