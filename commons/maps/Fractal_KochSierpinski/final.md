Replace and remove are the two fractal moves, both land between the integers, and dimension is a number you can measure rather than a number you are given.

You arrive standing five centimetres inside a pyramid. Nobody marked a spawn, so the room put you at its own centre, and its own centre is occupied by the base of the largest solid object in the chapter. Step out of it first.

```gdscript
D = log(N) / log(S)
```

Count how many copies of itself a shape contains, count how many times smaller each copy is, and divide one logarithm by the other. For a line cut in two you get one. For a square quartered you get two. For the two shapes in this room you get numbers that are not whole, and that is the whole content of the word fractal.

## The two moves

<!-- @fractal_koch_curve -->

The first move is replace. Take a segment, take out its middle third, and put two sides of a triangle there instead: four segments where there was one, each a third as long, so the length goes up by a third at every step and never stops going up. Four copies at one third: the dimension is about 1.26.

It is also the one thing here a hand can change. There is a slider on it, and turning it walks the depth up and down while you watch. Watch the size, though, not just the shape. At depth four this drawing measures the same bounding box as at depth zero, to the millimetre, because its spikes are built pointing inward. Infinite perimeter inside a finite box is the honest headline of the Koch curve, and this object demonstrates it by accident, in the wrong direction, which is a better demonstration than the intended one.

<!-- @koch_curve_3d -->

The same curve bent into an archway, drawn as two thousand three hundred cylinders. Look at it and then look at the note the corpus keeps about it: at this line thickness, iterations three, four, five and six are the same photograph. The detail is really there and the pipe drawn around it is thicker than the detail is fine. Resolution is a property of the drawing, not of the object.

<!-- @sierpinski_triangle -->

The second move is remove. Take a triangle, take out the middle one of the four you can quarter it into, and repeat on the three that are left: three copies at one half, dimension about 1.585. It builds over six seconds, a thousand and ninety-two slabs of it, ten metres wide in a room thirteen across, and it goes out through the east wall, out through the south wall and three and a half metres down through the floor. Nothing stops you walking through it, because it has no collision anywhere.

<!-- @sierpinski_pyramid -->

The same removal in three dimensions, and the only thing in this room that is solid. Twelve metres of lattice built out of nearly thirteen hundred separate cubes, each one carrying its own collision body, which is why you started inside it and why it is the one object here you can be stopped by. Four copies at one half in three dimensions gives a dimension of exactly two: a solid that fills area like a sheet and volume like nothing at all.

<!-- @ -->

## Measuring it

<!-- @box_counting_dimension -->

The bench that turns the formula into an instrument. Eight thousand points scattered into a Sierpinski gasket, a grid laid over them at six different scales, and a count at each scale of how many boxes have anything in them. Plot the counts against the scales on log paper and the points fall on a line, and the slope of that line is the dimension. It reads 1.585.

That number was not put in. It was measured off a scatter of points, and it agrees with the three-copies-at-one-half arithmetic to three decimal places. This is the moment the chapter stops describing and starts checking.

<!-- @recursion_observatory -->

Four of them side by side on one bench, ordered along a rail marked from zero to three: Cantor dust, the Koch curve, the Sierpinski pyramid, the Menger sponge. Nothing here moves. It is a shelf of specimens arranged by a quantity, which is what a museum does with anything once it can measure it.

<!-- @ -->

## Built without either move

<!-- @cube_cabin -->

<!-- @cube_bookshelf -->

A cabin and a bookshelf, each assembling itself out of boxes over a couple of seconds. They are here as the control, and they are more honest as a control than their labels admit: both are described as made by cube subdivision, and neither subdivides anything. The cabin is thirty-one hard-coded boxes and the shelf is twelve. Put them next to a Sierpinski pyramid and the difference is exact. One of these was written out part by part. The other was written once and applied to itself.

<!-- @science_screen -->

<!-- @dark_sphere -->

A screen set to record a trace, with nothing in the room drawing one, and a dark sphere turning over its halo. Between them they are the room's only two things at human scale, in a hall where the two objects that matter are five and ten metres taller than the walls.

<!-- @ -->

## Between the integers

A line is one-dimensional and a plane is two, and everything you were taught to draw sits on one of those whole numbers. Replace and remove both break that. The Koch curve is more than a line and less than a plane, at 1.26. The Sierpinski triangle is 1.585. The pyramid is exactly two and is not a surface.

The number is not a metaphor and not a ranking. It is a measured slope, taken off a log-log plot on the bench in the corner, and it says how fast detail appears as you look closer. That is what a dimension has always been. Nobody noticed it could be fractional until somebody measured a coastline.

Next: a fractal nobody built at all.
