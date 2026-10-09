# Walk a rule; watch a rule

Walk into the boolean tunnel and follow a corner through the successive openings. Its fourteen segments have fixed angles from zero to 130 degrees:

```gdscript
angle_deg = i * rotation_per_segment
```

The movement through these orientations is yours. The geometry holds still. Subtracting the inner box makes the hollow; turning the segment places that hollow at another orientation.

Then compare the five labelled carousel profiles. Follow one low stripe and one high stripe. Each layer uses:

```gdscript
var layer_speed: float = base_rotation_speed * pow(rotation_speed_multiplier, float(i))
```

All five profiles share that speed rule and the eight layer heights. Their radii differ. Compare the constant-radius column with the widening flare and narrowing ziggurat. What looks faster, and what did the code actually change?

Changing a radius changes the distance travelled around the rim in a revolution. This carries a concrete question into Trans_Scale.
