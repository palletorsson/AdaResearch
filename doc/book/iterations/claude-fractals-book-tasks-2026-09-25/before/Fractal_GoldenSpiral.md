# A number needs a mapping

<!-- @fibonacci_sequences -->

Two towers wait at the beginning of the row. Each carries a one. Before asking the machine for another, give it a number yourself. What could follow two equal beginnings?

Press NEXT. Two appears. Another press brings three. Stay with the numbers for a few steps: one, one, two, three, five. The next tower is already implied by a relation you can test.[^1] Add the preceding pair, then ask the machine to make its next term.

The row grows, but its heights are suspicious. Eight has not become a tower eight times as high as one. Fifty-five, at the end of this ten-term display, still fits comfortably below the wall. Something has happened between the number and the body that stands for it.

Press HEIGHT. The small towers sink towards the floor. Later ones keep more of their height. Read the labels again: none of the numbers has changed.

With the linear mapping, each unit receives five centimetres. A one is now easy to overlook from a distance. The earlier logarithmic mapping gave it half a metre, then compressed the increasing values. One arrangement keeps the small beginnings present. The other lets height carry addition at a common scale. They offer different ways to read the same history.

Try SUM after revealing at least three terms. Beside the row, two colours share a stack. One colour supplies the earlier value, the other the later one. A separate stack carries their sum. At the last term, twenty-one units and thirty-four units reach the same height as fifty-five. Each unit is still five centimetres. The equality can be checked by looking across their tops.

Now return to logarithmic heights. The unit stacks remain equal, but adding the corresponding tower heights would not reconstruct the next tower. The display has not broken the recurrence. It has changed what height means.

Ask for RULE. The source receives two quantities:

```gdscript
var next_fib = fibonacci_numbers[i-1] + fibonacci_numbers[i-2]
fibonacci_numbers.append(next_fib)
```

The display receives a value and gives it a height:

```gdscript
var h = 0.05 * value
# or
var h = 0.5 * log(float(value)) + 0.5
```

There are two decisions here. We can change the representation without changing the relation it represents. We can also lose sight of a small value without removing it from the sequence. The label and the alternative view let us find that difference again.

Walk around the desk and continue beside the supported displays. The earlier examples remain: seed points, stacked scales, shell-like chambers, a helix and a branching diagram. They are held still here so their arrangements can be inspected. Read one of their small plates. The seed pattern uses an index to choose a radius and an angle. The branching diagram uses a remainder after division to choose how many children to make. These are further rules.

The helix is especially useful to look at twice. Its radius grows by phi over a full turn. A curve usually called a golden spiral grows by phi over a quarter turn. A familiar colour and a persuasive title would not make those constructions identical. The plate names what this source actually draws.

The pleasure of recognition can come before the inspection. A shell! A seed head! We can enjoy that resemblance and still ask which operations supplied it. The two ones did not contain instructions to make a flower. We added a way for numbers to take positions, turns and sizes.

<!-- @golden_rectangle -->

A rectangle stands upright farther into the hall. This time there are no towers and no curve. Imagine removing a square whose side is the shorter edge. What shape would be left?

Press NEXT. The square remains visible in one colour; the remainder occupies the other portion. Press again. The next square is smaller and turns the direction of the construction. Follow a few cuts before asking for their measurements.

MEASURE puts side lengths on the squares. They decrease as the cut numbers increase. The first is about 3.090 metres across, the next 1.910, then 1.180. Those are lengths from this five-metre rectangle. They are not the increasing Fibonacci values painted onto another surface.

The readout follows the remainder. Its longer side divided by its shorter side stays close to 1.618034. We have changed the dimensions, yet retained a relation between them. Rotate your attention with each cut: the longer edge becomes the shorter one of the next stage.

For a rectangle of width phi and height one, removing a unit square leaves sides one and phi minus one. To keep the original proportion after turning the remainder, we require:

```text
phi = 1 / (phi - 1)
phi² = phi + 1
```

The positive solution supplies the ratio used here. The code still needs to decide which side loses its square, how many cuts to make, how to colour them and how to bring the result into this upright display. The proportion leaves those choices open.

Try ARC. A line joins circular segments laid through the squares. Turn it off again. The partition remains. Making the curve visible did not cause the subdivisions.

Each segment is a quarter-circle. The resulting joined curve resembles a logarithmic spiral, but its curvature changes from one circular piece to the next. We can follow it and feel its invitation inward without making it evidence of a universal rule of beauty. Another cut makes a smaller square, another length, another demand on the eye. Eventually the record can name a difference the view barely resolves.

The sponge made room by discarding material. This rectangle keeps the pieces together and gives the remainder another turn. The towers changed what a quantity looked like. Each procedure carries something forward and makes other differences harder to encounter. Asking what bodies are possible now includes asking what kind of reading our chosen representation permits.

In the retained room beyond, the recursive cabinet, growing terrain, Romanesco, aggregation study and sphere remain. The Romanesco's cones inherit positions and turns from their parent cones. Its botanical appearance is a construction to inspect, not proof that a plant follows this code. The terrain and aggregation have their own updates. Let their differences interrupt the temptation to call everything here the same pattern.

Next we gather the procedures. Before naming a desired shape, try saying what one step would receive, retain, change and pass on. The next capability will give those instructions a grammar.

[^1]: The numbers are Leonardo of Pisa's, from the rabbit problem in *Liber abaci* (1202), and older than his name for them: Virahanka and Hemachandra had counted the same series for Sanskrit metres centuries before. The ratio the towers approach is Euclid's “extreme and mean ratio”; “golden” is a nineteenth-century word for it.
