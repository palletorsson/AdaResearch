# Two accounts of one arrangement

The earlier shelf directed one retained value towards position, size, rotation and colour. Here we keep an entire population fixed and change its arrangement. We will build a small model that two measurements can read differently.

The room's route is ledger → jar → two compartments → displaced points → ruin → signal room. This tutorial reconstructs the two-compartment mechanism. The earlier [counts and neighbours build](counts-and-neighbours.md) remains a complete preparatory extension.

## First encounter

The table has sixteen labelled sites, eight in each compartment. Each site holds one orange A or blue B; eight of each exist throughout. RESET places all A on the left. The Shannon colour reading is one bit; the Boltzmann reading is zero.

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

**Supplied scaffolding:** the host draws the trays, spheres, labels and bars, connects controls, and saves/reopens records. It uses `commons/audio/rack_templates/RackTemplates.gd` and `commons/interactables/push_button.tscn` with their existing project dependencies. The preview supplies camera, light, floor and desktop buttons. These are declared dependencies, not additional student algorithms. The short file below owns the site state, exchange and both measurements.

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

[Trial, reconstruction and room evidence](../../../doc/book/iterations/2026-10-15-entropy-compartments/README.md) · [Research brief and next tasks](../../../doc/book/course/text-plans/Random_Entropy/research-brief.md)
