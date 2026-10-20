# Two accounts of one arrangement

Entropy Types has established that each reading needs a named question. Here we keep an entire population fixed and change its arrangement, then investigate differences the readings omit. We will build a small model that two measurements can read differently.

The room's route is ledger → jar → two compartments → displaced points → ruin → signal room. This tutorial reconstructs the two-compartment mechanism. The earlier [counts and neighbours build](counts-and-neighbours.md) remains a complete preparatory extension.

## First encounter

The instrument has two glass-sided trays beneath round Shannon and Boltzmann dials. Sixteen labelled sites hold one orange A or blue B each, eight sites in each compartment; eight of each colour exist throughout. RESET places all A on the left. The Shannon colour reading is one bit; the Boltzmann reading is zero. The scales have different units: the left measures bits per colour observation; the right shows S_B/k_B. Its pointer and bar follow the same computed value.

Press **A LEFT −** four times, watching one exchange at a time. Each tray now holds four A and four B. The colour shares have not changed, but the right-hand reading has. Press **SAME k**. The arrangement changes again while both readings stay.

A reading that stays still is evidence. It invites a precise question: what differences was this instrument built to retain?

## The two questions

**Shannon colour entropy** counts A and B over the whole board. Their shares are both 1/2, so H = −Σ p log₂p = 1 bit per colour observation. Think of selecting a site uniformly without being told its address. Knowing an address would change the question. This is a statistic of a retained board, not proof of an unpredictable source.

**Boltzmann configurational entropy** starts with a macrostate: k, the number of A on the left. A microstate here is a complete sixteen-site A/B list; same-colour occupants are not separately identified. How many such lists agree with k?

There are C(8,k) ways to choose the left A sites and C(8,8−k) for the right. Multiplying gives Ω. The function C(n,k), “n choose k,” counts subsets of k sites without counting their order. At k = 4, Ω = 70 × 70 = 4,900.

The physical expression is S_B = k_B ln Ω. Our screen displays **S_B/k_B**, the dimensionless natural logarithm of that count. It does not display joules per kelvin, temperature or heat. This fixed-occupancy configuration model has no thermal dynamics.

| A on left, k | Whole-board H, bits | Ω | S_B/k_B |
|---:|---:|---:|---:|
| 8 | 1 | 1 | 0 |
| 7 | 1 | 64 | 4.159 |
| 4 | 1 | 4,900 | 8.497 |
| 3 | 1 | 3,136 | 8.051 |
| 0 | 1 | 1 | 0 |

The readings concern different variables and state spaces. Shannon entropy over a *uniform distribution of those Ω compatible microstates*, converted from bits to natural-log units and multiplied by k_B, would agree with the Boltzmann value. The comparison does not establish competing definitions of the same measured variable.

## Build the small mechanism

This lesson uses Ada's existing Godot project. Copy the four files in `commons/artifacts/entropy_compartments/` into a fresh folder, for example `student_work/two_accounts/`. Copy only `compartment_model.gd`, `entropy_compartments.gd`, `entropy_compartments.tscn` and `preview.tscn`; ignore generated UID files.

Replace the copied `compartment_model.gd` with the complete listing below. The copied scene and host use relative references, so they load this new file. Open the copied `preview.tscn` and run that scene with F6. Its desktop buttons and the room's rectangular controls call the same methods.

**Supplied scaffolding:** the host draws the cabinet, specimen trays, spheres, labels, dial pointers and bars, connects controls, and saves/reopens records. It uses `commons/audio/rack_templates/RackTemplates.gd` and `commons/interactables/push_button.tscn` with their existing project dependencies. The preview supplies camera, light, floor and desktop buttons. These are declared dependencies, not additional student algorithms. The short file below owns the site state, exchange and both measurements.

<!-- student-code:compartment_model.gd -->

```gdscript
extends RefCounted
## Sixteen labelled sites, eight A (1) and eight B (0). No thermal dynamics.
var sites: Array[int] = [1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0]

func exchange(i: int, j: int) -> void:
	var held := sites[i]
	sites[i] = sites[j]
	sites[j] = held

func a_left() -> int:
	return sites.slice(0, 8).count(1)

func shannon_colour() -> float:
	var p := sites.count(1) / 16.0
	var h := 0.0
	for share in [p, 1.0 - p]:
		if share > 0.0: h -= share * log(share) / log(2.0)
	return h

func choose(n: int, k: int) -> int:
	var ways := 1
	for i in range(1, k + 1):
		ways = ways * (n - i + 1) / i
	return ways

func multiplicity() -> int:
	var k := a_left()
	return choose(8, k) * choose(8, 8 - k)

func boltzmann_over_kb() -> float:
	return log(float(multiplicity()))
```

Read `exchange` first. It holds one value temporarily so neither occupant disappears. Its indices must be valid site addresses, 0–15. The host's controls supply them. The first eight addresses are the left compartment; the rest are the right.

`shannon_colour` measures relative frequency. The zero check avoids taking log(0). `choose` builds the binomial count using integer arithmetic; for this small board its intermediate values are exact. Every exchange preserves eight A and eight B. Changing that inventory would require revising `multiplicity`, the labels and the saved-model version together.

## Run, preserve, replay, reconstruct

1. **Baseline:** RESET. Record seed 435, sixteen sites, eight A, eight B, k = 8, H = 1 and Ω = 1. The seed controls requested swap pairs; it is not used to decide the deliberately separated baseline.
2. **One change:** press A LEFT − four times. Keep the inventory, partition and measurement definitions fixed. Expect k = 4 and Ω = 4,900. Manual exchanges consume no random draws.
3. **Observe:** compare that state with SAME k. Note both the visible difference and the unchanged readings. At complete separation SAME k has no visible effect; that is a useful null result.
4. **Preserve:** KEEP stops motion and writes a uniquely named JSON file in Godot's user-data folder. The Output panel prints its full path. It contains all retained site lists, actions, seed, generator states, cursor, engine/model versions and event interval. In the Inspector, set the host's `observation` and `next_change` fields before KEEP; on a running preview use the Remote Inspector. There is no in-world notes keyboard.
5. **Replay:** RESET, then REPLAY. It opens the latest saved record and restores its states in order without drawing again. KEEP also updates a small latest-record pointer. Older files remain available; the current button opens only the latest. Replay preserves the event order at the recorded interval, not the wall-clock timing of manual presses.
6. **Reconstruct:** repeat in the fresh copied folder using only the declared files and printed model. Compare all sixteen final site values with the kept record, not just the gauges. A fresh apparatus can load an older record through its `restore(record)` method; REPLAY uses the latest pointer shared by these scenes.
7. **Revise:** propose one next change and its reason. For example, count unlike neighbouring pairs beside these two readings. Define which sites are neighbours before coding. A new number earns its place only if it answers the observed omission.

**ONE SWAP** chooses two distinct sites with a local seeded generator; swapping equal colours records an event without a visible change. **RUN / PAUSE** repeats these requests. A LEFT + moves back towards the separated baseline. Editing during replay makes a new continuation from its current state. Records stop at 1,024 events; KEEP and RESET begin another trial. RESET does not delete a kept file.

Replaying saved outcomes differs from generating new unpredictability. Resetting seed 435 and repeating the same requests reproduces this implementation's swaps. Saving actual states also avoids relying on a future engine version to reproduce its generator algorithm.

## What happened in the implementation trial

Native scripted tests swept k from 8 to 0, compared arrangements within k = 4, saved/reopened a trial and repeated 64 swaps from seed 435. H stayed one bit; Ω reached 4,900 and fell again. SAME k changed the arrangement without changing either measurement. Exhaustive enumeration independently recovered all 12,870 configurations and their nine multiplicities.

These are apparatus observations. They do not tell us whether a learner finds the comparison useful. Keep confusion, assistance, a null result or a reason to abandon a proposed measure in the research record. The 48-value seed bench remains the **first research pilot**; this is the next entropy apparatus.

The jar asks a related question using colour *given one of six height bands*: H(C|Y). Its corrected labels now state that partition and a 0–1 bit range. Changing the bands, adding radial shells, conditional prediction and a thermal model are further work, not hidden capabilities of this bench.

## Optional encounter: what comes apart, and what can join?

The prefab comparison near the entrance has one STAGE slider and two copies of the same inventory: a cardboard box, CRT monitor, lab stool and microscope. At **0**, both tables hold the original objects. At **0.5**, the left objects have scattered intact while the right table's fifty mesh parts have separated. At **1**, the left objects are home again; the right parts form four hybrids. The seed now determines which parts join, their joining order and their orientation. SEED +1 produces another set of forms on the same four pads. Each hybrid combines at least three source objects; its label names the donors. Mesh boundaries are modelling decisions, not atoms or physically simulated joints.

Start with seed 435 and move slowly from 0 through 0.5 to 1, then back. At 1, hold the viewpoint and stage fixed and use SEED +1 to compare new hybrids. At what point does an old object become difficult to recognise, and when does another form begin to hold together? KEEP several interesting arrangements, then open GALLERY. Four saved sets appear side by side, each labelled with its seed and slider stage; PREVIOUS/NEXT reveal more entries. Each set contains all four forms. Select its REPLAY number to restore it at full size, or BACK to return without changing the live experiment. The collection persists after reopening. Also keep an intermediate setting and compare it with a completed hybrid. The record retains the slider, raw draws, source signature, each part's hybrid membership and target transform. Earlier separation-only records still open: their old full displacement is now the midpoint. The Output path identifies each JSON to preserve; the gallery index links the collection.

For reconstruction, `disorder_sample.gd` supplies retained separation transforms; `seeded_grafts.gd` supplies seeded assemblies from fifteen small bundles, retaining details such as the screen and bezel. It shuffles memberships, joining order, attachment faces and quarter turns using a separate local random generator. `hybrid_recipe.gd` retains the transform codec and earlier fixed recipes for compatibility. Up to the midpoint, separation strength is twice the slider value. After the midpoint, each right-hand part interpolates from its separated pose to its saved hybrid pose. The left returns intact. Both branches calculate from stored endpoints, so reversing the slider retraces them. Completed hybrids are uniformly fitted to their pads; materials remain the originals. The [source guide and native receipt](../../../doc/book/iterations/2026-10-16-seeded-hybrids/README.md) list the host and dependencies; this optional reconstruction uses those supplied modules.

The joining rules and bundle boundaries are authored; the seed now varies which hybrids those rules produce. Compare two saved seeds at stage 1 in GALLERY and follow a part that changes roles. Does its new relation suggest a different use? Replay each at full size to check that impression; the gallery miniatures use a uniform display fit. A later revision can change one joining rule while preserving the separation record. Earlier fixed-hybrid saves still restore their original targets and labels. This slider is a reversible geometric path, not an entropy quantity or a demonstration of spontaneous self-assembly. An entropy claim would require a declared random variable or macrostate and a measure. Human recognition and independent reconstruction still need a trial. The [gallery guide and native receipt](../../../doc/book/iterations/2026-10-16-hybrid-gallery/README.md) add persistence, selection and exact replay to this loop.

### Follow one part before judging the whole

Use **FOLLOW PART** to mark the CRT screen on both tables. The gold frame and name are removable annotations; the screen retains its original material. This cue identifies a mesh across transformations. It does not establish that a new hybrid functions as a monitor.

1. **Baseline:** ORIGINAL, seed 435. Find the screen in each copy. Record the stage and seed before moving anything.
2. **Compare:** PARTS, stage 0.5. Leave the slider still and look left, then right. On the left, the screen remains in its assembled monitor. On the right, the parts have separated. Changing the gaze is not another experimental condition. If a screen is hidden behind another part, record that obstruction before moving the viewpoint.
3. **Follow:** move slowly from 0.5 to 1 while following the right-hand screen. Stop wherever its relationship becomes hard to recognise. The marker's hybrid letter identifies its target group; during the transition it does not mean the joining is complete. Reverse the slider to test whether the same path returns.
4. **Keep and replay:** KEEP an intermediate arrangement, record why it is worth returning to, then use ORIGINAL and SEED +1 before REPLAY. Check the screen, neighbouring parts, stage and seed. The saved arrangement should return. **SAVE BOTH VIEWS** in the desktop preview separately preserves the current head and outside-camera images, poses and full artifact state. A screenshot alone does not restore the apparatus.
5. **Reconstruct and revise:** rebuild with the declared modules above and load the saved JSON through `restore(record)`. Compare its part transforms with the record. Then change one bundle or joining rule in a versioned copy. Does the screen retain a role, acquire another one, or become unhelpfully obscured? Preserve that observation, including a null result, beside the parent record.

WATCH rehearses this procedure with two hands. It looks between the tables at the same midpoint, follows the screen through a slower six-second joining movement, tries another seed, keeps an intermediate form and replays it. Its [eye/outside review](../../../doc/book/iterations/2026-10-16-ghost-prefab-playtest/index.html) retains the captured states and questions. Looking at the apparatus from its head revealed that successful input alone did not show whether the comparison was visible; the pauses, identity cue and standing position were revised accordingly.

Short tutorial and final excerpts, with an authored rehearsal question, float above the ghost's head. These cues expose the proposed reading of the encounter; they are not reports of a learner's thoughts or understanding. The outside view shows them; the eye camera omits the annotation layer so they do not cover the work. Each captured pair retains their source and checksum. The final's question—what an account makes available and leaves aside—can motivate a change to the apparatus without adding this optional stop to the chapter's six-stop route.

Watching from the front for six seconds starts WATCH once, until a visitor uses a control. Touching a control takes over immediately. WATCH during rehearsal stops and restores the starting arrangement; the ghost's collection is separate. On successful completion in Random_Entropy, it restores the prefab baseline and walks on clear floor to the **Shannon ledger**, the main route's first artifact. A missing or obstructed route stops visibly. This pilot arrives with the next question; a ledger-specific control rehearsal remains to build. In the standalone preview there is no next artifact. This rehearses supplied apparatus and checks visibility; it does not replace independent tutorial reconstruction or a human trial. The 48-value bench remains the first research pilot.

[Trial, reconstruction and room evidence](../../../doc/book/iterations/2026-10-15-entropy-compartments/README.md) · [Research brief and next tasks](../../../doc/book/course/text-plans/Random_Entropy/research-brief.md)

## The prepared jar bridge

At (3,2), `entropy_jar_states` places four frozen specimens: layers, overlapping interface, mixed, core/shell. They reuse the shakeable jar's placement generator at seed 435 and preserve forty red and forty blue beads. The original interactive jar remains at (3,5).

Read each retained position twice: once in six height bands and once in two radial regions, split at 60% of the usable radius. Within each region, calculate colour entropy and weight it by its share of all eighty beads. The core/shell example leaves uncertainty under height but none under core/rim. These are prepared configurations, not successive frames of a physical mixing simulation. The two partitions differ in both shape and number of regions; this compares two specific observations, not a controlled estimate of the effect of orientation alone.

Reconstruct from `jar_snapshot.gd` and the source `entropy_jar.gd`, recording seed 435, found state, jar dimensions and partition definitions. Its `positions()` exposes the frozen coordinate list for an exact record. Change only the partition while preserving those coordinates. No visitor save/replay interface is added to the bank. The live jar is a separate shake/reset experiment; the prefab bench retains its own KEEP, gallery and replay.

The [two-hall curation](relationship.md) keeps definitions here brief and treats the compartments as an active extension of the chair comparison. The first 48-value bench remains the first research pilot.
