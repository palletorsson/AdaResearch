The ground is still here. After the tilted arrays and the turning blades, a continuous museum floor lets you change your pace.

The tunnel runs through the middle of the hall. Three stacks turn on either side. Begin with the opening.

<!-- @boolean_tunnel -->

Look into the first hollow cube, then through it towards the next. The openings do not keep the same orientation. Walk forward and follow a corner as it shifts around the passage.

Fourteen cubes make this tunnel. Each segment is three metres deep. The first receives no additional turn; the second receives ten degrees, the third twenty. By the last segment, the added angle is a hundred and thirty degrees.

```gdscript
angle_deg = i * rotation_per_segment
```

The tunnel holds these orientations still. Your movement brings you from one value to another, as it did in the previous hall's array. Here the repeated object surrounds a hollow. Its turned edges frame your passage.

Look back through the openings. A rule small enough to fit on one line has acquired length. You need time to walk what the program has already assembled.

The hole comes from subtracting an inner box from an outer box. The turn arranges those hollowed segments. Subtraction and rotation do different work: one opens the volume; the other changes the orientation of the opening along the run.

<!-- @ -->

Step out onto the gallery floor. You can walk around the next objects, pause between them, or return to a profile that looked different from the other side.

<!-- @carousel_cake -->

Find the stack labelled CAKE. Follow a stripe on a low layer, then a stripe near the top. Can you keep both in view through one revolution?

The upper layers turn faster. Each has a constant angular speed, but that speed is calculated from its place in the stack:

```gdscript
var layer_speed: float = base_rotation_speed * pow(rotation_speed_multiplier, float(i))
var angle: float = _rotation_angle * layer_speed
```

The base speed is half a radian per second. Each successive layer receives 1.2 times the speed of the one below. The bottom takes about twelve and a half seconds to turn once; the eighth layer takes about three and a half.

Now find COLUMN. The radii are equal all the way up. Follow the layers again. Has the speed rule changed, or has the shape changed what you notice?

Five profiles share the same eight layer heights and the same angular speeds. CAKE narrows and opens into a brim. ZIGGURAT becomes smaller towards the top. COLUMN keeps the radius constant. SPINDLE repeatedly widens and pinches. FLARE grows wider as you look up.

The fastest layer can therefore be small, broad, or the same radius as its neighbours. A point on a wider rim travels a longer distance in one turn. Equal angular speed does not mean equal distance travelled per second.

Stay with one stack until two layers seem to line up, then separate. Try another profile. The rule remains available in the code, but a description of the rule does not exhaust what its repetition looks like.

<!-- @ -->

The tunnel distributes angles along a path. The cakes distribute speeds through a stack and let time carry the differences past your eye. In one encounter you move through an arrangement already made; in the other you can stand still while relations continue to change.

Which part did your attention follow? Which layers went on turning while you watched something else?

The next hall takes up scale. These five silhouettes have already given us a reason to ask what a change in size does to the same movement.
