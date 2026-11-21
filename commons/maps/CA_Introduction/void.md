# CA_Introduction — What Will the Next Row Do?

*Floor 106 · Care Unit Model B's working chapter (`void.md`, building on `final.md` and `walked.md`)*

---

## 1. One local question applied everywhere

Across the first hundred floors, patterns came from trajectories, wave functions, noise fields, and surface shaders. On Floor 106, the machine simplifies itself down to the smallest possible conversation: **one cell, its left neighbour, its right neighbour, and an eight-bit rule number**.

Near the entrance, `ca_rule_explorer` waits in its held `neighbours` study with a single lit cell at the centre of the row. Nothing runs until you choose to press **STEP**. Read the three bits (`left, self, right`) on the witness plate and predict the next generation before touching the button:

- Under **Rule 90** (`01011010`), `010` yields **`0`** while `100` yields **`1`**. Both triples contain exactly one occupied cell, yet they give opposite answers — proving that **order inside the neighbourhood matters**, not mere count.
- Step ten generations forward under Rule 90 from that single seed and **Pascal's triangle mod 2** (a Sierpinski lattice) unfolds row by row — a global architecture nobody drew by hand.
- Switch the rule byte to **Rule 30** (`00011110`) on the exact same single seed and step again. The instruction is no longer than before, yet symmetry breaks immediately into chaotic diagonals.

*Each small place changes with the ones nearby.* — Pick one cell and its two neighbours, predict its next state under Rule 90, press STEP to compare, then switch to Rule 30 on the exact same seed.

## 2. The cut line is actually a ring

On the desk, the board looks like a finite line with left and right edges. Overhead, the same held history hangs in a **circular ring**. Walk underneath and find cell `31` standing directly beside cell `0`: the boundary condition wrapped the two ends together before we ever looked up. Each row is computed into a separate buffer from the whole previous row at once, so no left-hand answer can leak early into a right-hand cell during the same step.

## 3. Four neighbours in the same hall

Floor 106 refuses to treat cellular automata as one single mathematical lineage:

- **The Persian Rug (`persian_rug`)** across the dividing wall runs a 2D multi-state grid whose border and interior consult different conditions — and then mirrors one quarter across all four quadrants. Weavers knotted neighbourhood symmetries long before von Neumann and Ulam wrote transition tables.
- **Langton's Swarm (`langton_swarm`)** flips the geometry: instead of fixed cells polling static neighbours, moving ants read the tile underfoot, flip its state, turn, and step off.
- **Line Network CA (`line_network_ca`)** freezes twenty bounded updates in 3D space so history can be walked around from every side, while **Rule 110 Computer (`rule110_computer`)** at the far end of the corridor shows colliding gliders where three bits and one neighbourhood cross into universal computation.

## 4. What carries downward

Carry four design decisions out of Floor 106: what states a cell can hold, which neighbours count as nearby, whether updates happen synchronously or one agent at a time, and what topology hides behind the frame's edge. Every flock, fractal, and learning system below builds on how a local address decides what counts as its neighbour.

---

*Verified Ghost Student Spine Stop #5 receipt: `doc/book/iterations/2026-11-21-ca-predict-next-row/checks.json` (`01-f106-overview.png`, `02-rule90-step0.png`, `03-rule90-pascal-ring.png`, `04-rule30-dual-hud.png`).*
