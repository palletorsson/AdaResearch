# What neighbours share

What makes neighbouring random heights belong together?

<!-- @perlin_noise_bridge -->

Look closely at neighbouring columns in the two small grids. On the WHITE NOISE side, compare one height with the next. On the PERLIN NOISE side, follow a group of heights across several cells. Describe the difference before calling either one a landscape.

Keep SEED fixed and adjust FREQUENCY. Watch how the scale of features changes on the coherent side. Then choose another seed or press RESAMPLE and repeat the comparison. The two kinds of field remain distinct even when their particular arrangements change.

Choose three adjacent columns on each side and describe their relative heights: rising, falling, or turning between the two. Move one position along and repeat. You are examining a local relationship rather than asking which grid contains the single tallest column. At a lower frequency, follow how far a broad feature extends on the coherent side; at a higher setting, repeat along the same row. If a small region happens to look similar on both sides, examine a longer stretch before declaring the procedures equivalent. Independent draws can produce a chance run of similar heights, while a coherent field can still contain differences between nearby samples.

Independent samples supply each white-noise height separately. Perlin noise supplies related values at nearby positions through a spatial construction. Those local relationships make broader features possible. The two grids use comparable height displays, but they do not draw from identical distributions merely because their values fit within similar bounds.

The seed makes each construction repeatable under the same settings. Frequency changes how rapidly the coherent field varies across the sampled positions. You are changing a rule about relationships in space, rather than choosing every column individually.

Look for something terrain-like in the independent grid, then for an unexpected edge in the coherent one. Perception is good at supplying landscapes. That skill can help you notice a structure, but it cannot establish that erosion, water or geological forces produced it. These are height fields with a colour mapping, not miniature geological histories.

<!-- @ -->

One productive misuse is to withhold the landscape reading and describe only local differences. A future shared scale or alternative palette could make that comparison easier. The next room uses random samples for estimation: their placement will matter because a numerical answer depends on how the sampling rule covers a region.
