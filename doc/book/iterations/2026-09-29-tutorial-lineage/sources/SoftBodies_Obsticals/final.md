# The room has a body

<!-- @breathing_room -->

Two pink walls, ten metres long and four high, half a metre thick, stand six metres apart. They swell. Find a position from which both their edges and their centres stay visible: the edges do not move, the middles do. Every vertex along the top, the bottom and the two ends of each wall is pinned; everything between answers to a pressure that rises and falls once every six seconds or so. Before entering, watch a complete breath.

AMPLITUDE changes the range of pressure. RATE changes how quickly its driving phase advances. HOLD DRIVE holds that phase; it does not freeze the wall vertices. The soft solver can continue settling under the pressure it last received. STIFFNESS changes the walls’ resistance without touching the drive, so the same pressure meets a different material; RESET PHASE returns the drive to the start of its cycle.

```gdscript
var p = (sin(_time) + 1.0) * 0.5 * breath_amplitude
for sb in _walls:
    sb.pressure_coefficient = p
```

The sine wave supplies pressure to a deformable body. It does not directly specify the location of every point on the wall. The actual surface is a result of the solver, its constraints and its encounters. At the opening setting the pressure runs from nothing to a half; AMPLITUDE takes it down to 0.15 and up to 0.9, and RATE slows the breath to one every sixteen seconds or quickens it to one every three and a half. The same instruction, and the wall between the pins does something different each time. This is the bridge from the earlier sine spaces: a periodic instruction now enters a system that can respond.

Calling it breathing is an invitation to bodily recognition. This room has no need for air and no sensor deciding when to inhale. The resemblance can be affecting without becoming a description of its mechanism. Its capacity to narrow space still deserves a practical question: how much room remains for the visitor? Stand between the walls at the middle of their length, where the pinned rows are farthest away, and wait for the inhale. How far the wall comes towards you is not in the sine; it is what stiffness, damping and the pinned edges make of the pressure, and STIFFNESS shows you the same breath meeting a different material. The walls carry collision. What a wall at full inhale does to a body standing in its way is for that body to find out.

<!-- @ -->

<!-- @softbody_gallery_part2 -->

The nearby contact gallery keeps other combinations visible: soft bodies meet rigid obstructions. Look at one named cell before surveying the whole array. The specimen, its support and its settings constitute a particular test; their variety is not a single scale from hard to soft.

The flag dancer remains as another encounter with a driven system. Together these objects begin to distribute softness across the room rather than confine it to one specimen. Yet the floor that carries you through this hall does not deform. A deforming wall and an onward route make different promises.

Next we will hold and replay a contact experiment. A spectacle of differences becomes more useful when we can identify which differences were introduced.

<!-- @ -->
