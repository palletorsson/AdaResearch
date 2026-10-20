# Fixed bottoms, gentler bars

The user asked for a smaller gutter, less amplified height, and a cube that grows upward as a bar while its bottom stays still, describing the change as artistic research in action. The clarification specifies **between cubes/bars**; the control-board button spacing stays unchanged. The exact request and clarification are preserved in [the feedback receipt](../../../course/randomness-research-2026-10-14/implementation/003/evidence/anchored-bars-feedback.json).

The current recipe uses the same 48 seed-42 values and RGB assignments. Four-centimetre-wide cells have 5.5-centimetre pitch, reducing the empty gutter from 6 cm to 1.5 cm. FLAT keeps four-centimetre cubes. BARS uses `h = 0.04 + 0.12 * mean(a,b,c)` metres: lengths range from 4 to 16 cm. The bottom remains at 8 cm above the tray; the centre is `0.08 + h/2`. Only the top rises. This reduces the old 30 cm value-driven excursion to 12 cm.

For invented black, white, red and green triples the bar lengths are 4, 16, 8 and 8 cm, and the centres are 10, 16, 12 and 12 cm. Equal means still hide channel order. These examples are hand calculations, not seed-42 draws.

The decision changes the apparatus in response to an encounter. It does not yet show that bars make the relation easier or more interesting to read. The next question is whether a shared bottom makes comparison useful, or whether the closer bars conceal one another. Compare FLAT and BARS within this recipe before changing another condition. Comparing old and new apparatus bundles spacing, amplitude and geometry; it cannot isolate their individual effects.

The new record schema is `ada.seed-bench.v2`, with `rgb-fixed.v2` and `rgb-mean-bar.v1`. Old v1 imports/replays retain their original floating centres, cube sizes and spacing. Choosing FLAT or BARS while viewing an old result explicitly forks into v2 with a parent ID; it keeps the values and RNG state, leaves the kept old copy intact and resets mapping history for the new recipe. The board identifies a legacy replay. New draws remain a separate seeded operation.

The complete [tutorial](tutorial.md) now prints the bar recipe, explains mesh size and centre placement, and retains legacy replay. The final passage's question about assigning a job to numbers remains open; this human-directed change supplies a concrete instance, without inventing a learning outcome. The current run receipts and scoped checks are linked in [experiment.json](experiment.json). Physical headset usability and independent reconstruction remain separate unfinished tests.
