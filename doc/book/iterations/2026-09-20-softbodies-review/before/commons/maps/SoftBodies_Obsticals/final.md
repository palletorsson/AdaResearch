# The room has a body

<!-- @breathing_room -->

The walls swell. Find a position from which both their edges and their centres remain visible. Selected vertices stay pinned while the surfaces respond between them. Before entering, watch a complete pressure cycle.

AMPLITUDE changes the range of pressure. RATE changes how quickly its driving phase advances. HOLD DRIVE holds that phase; it does not freeze the wall vertices. The soft solver can continue settling under the pressure it last received.

```gdscript
var p = (sin(_time) + 1.0) * 0.5 * breath_amplitude
for sb in _walls:
    sb.pressure_coefficient = p
```

The sine wave supplies pressure to a deformable body. It does not directly specify the location of every point on the wall. The actual surface is a result of the solver, its constraints and its encounters. This is the bridge from the earlier sine spaces: a periodic instruction now enters a system that can respond.

Calling it breathing is an invitation to bodily recognition. This room has no need for air and no sensor deciding when to inhale. The resemblance can be affecting without becoming a description of its mechanism. Its capacity to narrow space still deserves a practical question: how much room remains for the visitor?

<!-- @ -->

<!-- @softbody_gallery_part2 -->

The nearby contact gallery keeps other combinations visible: soft bodies meet rigid obstructions. Look at one named cell before surveying the whole array. The specimen, its support and its settings constitute a particular test; their variety is not a single scale from hard to soft.

The flag dancer remains as another encounter with a driven system. Together these objects begin to distribute softness across the room rather than confine it to one specimen. Yet the museum crossing still has independent support. A deforming wall and an onward route make different promises.

Next we will hold and replay a contact experiment. A spectacle of differences becomes more useful when we can identify which differences were introduced.

<!-- @ -->
