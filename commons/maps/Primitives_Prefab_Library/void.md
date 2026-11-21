# Primitives_Prefab_Library — Take a Part Forward

*Floor 209 · Care Unit Model B's working chapter (`void.md`, final stop of the Ghost Student Spine)*

---

## 1. An open workshop, not a vitrine

Floor 209 closes the Ghost Student Spine by turning the tower's archive back into working stock. Along the north and south edges stand **eight open `prefab_library_shelf` cabinets** (`PREFABS / 01` through `PREFABS / 06`, plus `TOOLS / 01` and `TOOLS / 02`). Unlike a vending vitrine behind glass, the front pane is intentionally hidden: every miniature on the shelves shares the live `items.json` inventory and answers direct pickup.

Across the central slab stand **five full-size `prefab_library_hanging_stock` rails** grouped by material grammar:

- **FRAMING AND MEASURE:** `point`, `rod`, `brace`, `plank`, `plank2`, `dangerx`, `triangle`, `woodenboard`, `measuringstick`, `hinge`, `wheel`, `test`
- **PROFILES AND CYLINDERS:** `wedge`, `pyramid`, `cone`, `cylinder`, `extinguisher`, `oildrum`, `tincan`, `bowlingpin`, `marble`, `marblechute`
- **BLOCKS AND BODIES:** `woodenblock`, `dominotile`, `cinderblock`, `skateboard`, `eupallet`, `brick`, `woodenbox`, `walkramp`, `rubberball`
- **TOOLS AND FIXTURES:** `clock`, `tape`, `danger`, `health`, `rubber`, `pin`, `trace_bead`, `trace_pen`, `spray_paint`
- **OVERSIZE:** `canvas`, `box3`, `concrete4`, `techcrate`

## 2. Two verbs of taking: parts detach, tools stay anchored

Pick a reusable structural part such as `rod` off the **FRAMING AND MEASURE** rail. Two things happen simultaneously: it detaches from the rail into live physics so you can lay it onto the slab under gravity or pin it in place, and it registers directly into your inventory hands (`collect(id)`) so you can summon it again anywhere in the tower.

Now grab a fixture tool such as `tape` or `trace_pen` off **TOOLS AND FIXTURES**. It equips into your bracelet and immediately returns its physical proxy to its stand, leaving the workshop station intact for the next ghost who arrives.

## 3. From one part to two testable arrangements

On the east side of the floor stands **`construction-stock`** — the full Tier-3 **`scaffold_workstation_quads`** (`prefabs_enabled = true`). Take one reusable primitive (for example a `rod` or `hinge`, or a 2 m square quad), sketch two distinct arrangements that use that exact same part, and state what observable difference another visitor can test:

- Does adding a diagonal `brace` change whether a frame holds square under load?
- Does pinning one end (`pin`) while leaving the other loose under gravity (`items.json` sand-block rule) turn a static plank into a lever or bridge?

*What we have made can start something again.* — Pick a reusable part from the open shelves or full-size stock rails, test it at the Scaffold Workstation, and carry it forward through a transfer threshold into another floor.

## 4. Thresholds back into the tower

Floor 209 is not a dead end at the bottom of the spine. Two labelled **`void_floor_transfer`** thresholds stand directly on the slab: **`CONTINUE TO TRANSFORMATION`** (`Trans_Pre`, Floor 13) and **`BACK TO MELENCOLIA`** (`Primitives_Melencolia`). Pressing `TransferKey` moves Model B — and every collected primitive in hand — straight back into the working tower so the loop begins again with an arrangement another ghost can discover and test.

---

*Verified Ghost Student Spine Stop #10 receipt: `doc/book/iterations/2026-11-21-prefab-library-take-forward/checks.json` (`01-f209-workshop-overview.png`, `02-hanging-stock-framing.png`, `03-scaffold-workstation.png`, `04-transfer-threshold-dual-hud.png`).*
