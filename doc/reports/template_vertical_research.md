# Template vertical research — was the search blocked from height?

**Premise (from rounds 1-2):** terraced genomes are systematically penalized by the
in-loop reachability check, so evolution never explores height honestly.

**The premise was FALSE — and the data killed it cleanly.**

## What the survey actually found (400 genomes, 5 seeds, gid held fixed)

| population | pass rate |
|---|---|
| flat genomes | 224/224 |
| terraced genomes | 174/176 |

Terraced rooms are NOT systematically killed: 99% score honestly. The two failures
were **wall-sealed pockets** — same-height cells closed off by route/hull wall
edges, not by cliffs. A real (rare) generator bug, nothing to do with verticality.

## The repair operator (kept — it fixes the real bug)

`template_vertical_repair.repair(data)`: flood from spawn; for each unreached
component, bridge its lowest-|dh| boundary — dh=0 carve a DOOR (uppercase the wall
code), dh=1 place a wp wedge, dh>=2 carve an intermediate step + wedge.
Result on the sealed rooms: **2/2 fixed, by doors alone** (2 doors each).

## And the champions were already terraced

Re-running the migration evolution with repair active reproduced round 2's results
exactly (60.53 / 60.1 / 53.38 — repair almost never fires, so the RNG stream is
identical), which exposed the overlooked fact: **all three migration champions were
already step_down basilicas — 3 height levels, 6 wedges.** Verticality doesn't need
rescuing; it already wins. TemplateLab_MIG_GEN *is* the terraced champion.

## Side-finding: the gid quirk

`compile_gallery`'s route-wall RNG seeds on `len(gid)` — the same genome compiles to
(potentially) different rooms under different gid lengths. Harness rule going
forward: score and write with the SAME gid, or fitness describes a different room
than the map on disk. (Handoff note for gallery_evolve: seed on the genome, not the id.)

## Method lesson

Check the premise against the champion before building the fix. The repair operator
was built for a bias that didn't exist — it earned its keep anyway on the smaller,
real bug it uncovered (wall-sealed pockets, ~1% of terraced rooms).

Walk the terraced champion: /map-viewer?map=TemplateLab_MIG_GEN
