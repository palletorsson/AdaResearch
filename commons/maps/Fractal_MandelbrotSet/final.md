Five characters index every Julia world at once, and the edge of that index is where the interesting ones live.

The last hall gave you one dial and one picture. Turn the dial and you get a different picture; turn it far enough and the picture stops being connected and falls into dust. That raises an obvious question, and this hall is the answer to it: for which values of c does the set hold together?

```gdscript
z = z * z + c
```

The same five characters, asked a different question. In the last hall c was fixed and you swept the starting points. Here the starting point is always zero and you sweep c, and you mark every c whose orbit stays bounded. What you get is not another fractal in the family. It is the catalogue of the family.

## The catalogue overhead

<!-- @mandelbrot_set -->

Ten thousand cubes in a field nine and a half metres square, hanging about four metres up, which is wider than the floor it hangs over and higher than anything you can climb. Each cube is one value of c, coloured by how long that c took to escape, and the black region in the middle is the set itself: every c whose Julia set is connected.

You are standing under a map, and each pixel of the map is an entire world from the previous hall. Look up long enough and the shape resolves: a cardioid with a disc stuck to it, and smaller discs on that, and filaments running out. The filaments are where the two behaviours meet, and every one of them is a place where a hair's difference in c is the difference between a connected Julia set and a cloud of dust.

Do not jump while you are looking at it. The jump key is bound to the same action that resets the field's zoom, so the whole thing re-rolls over your head.

<!-- @mandelbrot_dive -->

The instrument, on a table that floats a little off the floor: the same computation as a shader, live, with two sliders and four buttons. Zoom in anywhere on the boundary and there is more boundary, at every magnification, forever, and small complete copies of the whole shape appear inside the filaments, each one slightly distorted and unmistakably the same object.

There is a catch worth knowing before you use it. The pan controls answer to the same keys as walking, so on a desktop, crossing the room drags the fractal along with you. The instrument and the visitor are wired to the same hands.

<!-- @dark_sphere -->

A dark sphere pulsing on the floor at knee height, seventy centimetres across. In a room whose subject has no scale at all, it is useful to have one object whose size you can state.

<!-- @ -->

## The honest cap

Every picture here is a lie about depth, and the lie is measurable. The field overhead runs its test a hundred times per point and then gives up; anything still bounded after a hundred steps is painted black and called a member. Some of those points are not members. They would have escaped on the hundred and first step, or the thousandth.

So the black region you are looking at is slightly too big, and it is too big in a way that depends entirely on a number somebody chose. Zoom the table in far enough and the boundary goes soft and blocky, not because the object ran out of detail but because the arithmetic ran out of digits. The object has infinite detail. Every image of it has a budget.

That is the chapter's last honesty, and it belongs here rather than in the halls before it. Recursion had a base case that stopped it. The Koch curve had a line thickness that hid it. Julia had a zoom that breathed. And the atlas of all Julia sets has an iteration cap, which is the same admission in its final form: the rule is infinite and every look at it is finite.

Next: what these rules make when they are set to grow rather than to draw.
