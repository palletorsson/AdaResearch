Nothing places a form at the bottom. A body that can read only the slope under its own feet gets there anyway, and that is the whole chapter.

You arrive inside a hill. One of the exhibits in this room builds a twenty-metre landscape in a room fourteen metres wide, so the terrain swallows the walls, the way out and everything else standing here, and it has no collision at all: you walk through the hillside as though it were weather. Do that, and then find the small things inside it.

A marble in a bowl comes to rest at the bottom and nowhere else. Not because anything put it there, and not because it knows where the bottom is. It follows the slope down until the slope is zero, and where the slope is zero it stops. Every shape in the four halls after this one is found the same way, by something that cannot see the answer and can feel which way is down.

```gdscript
func _gradient_at(pos: Vector2) -> Vector2:
    var eps: float = gradient_sample_distance
    var gx: float = (_sample_height(pos.x + eps, pos.y) - _sample_height(pos.x - eps, pos.y)) / (2.0 * eps)
    var gz: float = (_sample_height(pos.x, pos.y + eps) - _sample_height(pos.x, pos.y - eps)) / (2.0 * eps)
    return Vector2(gx, gz)
```

Look at what that does. It does not know the surface. It takes two small steps either side of where it is, compares the two heights, and divides. The slope is measured, not known, and it is measured from nothing but the neighbourhood. On the bowl in this room, whose wall rises as the square of the distance from the centre, that measurement returns the true slope exactly.

## The oldest optimiser

<!-- @descent_marble_toy -->

A bowl the width of two hands, twelve centimetres deep, with a marble rolling in it. You cannot tip it and you cannot touch it; it is a thing to watch, damped, going round for as long as you stand there. This is the chapter in one object, and it is worth staying at until it is boring. The marble is not solving anything. It has no picture of the bowl, no memory of where it has been and no idea that a bottom exists. It reads the tilt under itself and moves that way, and the tilt runs out at exactly one place.

<!-- @gradient_descent -->

This is the hill you are standing in. The same rule as the marble, on a landscape nobody smoothed: a gold sphere takes a step down the steepest way about five times a second, trailing a line behind it and an arrow ahead of it. Watch where it ends. It ends in whichever valley it happened to start above, which on a wrinkled surface is not the lowest valley and has nothing to do with the lowest valley. The rule that always works in a bowl is a rule that works locally, and a wrinkled world is where those two stop being the same sentence.

<!-- @gradient_descent_well -->

A glowing basin banded with contour lines, one deep well off to one side, two shallow dips, and three marbles let go on it. They do not do the same thing. The difference is momentum, which here is set to a little under nine tenths: a marble carrying that much memory of its own motion rolls through a shallow dip and out the other side, and a marble with less settles in the first dip it meets. Same landscape, same rule, and the only thing separating a good answer from a mediocre one is how much of its past each marble is still carrying.

That is the problem the last hall in this chapter is about, posed here on the first bench, four rooms early.

<!-- @settling_tremble -->

A wall chart, a hand's span across, with two curves drawn over each other and nothing moving on it. The amber one is the true catenary, the exact shape a hanging chain takes, where every link balances. The blue one is seventeen nodes of a solver that was trying to reach it, stopped at the moment the largest move in a pass fell below six thousandths of a metre. They do not lie on top of each other. The blue nodes sit scattered a hair off the amber line, and that scatter is the whole point: the solver never arrives, it gets inside a band and stops, and the band is a number somebody chose.

The chart does not animate. It is a photograph of the tremble rather than the tremble, which is the correct way to show something whose whole content is that it never settles. Settled means tired, not still. Keep that. Every shape in the next three halls is a shape that stopped moving because a tolerance said it could.

<!-- @science_screen -->

The screen sweeps eight metres around itself once a second, looking for something it can redraw as a flat diagram. It finds nothing. Not one of the four things in this room answers the questions it knows how to ask, so it stands there lit and empty, facing away from where you came in. A measuring instrument surrounded by four objects it cannot read is a fair enough emblem for a room about a rule that only ever looks at the ground directly under itself.

<!-- @ -->

## Down is enough

The gradient is a local instrument. It has no opinion about the landscape, only about the ground beneath the object, and from that alone a form appears. That is the strange economy this chapter is about: nature does not compute a shape and then make it. It lets something fall, and the falling is the computation.

Three things in this room already complicate it, and all three come back. A marble finds the nearest bottom rather than the best one. A solver never actually finishes; it stops. And nothing here can be touched: five objects, not one collider between them, so the only thing you can do with a room about falling is watch other things fall.

Next: the two oldest of these problems, solved by matter itself, without a solver anywhere.
