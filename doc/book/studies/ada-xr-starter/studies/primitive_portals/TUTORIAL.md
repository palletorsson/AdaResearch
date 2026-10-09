# Portals — how close is useful?

The sphere became rounder as we added divisions. How many would be enough for something we want to make?

Open `primitive_portals.tscn` in the [Ada student starter](../../README.md). A pink hexagon sits inside a grey circle guide. This is a reduced version of the planar comparison beside the museum's rings.

## 1. Follow the closed line

Open `studies/primitive_portals/perimeter.gd`. A supplied sampler gives us six positions equally spaced around a circle of radius one metre. They are in order; the first position is not repeated at the end.

We reuse the segment from Lines. To measure the whole boundary, we add the distances between neighbours, then close the line:

```gdscript
func polygon_perimeter(positions: Array[Vector3]) -> float:
    var total := 0.0
    for i in range(positions.size() - 1):
        total += positions[i].distance_to(positions[i + 1])
    total += positions[positions.size() - 1].distance_to(positions[0])
    return total
```

The loop measures all but the closing edge. The next line measures from the last position back to the first. Together they make the **perimeter**. This function takes a list and returns a number; it does not change the list or draw anything.

The hexagon's perimeter is about six metres. The corresponding circle's circumference is about 6.283185 metres. The straight edges take a shorter route.

## 2. Add sides

Find the settings:

```gdscript
var divisions := 6
var radius := 1.0
var tolerance := 0.01
```

Change `divisions` to `12`, then `24`, then `48`, running the scene after each edit. Keep the radius fixed. Watch the corners become less visible and the measured shortfall decrease. Walk closer when a corner becomes hard to see.

Each doubling uses twice as many segments. More detail has a construction cost, though a segment count alone does not tell us the frame rate.

The grey guide stays at 256 segments throughout. It is another finite drawing, not the exact circle against which the number is calculated.

## 3. Choose what counts as enough

The script compares the measured perimeter with the circumference formula:

```gdscript
    var circle_length := TAU * radius
    gap = circle_length - perimeter
```

`TAU` is Godot's approximation to 2π. The gap is a difference between total lengths, in metres. It is not the visible distance from a pink edge to the grey guide.

A **tolerance** is the difference we agree to accept. The supplied readout says *within tolerance* when `gap <= tolerance`. With `0.01`, 48 sides is the first of our four trials to pass.

Keep 48 sides and change the tolerance to `0.001`. Run again. The same polygon now falls outside the requirement. We changed the decision, not the geometry.

In exact geometry, these polygons approach the circle without becoming it. The displayed numbers also have limited precision. Neither a pleasing outline nor a passing comparison makes the construction exact.

The sampler and display are supplied, with their source included. You own the perimeter calculation and the settings. The museum's torus ladder and halving track give other ways to encounter a limit; this study measures neither their surfaces nor their motion.

We can now give a construction a purpose and a stopping criterion. Melencolia gathers these tools and asks what we want to do with them.
