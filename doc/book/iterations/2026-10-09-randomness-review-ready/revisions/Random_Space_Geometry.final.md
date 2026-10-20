# What neighbours share

What makes neighbouring random heights belong together?

<!-- @perlin_noise_bridge -->

Through the connecting passage, the comparison bench stands among the shapes in the second room. Look closely at neighbouring columns in the two small grids. On the WHITE NOISE side, compare one height with the next. On the PERLIN NOISE side, follow a group of heights across several cells. Describe the difference before calling either one a landscape.

Keep SEED fixed and adjust FREQUENCY. Watch how the scale of features changes on the coherent side. Watch the WHITE NOISE side as you do: not one of its columns moves. With the seed and draw order kept, every redraw returns the same independent values. The frequency control belongs to the other construction: it changes where the grid samples the field. OCTAVES, beside it, lays finer layers of Perlin noise over the broad shape; the white side ignores that slider too. Then choose another seed or press RESAMPLE and repeat the comparison. The two kinds of field remain distinct even when their particular arrangements change.

Choose three neighbouring columns: rising, falling, or turning between the two? Move one place along and repeat. A chance run of similar heights can occur on the independent side too. Follow a longer stretch before letting a resemblance stand for the same procedure.

Independent samples supply each white-noise height separately. Perlin noise supplies related values at nearby positions through a spatial construction.[^perlin] Those local relationships make broader features possible. The two grids use comparable height displays, but they do not draw from identical distributions merely because their values fit within similar bounds.

You are changing a rule about relationships in space. The columns need not each be chosen by hand.

Look for something terrain-like in the independent grid, then for an unexpected edge in the coherent one. Perception is good at supplying landscapes, and this work prompts one: its subtitle reads “From chaos to terrain”, and both grids are painted on one ramp that runs from blue through green to white, like water, grass and snow. That skill can help you notice a structure, but it cannot establish that erosion, water or geological forces produced it. These are height fields with a colour mapping, not miniature geological histories.

<!-- @ -->

At the tutorial table, the columns keep one grey material. You retain the independent heights while changing the field. A number names the average gap between neighbours, but a row is still worth following with your eye. Two arrangements can contain the same numbers and ask you to cross very different surfaces.

One productive discipline is to keep withholding the landscape reading, despite the subtitle and the palette, and describe only local differences. On the installed bench, both grids share one height scale and one colour ramp, so differences in local spread can be read directly; the panel offers no other palette, so setting the landscape aside is left to you. Now look at the shapes scattered around the hall: each one's position was drawn on its own, uniformly inside a box, and the links between them join pairs picked at random, near or far; distance decides only what kind of link is drawn. In the next room, the dartboard uses random samples for estimation: where they land will matter, because its numerical answer depends on how the sampling rule covers the square. Each of its darts, from THROW, from AUTO or already on the board when you arrive, is placed by the same kind of draw as those shapes and the WHITE NOISE heights, uniform and with no neighbour consulted: do such draws cover a square evenly, or do they leave clumps and gaps?

[^perlin]: The bench uses Godot's FastNoiseLite Perlin mode with layered fractal noise. The tutorial uses the same mode with one layer. Perlin noise relates values through a lattice of gradients; this names a construction, not a claim that the present library reproduces the original implementation exactly. See [Godot: FastNoiseLite](https://docs.godotengine.org/en/stable/classes/class_fastnoiselite.html). The mixer in Random Space is a sum of sines and is identified there as such.
