# What holds the floor?

14 September 2026. A source and history audit before procedural generation.

`0` means no grid structure. `1` supplies the ordinary floor. Numeric higher values describe stacks in the grid, but the museum uses `wall_height` (default 2) to decide whether they become walls or raised decks. `w` is an explicit wall. A generated object does not automatically replace missing support.

Both portable plans had 56 zero cells where the current maps specify floor, plus seven stale wall cells: 63 tile corrections per plan. Only tile and interior_count changed. Every source map, artifact placement, role and route is preserved. Map-authored Godot halls normally reread source maps at build time, so these cache repairs are not evidence that 56 actual runtime holes were filled.

The six active maps retain 131 source zeros. Every one matches a zero in the July grid after accounting for the later perimeter offset. Those gaps need a bodily review before acceptance. Three old teleporter zeros survive at Caves (13,9), Sculpted Forms (11,11), and Mirrored Patterns (10,8); the museum manages its own transport, so the old utility is not itself a reason to leave a hole. Specific covers can use museum.floor_cells while preserving grid data.

Space Colonization has 43 additional source zeros and remains in the sequence/book, but is absent from map_authored and both active plans. Record and resolve that route discrepancy separately.

Genetic Evolution now has no source zeros; its 25 numeric height-3 cells still become full walls under the default threshold. Review those platforms and wedges, fit the population footprint and expose the actual scoring operation. The actual code scores geometric targets, not locomotion in the physical arena described by the earlier tutorial.

Before each hall: name the support owner; stage museum circulation and generated space separately; inspect source, placement, scale and collider; test entrance, controls, edges and onward route; then write the book. Preserve an intentional void with an explicit reason and a tested route. Runtime collision and headset tests have not been performed by this audit.
