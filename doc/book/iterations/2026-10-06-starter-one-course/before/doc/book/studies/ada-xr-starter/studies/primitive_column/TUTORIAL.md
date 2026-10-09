# One column — an outline made of numbers

The octahedron used a rule to place six corners. Now we give a rule an outline to work with.

Open `primitive_column.tscn` in the [Ada student starter](../../README.md). One pale column stands in the room. Its sides catch the light differently as you walk around it.

## 1. Read the outline

Open `studies/primitive_column/column.gd`:

```gdscript
var profile: Array[float] = [0.50, 0.50, 0.32, 0.22, 0.32, 0.50, 0.50]
var height := 2.2
var sides := 8
```

The **profile** describes the column from bottom to top. Each entry is a radius in metres. `Array[float]` holds numbers where Trace's `Array[Vector3]` held positions.

Each radius makes one horizontal ring of positions. Seven entries give seven rings, equally spaced over the full height. The first two have radius `0.50`. The middle ring has radius `0.22`: that is the narrow waist. Straight strips join neighbouring rings.

Change only `0.22` to `0.55` and run again. The waist becomes a bulge. The neighbouring strips change slope. Height and the number of sides stay the same.

## 2. Follow one entry into space

This function turns the radii into positions:

```gdscript
func column_positions(radii: Array[float], full_height: float, divisions: int) -> Array[Vector3]:
    var circle := CircleSamples.points_on_circle(divisions, 1.0)
    var step := full_height / (radii.size() - 1)
    var points: Array[Vector3] = []
    for i in range(radii.size()):
        for p in circle:
            points.append(Vector3(p.x * radii[i], i * step, p.y * radii[i]))
    return points
```

`CircleSamples` is supplied. It returns equally spaced positions around a circle of radius one in the XY plane. Here we use its X and Y values for the column's X and Z. The ring lies horizontally; the column's Y comes from `i * step`.

Seven rings leave six intervals, so `step` divides the height by `radii.size() - 1`. The outer loop visits each radius. The inner loop places its ring. With seven radii and eight sides, the function returns 56 positions, starting at the bottom.

In `_ready()`, the returned positions become a surface:

```gdscript
    positions = column_positions(profile, height, sides)
    surface.mesh = ColumnSurface.make(positions, sides)
```

`ColumnSurface` is a supplied builder. It connects adjacent rings with triangles and closes the top and bottom. Its source is included; lighting normals and seam closure stay inside it for now. The position function returns data. The builder makes the mesh from that data.

## 3. Separate height from resolution

Restore the middle radius to `0.22`. Change `height` to `1.6` and run again. Every ring keeps its radius. Only the spacing between rings changes.

Restore `2.2`. Now try `sides` at `4`, `6`, `8`, `12` and `16`, running after each change. The profile and height stay fixed. The circular cross-sections gain sides; the straight intervals up the outline remain straight.

More rings would not automatically make this outline smoother. Adding an entry also changes the equal spacing. This reduced lesson joins specified radii with straight intervals; the larger Rings of Ash gallery uses curved profiles and a separate setting for sampling those curves.

## 4. Keep an outline of your own

Change two radii. Keep the height and side count fixed while you decide whether to keep the result. Then try it at another height.

Use 2–32 radii, each above zero and at most `0.8` metres. Keep the full height above zero and at most `2.5` metres in this room. The supplied sampler accepts 3–256 sides. These are the study's working bounds, not definitions of a column.

The column is a visible surface without a collider. The room, input, material and mesh builder are supplied. Your list and position rule produce its form; no prepared mesh is fetched from a scene.

Four sides can be the shape you want. Sixteen can suit another purpose. In Portals we will give one comparison a measurable requirement. That requirement will still be ours to choose.
