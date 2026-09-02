Nobody builds this one. The boundary between two fates draws itself, and a single number decides which boundary you get.

The last two halls were made things: a rule you wrote, applied to a shape you chose, as many times as you said. This is the hall where that stops. There is no construction here. There is a question asked of every point in a plane, and the answer, plotted, is the picture.

```gdscript
func escapes(z: Vector2, c: Vector2, limit: int) -> int:
    for i in limit:
        z = Vector2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c
        if z.length_squared() > 4.0:
            return i          # it left. how long it took is the colour
    return limit              # it stayed
```

Square it and add c. Do that forever. Some starting points run away to infinity and some never leave, and the only thing the machine records is how many steps the runaways lasted. Nobody draws a shape. The shape is the border between the ones that stay and the ones that go.

## The set, on the floor

<!-- @julia_set -->

Not a picture and not a screen: a carpet of eight-centimetre cubes lying flat on the ground, one cube per point that survived the test. It is sparse, a scatter rather than a field, and it breathes on a thirty-second cycle as the zoom drifts, thickening to four hundred and sixty cubes and thinning back to forty-five. About a third of it hangs off the edge of the platform over nothing.

Walk around it rather than looking at it from one side. The cubes are the points that never escaped, and the empty floor between them is not background: it is every point that did. The picture is made of one answer and the absence of the other.

<!-- @julia_set_explorer -->

The instrument, and the only thing in this room you can operate. A table with a shader running on its top face, computing the same escape test per pixel in real time, and two grabbable sliders and four buttons on a panel at the near edge. The sliders move c.

That is the room in one gesture. c is a single complex number, two dials, and it is not a setting for the picture; it is the picture's entire identity. Move it a little and the shape deforms. Move it past a certain boundary and the set shatters from one connected object into infinitely many disconnected specks, with no intermediate state. There is a knife edge in the dial and you can find it with your hand.

<!-- @lyapunov_fractal -->

Flat on the floor beside it, a small painted square computed once and never again. Different equation, same idea: run a simple rule over and over for each point and colour by whether the running is stable or divergent. The order of the letters in its pattern is chosen before anything is drawn, and the picture is what that order produces. It is here to say that the trick is not special to one formula.

<!-- @dark_sphere -->

A dark sphere over a disc of light, turning, breathing. The one object in this hall that has a surface you could point at and a size you could state.

<!-- @ -->

## Found, not made

Six metres above the west edge of the floor, well past where you can walk, a red marker drags a comet trail through empty air. That is c, moving along a slow closed path, and the carpet on the floor is what c currently is. The parameter is out of reach and the picture is at your feet, and neither of them is a thing anybody drew.

This is the chapter's turn. Recursion was an engine you fed. The Koch curve and the Sierpinski triangle were rules you applied to a shape you chose. Here the rule is three operations long, the shape is not chosen at all, and what appears has a boundary of infinite intricacy that no one designed and no one can fully specify. The authorship has moved. You set one number; everything else is discovered.

And there are as many of these as there are complex numbers.

Next: the map of all of them at once.
