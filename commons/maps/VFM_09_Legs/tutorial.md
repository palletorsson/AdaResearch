# One Leg to Eight

A gait is not a style. It is what is left once you know how many feet are on the ground and how many can be in the air at once.

The rule that decides it.

```gdscript
# a body is statically stable while its centre of mass sits inside the
# polygon formed by the feet that are currently planted
func can_lift(planted: Array[Vector3], com: Vector3) -> bool:
    if planted.size() < 3:
        return false          # two points make a line, and a line is a fall
    return _inside_polygon(planted, com)
```

One leg fails the test always, so it must bounce. Two fail it always, so they fall forward and catch. Three pass it only while all three are down, so a three-legged walker can never lift a foot without a moment of dynamic stability. Six pass it with three lifted, which is why insects can run without ever being airborne.

Four is the interesting case. Lift one and you keep a triangle; lift a diagonal pair and you keep only a line — so a trot is, strictly, a controlled fall repeated. Watch the four-legged walker here, then go next door and watch the spider in the Arena do the same thing at a fifth the size.
