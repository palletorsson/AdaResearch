Where can a high curve be changing very little?

The fabric can come with you. In the previous room, changing an address changed what reached a wall or a skirt. Here the curve stays fixed while you choose where to inspect it. We are still changing position, not advancing a clock. Before asking how fast a body moves, we can ask how a value changes from one place to another.

<!-- @tangent_slope_workbench -->

Begin with the red point and its green neighbour. A green line joins them. At the starting position, which point is higher? Follow the curve between them. Does that straight connection tell you everything the curve has done?

The console names three quantities: `x`, the selected position; `f`, the value there; and `h`, the interval to the other sample. Below them are the rise and the rise divided by that interval. A negative rise says the second value is lower when the interval points to the right. It does not tell us that every part of the journey went down.

Leave the red point where it is and press **STEP**. Watch the green neighbour approach. Press again, and again. Does the line still lean the same way? Now press **DERIVATIVE**. A gold tangent appears at the red point, and a second plot shows the local slopes along the whole curve. Compare their directions before reading the numbers.

At this starting position, the wide interval crosses a crest. Its two endpoints report an overall fall. Close enough to the red point, the curve is still rising. Both reports describe this same curve. They answer questions at different scales.

```gdscript
var rise = f(x + h) - f(x)
var rate = rise / h
```

Two values and an interval are enough to construct the green line. This rate is a finite difference: change across the interval, per unit of position. **STEP** cycles through 0.5, 0.25, 0.125 and 0.0625 position units. At the right edge, the bench samples backwards and displays a negative `h`; the division uses that signed interval. Zero is never offered. Dividing by zero would not uncover the tangent.

The derivative asks what these ratios approach as the interval tends to zero, where that limit exists. This bench does not reach the limit by pressing the button enough times. Its gold tangent comes from a separate analytic calculation for the smooth curve:

```gdscript
func f(x: float) -> float:
    return 0.5 + 0.4 * sin(2.0 * x) + 0.15 * cos(5.0 * x)

func df(x: float) -> float:
    return 0.8 * cos(2.0 * x) - 0.75 * sin(5.0 * x)
```

The two functions can be read alongside one another. The heights do not become slopes by changing their label: the calculation changes. `df` gives the local rate against which we can compare the finite samples. A smaller interval helps here, but the four choices are an experiment, not a proof that every smaller computational step must improve every estimate. Precision, noise and the shape of the function can matter.

Use the existing slider, or **x −** and **x +**, to move the red sample. Find a high point with a nearly flat tangent. Then find a lower point with a steep tangent. Compare `f` with the analytic `f′` readout. Height and rate cannot replace each other.

Try two places of similar height with opposite slopes. Imagine receiving only their height values. The report could be accurate and still conceal the distinction you need for your next movement. This is another kind of remainder: the data retained something true while leaving out a relation.

The sign card says **near zero** when the magnitude is below 0.05. That threshold is a display choice. It does not certify an exact zero or prove that you have found a maximum or minimum. Look at the neighbours. Extend the gold line in your imagination: it can describe the curve nearby without becoming a map of the whole journey.

Press **DERIVATIVE** again to hide the analytic comparison and make another prediction. **RESET** returns to the initial position and wide interval, with the tangent hidden. A sharp corner would ask whether the rates from its two sides can agree. This bench contains one smooth function; that corner remains an experiment we could build.

<!-- @ -->

What does this make possible for a body? Knowing a height tells it where a surface is. Knowing how height changes with position can help it anticipate an incline. This plot supplies the distinction; it does not make the museum's walking controller use it. That connection would be another piece of code.

Replace position with time and a rate acquires different units: change per second. The choice of independent variable belongs to the question. Moving the slider quickly does not make this curve's derivative a velocity.

In **Accumulation_Riemann**, we gather contributions across an interval. Carry the difference between a value, a local rate and the interval through which you look. What we set aside to make one measurement manageable may matter when we begin to add things together.
