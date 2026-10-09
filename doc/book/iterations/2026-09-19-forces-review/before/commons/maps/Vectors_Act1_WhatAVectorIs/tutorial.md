# One displacement, two wall projections

The opt-in `lesson:room_reading` layer on VectorBasics starts with its input arrow and hides the legacy decomposition displays. A floor console offers SHORT, LONG, SHIFT, ZERO and PARTS. The input arrow is brought forward above the console. The projection screen occupies a cleared side bay; former interior grid columns in that footprint have been removed.

Both projections read `end.global_position - start.global_position`. SHORT selects magnitude 0.25 m and LONG selects 1 m, retaining direction when nonzero. Their fallback at zero is normalised (1,1,1). SHIFT alternates a common 0.2 m translation of both pins along the console axis. ZERO makes them coincide. PARTS reveals world components and two component-leg drawings. This is a description of displacement, not a force controller.

The wall's XY and XZ diagrams use 0.85 display metres per world metre. Each projection is limited to radius 1.05 display metres. The clipping label names that bound; the numeric displacement is unchanged. The adapter samples at 20 Hz and rebuilds only after a measured vector or reveal-state change. Body, world and drawing coordinates are kept explicit. Existing VectorBasics placements without the lesson metadata retain their interface.

The companion vector_normalize_demo uses a 0.001 magnitude threshold. Its unit-vector numeric readout now uses the computed unit.length(), so zero returns 0.000 instead of the previous hard-coded 1.000. Its drawn unit sphere belongs to the illustration's scale, not the world-metre scale of the first wall.

Before expanding this into bodily locomotion, introduce velocity state, acceleration and integration. The existing force_pad assigns launch velocity; force_field_zone adjusts velocity over time. They require distinct adapters and distinct comparisons.
