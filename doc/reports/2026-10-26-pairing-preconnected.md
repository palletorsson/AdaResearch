# Point Lines / partly connected PairingPoints

The existing twelve-point field starts with three native connections: Point00–Point01, Point04–Point08 and Point06–Point11. Their differing direction and length give an immediate example of a line; six points remain loose for the player. All endpoints keep their existing pickup and pairing behavior. The separate MeasurementRoom entrance remains unsolved.

`pairing_field.gd` has an optional `initial_pairs` array. Its default is empty, preserving other uses. Only the Point Lines setting-out assembly supplies the three initial pairs. Seeding updates both the manager's graph and the endpoints' reciprocal connection state. Initial lines live under the editable PairingPoints member so its real editor export includes them. No saved room placements or player arrangements were rewritten.

`tools/probes/pairing_preconnected.gd` checks the real saved floor, three graph edges, six free endpoints, reciprocal state, real line meshes, a closed separate gate, actual desktop pickup of a connected endpoint and actual pickup/release joining a loose pair. Eleven checks pass. The focused run excludes adjacent asynchronous content; it is not physical-headset acceptance. The earlier museum regression was adjusted to test a loose pair and expect three starting connections plus the player's new fourth connection.

Native screenshot and receipt: `doc/ports/2026-10-26-pairing-preconnected/`. Floor 3 models are incrementally re-exported; all other floor model receipts and saved layouts are preserved.
