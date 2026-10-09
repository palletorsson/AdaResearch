# The view has partitions

<!-- @color_constellation_office -->

Someone has prepared a place for you. A desk, a monitor, a chair. Seven more places repeat along the aisle. The glass has colour; the office has an order.

Choose a cubicle. Before entering, look toward its desk through a pane. There is almost nothing between you and the chair. Almost. Walk toward the opening instead. Your view took a route your body could not.

At the entrance console, press **GLASS / OPAQUE**. Return to the same cubicle. The chair has disappeared behind a coloured wall. Find the opening again. Has the route become longer, or has finding it become a different task?

Press once more. The furniture returns to view. No doorway has opened.

![The same furnished cubicle viewed through glass and opaque partitions.](/book-review/doc/book/iterations/2026-09-23-walls-view-and-passage/same-opening.png)

*The view changes; the opening stays. Both states send the body through the same doorway.*

The switch changes two material properties on each of forty panes:

```gdscript
mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if glass_visible else BaseMaterial3D.TRANSPARENCY_DISABLED
mat.albedo_color.a = 0.26 if glass_visible else 1.0
```

The collision bodies remain where they were. Each cubicle still has its 1.2-metre entrance; the walls still meet at right angles. A change to visibility can alter how you approach a place without changing the geometry that admits you.

In Paint, two gestures entered one image. Here the image and the body encounter different accounts of the same wall. Through the glass, you can see the desk from the aisle and the aisle from the desk. Opacity interrupts that view in both directions. The cubicle offers another degree of privacy without another way out.

Move until several panes overlap. Their colours enter the renderer's transparency calculation. This glass does not calculate the wavelengths a real pane would absorb. Its clearness is a setting. Even the apparently empty space between you and the desk has been made by a procedure.

<!-- @color_space_navigator -->

Leave the cubicle through its opening. At the smaller models, look for red, first in the cube and then in the cylinder. Where could you go from it?

You have been walking through an arrangement of coloured space. These models arrange colour values in space. In the cube, increasing the red channel moves a sample along one axis. Green and blue have their own directions. A colour has become an address again, but the address now comes from the colour itself.

![The museum’s RGB cube and HSV cylinder, each displaying five hundred colour samples.](/book-review/doc/book/iterations/2026-09-23-walls-view-and-passage/colour-coordinates.png)

*RGB channels become three straight directions. In HSV, hue goes around, saturation moves outward and value changes height.*

The RGB model assigns a sample's position and colour together. In this shortened version of the construction:

```gdscript
position = (Vector3(r, g, b) - Vector3.ONE * 0.5) * cube_size
colour = Color(r, g, b)
```

Look across to the HSV cylinder. Hue turns around its axis, saturation moves outward, and value changes height. Going around has replaced one of the cube's straight directions. The two models offer different ways to organise colour values.

Neither contains every colour as a visible point: each holds five hundred samples. The gaps belong to the display we have built. Even the black corner has been brightened slightly so that you can find it. To show a value, the exhibit has already made an accommodation. What would disappear if it refused?

<!-- @gradient_interpolator -->

The next bench starts with red at one end and blue at the other. Sixteen small cubes run from one to the other. Follow them with your eyes, then press **RGB / HSV**. Leave the endpoints alone.

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

A view through glass, a position in a colour model, a calculated passage: similar appearances can conceal different operations. Ahead, the disco floor returns in colour. Keep its arrangement and change its palette. Does the same pattern still invite the same movement?
