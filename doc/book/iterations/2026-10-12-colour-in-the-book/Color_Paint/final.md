# Before the hand

<!-- @ball_painting_demo -->

A spray can is already moving across the canvas. Wait before taking anything. The line changes direction, and the pigment changes colour as it travels. A painting is underway without your hand.

At the grid, a colour waited at an address until another write replaced it. Here, look back at a place the nozzle has left. Something of its passage remains. Something is already changing.

Thirty spray cans wait on the low tray. Pick up a colour, aim the nozzle at the canvas and hold the trigger. A hiss begins at your hand. Move across the automatic line. Your gesture reaches a surface that has other business; it does not wait for you to finish.

Bring the nozzle closer. The mark gathers into a smaller area. Draw back and the same colour spreads more thinly. Make a quick pass, then slow your hand. Colour gathers where you give it more time.

Stay close in one place for longer. A narrow run slips below the patch. Release the trigger and watch it continue, then stop. Your hand has finished before your paint has. Staying also leaves a movement behind.

Release the trigger. Your marks stop arriving while the other painter continues. Let go of the can and it returns to its place.

Which part of the image can you still call yours?

![Spray cans beside the shared canvas, with light and dense passes, overspray and a narrow paint run.](/book-images/iterations/2026-09-28-paint-aerosol-and-runs/shared-aerosol.png)

*The moving hand, the waiting hand. Distance spreads the colour; speed changes how much arrives in one place. A close, lingering spray can leave a run.*

The canvas has its own addresses. `u` and `v` measure position across the surface, each from zero at one edge to one at the other. The automatic painter supplies both coordinates:

```gdscript
var uv := Vector2(0.5+0.43*sin(elapsed*0.71),0.5+0.4*sin(elapsed*1.13+0.6))
```

Two oscillations give the automatic brush its position. Their rates differ. Follow one turn of the line and then another: neither coordinate alone describes the gesture you see. Its hue changes with elapsed time too. The moving can follows this calculation; its paint is placed directly on the surface.

The can in your hand takes another route. A ray leaves the nozzle and finds the canvas you are aiming at. The hit becomes a position on that surface, then a pair of coordinates between zero and one. The canvas is four metres wide and two and a half high. Those proportions matter: assuming a square would quietly move your mark away from where you aimed. Tilt the can and its round footprint stretches across the surface.

Both routes reach the same spray operation.

```gdscript
surface.draw_spray(hit, -normal, 0.06, color, 1.0 - exp(-7.0 * deposit_time), strokes)
```

That is the automatic caller. It leaves a soft patch with a radius of six centimetres. Your nozzle makes a patch whose radius depends on its distance from the canvas. The shader scatters its coverage into grain, thickest near the centre. One deposit is partly transparent; another can cover more of what was there. The apparent mist is still an arrangement of pixels.

The canvas keeps working between these calls. Its shader samples the preceding image and neighbouring pixels, allowing a little spreading, downward drift and fading toward the ground colour. The surface remembers by becoming another image. It does not preserve a list of gestures that can be retrieved intact.

```glsl
color = mix(ground_color, prev_color, pow(dissipation, step_scale));
```

Here the ground is white. It enters the work again as the direction of forgetting in this particular simulation. We could ask for another ground, another rate of fading, another way for two colours to meet. None is the natural behaviour of code. Here we can point to the line that makes the decision.

The automatic brush advances by elapsed time. The wet surface updates with rendered frames. Even their clocks differ.

Look along the edge of a light pass. Separate specks reach beyond the thick centre. The software fills between nearby samples of the moving nozzle, but it cannot keep every possible position of your hand. Even this soft edge has a resolution.

<!-- @albers_wall_gallery -->

Turn from that accumulating surface to the studies after Josef Albers’s *Homage to the Square*.[^albers] Let one coloured area hold your attention, then include its surround. At the painting, a neighbour may arrive while you look. Here an arrangement holds the comparison available for longer.

Return to the canvas. Some of what happened while you looked away is still visible. Some has flowed into something else. The shared surface has made room for two ways of moving without keeping them separate for you.

<!-- @ -->

Ahead, colour becomes a partition you can walk beside and look through. What happens to this question of neighbours when the coloured surface helps organise the room itself?

[^albers]: Albers began [*Homage to the Square*](https://www.moma.org/collection/works/79438) in 1950. His [*Interaction of Color*](https://www.albersfoundation.org/alberses/teaching/interaction-of-color), published in 1963, develops exercises in how surrounding colours affect what we see. Our invitation to attend to a colour and its surround draws on that inquiry; the procedural gallery is our interpretation.
