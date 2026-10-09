# The view has partitions

<!-- @color_constellation_office -->

A sheet of cyan stands higher than you. Beyond it, magenta crosses your view. The pale floor continues through both colours. For a moment, the room seems to have several distances at once.

Step sideways. A dark patch narrows, then opens into blue. Nothing in the office has moved. You have changed which panes stand between you and the far wall.

There are twelve sheets, staggered across the floor. Some turn away from the others. Their edges stop short of enclosing a room. Follow one edge until you can pass it; the colour that covered the next space falls behind you.

A desk waits to one side. Two more places to work are scattered among the partitions. Sit in imagination, or stand beside a chair and look back through the colours. How much of this office could you call your own without being able to close it?

![Looking through the overlapping colour planes in the museum office.](/book-review/doc/book/iterations/2026-10-01-office-open-colour/layers-glass.png)

*The overlap changes with your position. The panes and the gaps remain still.*

At the entrance, press **FILTER / OPAQUE**. The view closes into coloured surfaces. Take the same route again. The next opening is harder to see, although it has not become narrower.

Press once more. A chair returns through a pane. The pane still stops your body.

In filter mode, the surface lets the view behind it contribute to the colour:

```gdscript
surface.albedo_color.a = 0.52
```

An overlap adds another tint. The pale backing keeps the view bright enough to follow through the layers. This is a blend of screen colours, not a simulation of the wavelengths passing through real glass.

In Paint, your mark joined someone else's on a shared surface. Here the colour between two people changes what each can see. Opaque walls can interrupt that exchange. Gaps still let a view reach around them. Privacy depends on where you stand, where someone else stands, and how far the partition extends.

<!-- @color_space_navigator -->

Find a gap between the panes and leave the office. At the smaller models, find the red corner of the cube, then look for red around the cylinder. The colour is familiar. Its neighbours have moved.

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

<!-- study-spine:colour_assembly -->

<!-- @colour_assembly -->

Twelve numbered panels hang above an open floor. Their colours repeat. From the controls, choose SCREENS: the same panels stand upright and divide the space ahead. Choose GATHER. Some return overhead while others hold an edge around an open centre.

Walk into it. Naming a space for gathering does not say who may gather there, or who is allowed to move its walls. Gillick's secondary structures make that uncertainty productive for this study. Here the arrangement can be changed from the console, while the colour can be changed independently. Find a panel by its number. Where did its neighbour go?

<!-- study-spine:colour_wall_studies -->

<!-- @colour_wall_studies -->

On the wall, twenty-four coloured rails stand at equal intervals. Widen the spacing. The same material now occupies more wall; the gaps have become a larger part of what you see.

Beside them, pull the vertical members of a crossing forward. Its drawing acquires depth and a second, shadowed grid. Further along, one rail can be omitted from an open composition and restored. These responses to Gillick keep a small vocabulary available for rearrangement. The clarity of the parts can suggest a comprehensible system. It does not disclose who made it, who maintains it, or who gets to change the plan.

<!-- @ -->

Ahead, the disco floor returns in colour. Keep its arrangement and change its palette. Does the same pattern still invite the same movement?
