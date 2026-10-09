# change: the chapters

## Change Intro

*Change_Intro*

### Change and accumulation

#### Measure a change

Where can a high curve be changing very little?

A fabric chosen in the previous room can arrive here on your dress. Changing an address changed what reached a wall or a skirt; now we choose where to inspect a curve. The curve stays fixed. Before asking how fast a body moves, we can ask how a value changes from one place to another.


Begin with the red point and its green neighbour. A green line joins them. At the starting position, which point is higher? Follow the curve between them. Does that straight connection tell you everything the curve has done?

The console names three quantities: `x`, the selected position; `f`, the value there; and `h`, the interval to the other sample. Below them are the rise and the rise divided by that interval. A negative rise says the second value is lower when the interval points to the right.

Leave the red point where it is and press **STEP**. Watch the green neighbour approach. Press again, and again. Does the line still lean the same way? Now press **DERIVATIVE**. A gold tangent appears at the red point, and a second plot shows the local slopes along the whole curve. Compare their directions before reading the numbers.

At this starting position, the wide interval crosses a crest. Its two endpoints report an overall fall. It does not tell us that every part of the journey went down. Close enough to the red point, the curve is still rising. Both reports describe this same curve. They answer questions at different scales.

With shorter names for the bench's variables, the calculation reads:

```gdscript
var rise = f(x + h) - f(x)
var rate = rise / h
```

Two values and an interval are enough to construct the green line. This rate is a finite difference: change across the interval, per unit of position. **STEP** cycles through 0.5, 0.25, 0.125 and 0.0625 position units. At the right edge, the bench samples backwards and displays a negative `h`; the division uses that signed interval. Zero is never offered. Dividing by zero would not uncover the tangent.

The derivative asks what these ratios approach as the interval tends to zero, where that limit exists. This bench does not reach the limit by pressing the button enough times. Its gold tangent comes from a separate analytic calculation for the smooth curve. With the same shortened names, the two functions read:

```gdscript
func f(x: float) -> float:
    return 0.5 + 0.4 * sin(2.0 * x) + 0.15 * cos(5.0 * x)

func df(x: float) -> float:
    return 0.8 * cos(2.0 * x) - 0.75 * sin(5.0 * x)
```

The two functions can be read alongside one another. The heights do not become slopes by changing their label: the calculation changes. `df` gives the local rate against which we can compare the finite samples. A smaller interval helps here, but the four choices are an experiment, not a proof that every smaller computational step must improve every estimate. Precision, noise and the shape of the function can matter.

Use the existing slider, or **x −** and **x +**, to move the red sample. Find a high point with a nearly flat tangent. Then find a lower point with a steep tangent. Compare `f` with the analytic `f′` readout. Height and rate cannot replace each other. Follow the second plot: where is the slope itself changing fastest as you move along the horizontal axis? A rate can have a rate of change of its own.

Try two places of similar height with opposite slopes. Imagine receiving only their height values. The report could be accurate and still conceal the distinction you need for your next movement. This is another kind of remainder: the data retained something true while leaving out a relation.

The sign card says **near zero** when the magnitude is below 0.05. That threshold is a display choice. It does not certify an exact zero or prove that you have found a maximum or minimum. Look at the neighbours. Extend the gold line in your imagination: it can describe the curve nearby without becoming a map of the whole journey.

Press **DERIVATIVE** again to hide the analytic comparison and make another prediction. **RESET** returns to the initial position and wide interval, with the tangent hidden. A sharp corner would ask whether the rates from its two sides can agree. This bench contains one smooth function; that corner remains an experiment we could build.


What does this make possible for a body? Knowing a height tells it where a surface is. What if a walking body also read the slope and leaned into an incline? The plot makes a relation available; a body could be written to act on it.

Replace position with time and a rate acquires different units: change per second. The choice of independent variable belongs to the question. Moving the slider quickly does not make this curve's derivative a velocity.

Walk to the accumulation workbench in this hall. Carry the difference between a value, a local rate and the interval through which you look. We will keep the same curve and ask a different question.

#### Add contributions

The curve has followed us. At the first workbench, two samples could report a fall while the curve was rising at the first point. Here we keep the same function and ask it for something else. Across this whole interval, how much area lies between the curve and the baseline?


Four blue rectangles wait under the line. Their tops cut through it. Somewhere a rectangle includes space above the curve; elsewhere it leaves space beneath it uncounted. Before touching the slider, choose one rectangle. Where would you put its top?

The console begins at **MID / N 4**. Press **CELL +** to move the red sample through the four intervals. The selected height and width appear together, followed by their product. Each interval is 1.25 units wide. One height has been asked to represent everything that happens across that width.

Press **HOLD**. A second panel keeps these four rectangles and their total. Now press **RULE** once. The live rectangles take their heights from the right edges of their intervals. The curve has not moved. The widths have not changed. Watch how much of the picture changes anyway.

Which total would you trust? Keep the question open while pressing **RULE** again for the left edges, then again for the midpoints. The held panel remembers the version you chose to keep. Its stillness gives the moving comparison somewhere to land.

In a teaching sketch, the calculation is short enough to read aloud:

```gdscript
var width = (b - a) / n
var total = 0.0
for i in range(n):
    var x = a + (i + fraction) * width
    total += f(x) * width
```

`fraction` is 0 for the left edge, 0.5 for the midpoint, and 1 for the right edge. An address, a height, a width, an addition. The loop keeps doing the same small thing. What looks like a filled area is made from these contributions.

This is a Riemann sum. Here `a` is 0 and `b` is 5. The function stays positive, so the contributions are positive areas. In another model, a rate multiplied by a time interval could give an amount gained during that interval. In Flow_Field, we will give the small interval to a clock.

Return to the midpoint rule and leave the held four-rectangle panel beside it. Move the count slider one stop. Eight narrower rectangles now look at the same curve. Follow their tops. A ridge that passed between two samples may now receive a sample of its own. Continue through 16, 32, 64 and 128. What becomes easier to estimate, and what becomes harder to distinguish by eye?

The held total stays at about 2.23665. At eight midpoint samples the live total is about 2.88669. More samples have changed the account substantially. The smooth-looking line did not warn us how much the first four would miss.

Only now press **REFERENCE**. The console shows a separate estimate made from 4,096 midpoint rectangles, about 2.86384, and the signed difference between the live sum and that reference. Toggle it off to return to the selected contribution. The small difference bar has a cap of 0.05; two full bars can conceal very different discrepancies. Read the numbers as well as the shape.

Try **RESET**, hold the four midpoint rectangles again, and select the right-edge rule. Against this reference, those four right-edge samples are closer than the four midpoints. A familiar method has no entitlement to win every coarse comparison. For this smooth function, sufficiently fine partitions bring the estimates together; that does not make every finite sampling choice equivalent.

There are several resolutions in front of you. The curve is drawn with 200 line intervals. Your sum uses one of six counts. The reference uses 4,096 rectangles. The integral is the limit these sums approach as the partition width tends to zero; none of the buttons reaches that limit. The apparently continuous image and the reassuring reference number each have a finite construction we can inspect.


What did we reject to make a total possible? Variation inside each interval has been replaced by one selected height. Then the individual contributions have been gathered into a number that cannot tell us where they came from. The held picture keeps some of that history available. It still cannot keep everything.

Ada needs such reductions to run. The question is where to reopen them. An estimate can be useful enough to act on while leaving a difference worth returning to. Who chooses the tolerance, and for which body or task?

Before leaving this hall, visit the bridge. The sum we have just inspected used positive heights. What if the contributions themselves could be positive and negative?

#### Recover a difference

Can a journey return to its starting height after changing all the way?


Watch the pulse move along the arch. Predict the height difference left between its beginning and end. Then follow the coloured contributions beneath the bridge. Which side contributes positively, and which side negatively?

The arch rises and falls to a level endpoint. Zero net change does not mean that nothing happened. The curve here is a different function from the workbenches: a symmetric arch. The pulse lets you follow it; the horizontal coordinate measures position.

A plot below the deck gives the local height rate with respect to horizontal position. Signed strips extend above or below the plot's baseline. Press **COMPARE TOTALS**. Endpoint labels and a difference marker appear beside it. Underneath, a numerical sum of the rate is compared with the endpoint height difference. Press again to hide this comparison and make another prediction; the arch and its signed strips remain.

```gdscript
var dx = span / samples
for i in range(samples):
    total += (slope_at(i) + slope_at(i + 1)) * 0.5 * dx
```

This is the structure of the bridge's trapezoid calculation, using 512 intervals. Its slope function and endpoint heights come from the same selected curve. It is a finite numerical comparison, not a proof printed by the machine.

For a continuously differentiable height function, integrating its signed derivative across an interval recovers the final height minus the initial height. This is the net-change relationship in the fundamental theorem of calculus. Recovering a function from its derivative still requires a starting value: a slope alone cannot tell us how high the whole bridge was placed.

Back at the line, `b - a` gave the same answer for a direct walk and a detour. Here we ask about height: the final height minus the initial height. The signed sum approaches that difference by adding the changes along the way. The strips can still show where the climb and descent happened; the total cannot.

Compare the earlier positive-area sum with this signed-rate sum. They use different inputs and answer different questions. Adding the magnitudes of the rate contributions would measure something else again. A journey's net height change can vanish while its rises and falls remain substantial.


What would a report of zero leave out of your journey? The total can be correct and insufficient for the question you now want to ask. Which part of the journey would you need to keep?

In **Flow_Field**, an update will help determine the address of the next sample. Carry the loop forward. We are about to make the path through the data part of the computation.

---

## Flow Field

*Flow_Field*

### A path made by its next step

Where will this particle look next?

In the previous hall, we chose addresses along a fixed interval, measured changes, and added contributions. Here an update changes a particle's position. That position becomes the address used by its next update. The loop starts making its own route through the field.


Begin with the little canvas. Eighty particles leave coloured trails. Follow one through a bend before trying to read the whole picture. Do its neighbours continue beside it? Predict the next turn.

The display says **FIELD HELD**. The particles are moving, but the field's time coordinate is held still. Press **ARROWS**. Twenty-four arrows appear over the canvas. Find one near a particle and compare their directions. An arrow gives the instruction at its own address; a particle a little farther away samples a different address. They need not point exactly alike.

The arrows and particles call the same function. The particle update can be condensed into this teaching sketch:

```gdscript
var direction = field_direction(position)
position += direction * speed * delta
```

The sum has begun to move. At the accumulation bench, the loop added a height times a width. Here `direction * speed` is a velocity: how fast, and which way. `delta` is the time since the previous frame, in seconds. Their product gives a displacement to add to the position.

The clock has entered the calculation. For this small interval, the program treats the sampled direction as fixed. Then it asks again at the new position. What changes if the interval spans a bend? The accumulated answer chooses the next address, and the trail remembers a limited sequence of those answers. It cannot remember an infinitely detailed movement between them.

Keep SCALE fixed and move SPEED. What changes about the spacing of the samples? Now keep SPEED fixed and change SCALE. Look at the arrows as well as the trails. You have changed how the directional rule varies across space. Existing trails still contain earlier instructions, so give the particles time to replace that history, or use RESET.

The field starts from a noise value: one number at each address. Here noise gives us smoothly varying values across space, with the same address returning the same value while the field is held. The program turns that value into an angle, then takes its cosine and sine to obtain a unit direction. That turn can be written as:

```gdscript
var angle = noise_value * TAU * 2.0
var direction = Vector2(cos(angle), sin(angle))
```

That construction makes a vector from a value. It does not calculate the noise function's gradient. A gradient would require measuring spatial changes in that scalar value, returning us to the first hall's question about rates. Similar-looking swirls can conceal different operations.

Press **FIELD TIME**. The field's time coordinate now advances too. The arrows refresh ten times per second while particles update every rendered frame. Can an arrow appear to lag a nearby turn? The shared rule is real, and the display still has a sampling schedule. Press again to hold field evolution at its current time; particles continue moving.

RESET scatters new starting positions and clears their trails without choosing a new noise seed. SEED chooses a different noise field and resets the particles. Neither button rewinds every clock. Distinguish a new starting distribution from a new rule before comparing their pictures.

Watch an edge. A particle leaving one side wraps to the opposite side. A long stroke across the canvas can be the trail renderer joining its last position before that wrap to its first position after it. The line suggests a crossing the update did not make. We have encountered another gap between an operation and its picture.


What kind of body can exist here? This particle has a position and receives a prescribed direction and speed. It has no mass in this calculation, no accumulated velocity and no collision negotiation with the other particles. Its neighbours can influence what we see without influencing how it moves.

The opposite edges are joined by the wrapping rule. Directions on those edges are not guaranteed to match: the noise is not made periodic merely because the particle's coordinates wrap. A world can provide a return route and still contain a seam. Follow one return and look for it.

The pattern may recall a fluid. Its beauty invites that association; the code lets us ask how far the association holds. Changing a boundary rule or adding interactions would permit other kinds of movement, and ask for other quantities to be stored.

In **Forces**, we will distinguish a prescribed direction from an acceleration that changes velocity. A body will carry more of its previous motion into the next update. What possibilities appear when it cannot simply take the new direction immediately?

---
