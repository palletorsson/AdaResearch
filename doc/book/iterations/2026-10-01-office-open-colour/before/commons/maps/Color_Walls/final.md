# The view has partitions

<!-- @color_constellation_office -->

Someone has prepared a place for you. A desk, a monitor, a chair. Seven more places repeat along the aisle. The glass has colour; the office has an order.

Choose a cubicle. Before entering, look toward its desk through a pane. There is almost nothing between you and the chair. Almost. Walk toward the opening instead. Your view took a route your body could not.

At the entrance console, press **GLASS / OPAQUE**. Return to the same cubicle. The chair has disappeared behind a coloured wall. Find the opening again. Has the route become longer, or has finding it become a different task?

Press once more. The furniture returns to view. No doorway has opened.

Now go inside. Stand beside the chair and look back towards the aisle. The glass that let you look in also lets a view reach you here. Would you choose this much openness if you meant to stay?

![Looking out from inside a furnished cubicle through its coloured glass.](/book-review/doc/book/iterations/2026-09-28-walls-a-view-from-inside/inside-glass.png)

*Inside the cubicle, the aisle remains in view. The same doorway serves the glass and opaque states.*

The office has forty panes. The switch changes two material properties on each one:

```gdscript
mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if glass_visible else BaseMaterial3D.TRANSPARENCY_DISABLED
mat.albedo_color.a = 0.26 if glass_visible else 1.0
```

The collision bodies remain where they were. Each cubicle still has its 1.2-metre entrance; the walls still meet at right angles. You may have to find the chair again, but the opening that admitted you is still there.

In Paint, your gesture joined another painter on a shared surface. Here a coloured surface separates a place to work from a place to pass. Through the glass, each remains visible from the other. Opacity interrupts that exchange in both directions. The cubicle offers another degree of privacy without another way out.

Move until several panes overlap in your view. A colour gathers where you see through more than one. No new pane has appeared there. The renderer combines their colours and transparency; it does not calculate the wavelengths a real pane would absorb. Move again and the overlap shifts.

<!-- @color_space_navigator -->

Leave the cubicle through its opening. At the smaller models, find the red corner of the cube, then look for red around the cylinder. The colour is familiar. Its neighbours have moved.

You have been walking through an arrangement of coloured space. These models arrange colour values in space. In the cube, increasing the red channel moves a sample along one axis. Green and blue have their own directions. A colour has become an address again, but the address now comes from the colour itself.

![The museum’s RGB cube and HSV cylinder, each displaying five hundred colour samples.](/book-review/doc/book/iterations/2026-09-28-walls-a-view-from-inside/colour-coordinates.png)

*RGB channels become three straight directions. In HSV, hue goes around, saturation moves outward and value changes height.*

The RGB model assigns a sample's position and colour together. In this shortened version of the construction:

```gdscript
position = (Vector3(r, g, b) - Vector3.ONE * 0.5) * cube_size
colour = Color(r, g, b)
```

Follow the RGB cube upwards: that direction adds green. Across in the HSV cylinder, rising changes value, as height did among the pillars. Hue goes around its axis; saturation moves outward. Up is still up in the room, but the colour rule gives it another job.

Neither contains every colour as a visible point: each holds five hundred samples. The gaps belong to the display we have built. Even the black corner has been brightened slightly so that you can find it. To show a value, the exhibit has already made an accommodation. What would disappear if it refused?

<!-- @gradient_interpolator -->

At the next bench, red and blue mark the ends of a row of sixteen small cubes. Follow the colours between them, then press **RGB / HSV**. Leave the endpoints alone.

The middle changes. The agreement about where to begin and end did not decide how to travel.

![The same sixteen gradient cubes between red and blue in RGB and HSV modes.](/book-review/doc/book/iterations/2026-09-23-walls-view-and-passage/same-endpoints.png)

*The endpoints remain red and blue. Changing the interpolation changes the colours encountered between them.*

In RGB mode, the calculation is:

```gdscript
col = ca.lerp(cb, t)
```

Here `t` runs from zero to one across the sixteen samples. Red decreases as blue increases. In HSV mode, the program instead chooses the shorter arc around hue, while interpolating saturation and value. For these endpoints that keeps a bright passage through magenta, where the RGB passage was darker. Try **COLOUR A** and **COLOUR B** to choose another pair from eight presets. Does the distinction remain as conspicuous?

The path was chosen in code. The number of places along it was chosen too. Sixteen cubes let us inspect a transition without pretending we have occupied every value between its ends.

<!-- @ -->

Ahead, the disco floor returns in colour. Keep its arrangement and change its palette. Does the same pattern still invite the same movement?
