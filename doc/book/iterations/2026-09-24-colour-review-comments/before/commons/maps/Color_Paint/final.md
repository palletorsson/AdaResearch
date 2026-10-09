# Before the hand

<!-- @ball_painting_demo -->

A coloured ball is already moving across the canvas. Wait before taking anything. The line changes direction, and the pigment changes colour as it travels. A painting is underway without your hand.

At the grid, a colour waited at an address until another write replaced it. Here, look back at a place the ball has left. Something of its passage remains. Something is already changing.

Thirty pigment balls wait on the low tray. Pick one up and aim it at the canvas. Move across the automatic line. Your gesture reaches a surface that has other business; it does not wait for you to finish. Release the ball. It returns to its place, and your marks stop arriving. The other painter continues.

Which part of the image can you still call yours?

![The same museum canvas before pickup, during a second gesture, after release and a little later.](/book-review/doc/book/iterations/2026-09-23-paint-shared-memory/the-surface-keeps-working.png)

*A pigment ball is held and moved across the automatic line, then released. The ball returns to the tray while the painting continues to change.*

The canvas has its own addresses. `u` and `v` measure position across the surface, each from zero at one edge to one at the other. The automatic painter supplies both coordinates:

```gdscript
var uv := Vector2(0.5+0.43*sin(elapsed*0.71),0.5+0.4*sin(elapsed*1.13+0.6))
```

Two oscillations give the automatic brush its position. Their rates differ. Follow one turn of the line and then another: neither coordinate alone describes the gesture you see. Its hue changes with elapsed time too. The moving ball is the visible companion of this calculation; no collision is needed for its paint to arrive.

Your ball takes another route. A ray finds the canvas you are aiming at. The hit becomes a position on that surface, then a pair of coordinates between zero and one. The canvas is four metres wide and two and a half high. Those proportions matter: assuming a square would quietly move your mark away from where you aimed.

Both routes reach the same drawing operation.

```gdscript
surface.draw_line(previous,uv,color,12,256)
```

That is the automatic caller: brush radius twelve pixels, positions snapped to 256 divisions along each axis. The manual balls carry their own brush sizes and snap resolutions. Try another ball. Colour changes, but it is not the only difference in your hand. The apparently continuous movement passes through a finite choice of positions, as the drawn line did in Trace.

The wet canvas keeps working between these calls. Its shader samples the preceding image and neighbouring pixels, shifts the sampling position, and fades the result toward white. The surface remembers by becoming another image. It does not preserve a list of gestures that can be retrieved intact.

```glsl
vec4 color = mix(vec4(1.0), prev_color, dissipation);
```

White enters the work again. It is the direction of forgetting in this particular simulation. We could ask for another ground, another rate of fading, another way for two colours to meet. None is the natural behaviour of code. Here we can point to the line that makes the decision.

The automatic brush advances by elapsed time. The wet surface updates with rendered frames. Even their clocks differ. A slower rendering pace can change how much the image has faded during the same time on your watch. The computer's ability to keep up participates in what the painting becomes.

<!-- @albers_wall_gallery -->

Turn from that accumulating surface to the Albers studies. Let one coloured area hold your attention, then include its surround. At the painting, a neighbour may arrive while you look. Here an arrangement holds the comparison available for longer.

Return to the canvas. Some of what happened while you looked away is still visible. Some has flowed into something else. The shared surface has made room for two ways of moving without keeping them separate for you.

<!-- @ -->

Ahead, colour becomes a partition you can walk beside and look through. What happens to this question of neighbours when the coloured surface helps organise the room itself?
