# Which way will carry you?

[Inside Noise](noise-inside-noise.html) → **Noise Space 10** → [Noise Perlin Simplex](/necklace/thread?map=Noise_Perlin_Simplex&role=primary)

[Two primary works and their book passages](/necklace/thread?map=Noise_Space_10&role=primary) · [Sequence progress](/research/waves-chance-noise/index.html#Noise_Space_10)

Two pairs of pale posts face each other across the ground. A gold line joins them. Before entering, follow it with your eyes. **Where would you expect your pace to change?**

![A view from the near margin, with the proposed gold route crossing the noise terrain towards the far posts](noise-space-ten-standing.png)

The previous sphere surrounded us with a field while the floor stayed still. Here a value reaches the ground itself. The same field can carry the body differently when we change how much height it receives.

## Keep the field. Raise its contribution.

Choose a height scale below. The four images were rendered from the same camera in Godot. The seed, generator and routes stay fixed. At zero the ground is level; the field still has values, but its contribution to height is zero.

<!-- comparison -->

The section follows the actual mesh triangles, with 101 points spaced evenly along the route in plan. Its steepest sampled segment helps us investigate a crossing. A line has no width; a moving body meets neighbouring slopes too.

```gdscript
func ground_at(p: Vector2) -> float:
    var value: float = noise.get_noise_2d(p.x * noise_scale, p.y * noise_scale)
    return 1.0 + height_scale * edge_weight(p) * value
```

HEIGHT selects 0, 0.25, 0.65 or 0.90. OpenSimplex2S, seed zero, four fBM octaves, gain 0.5, lacunarity 2, frequency 0.1 and the coordinate multiplier five stay fixed. This gives the change a specific place to enter.

## Let the body answer

In two recorded desktop attempts, the same forward input starts from the near margin:

| Height scale | Route A section | Steepest sampled segment | Recorded attempt |
| --- | --- | --- | --- |
| 0.25 | 8.13 m | 24.18° | Crosses to the far margin |
| 0.90 | 9.45 m | 58.26° | Stops partway across, still supported |

The tested capsule is 1.8 m tall and 0.6 m across, with a 45° floor-angle limit. The stalled attempt belongs to that body, input and setting. Other ways through remain to be tried. Route B is a longer proposal, and its steepest sampled segment is slightly steeper here; a detour has not automatically become an easier way.

## A place from which to change the question

![The supported instrument with its tilted section display and local controls, beside the terrain](noise-space-ten-instrument.png)

The eight-metre patch meets a dark margin at one metre above the museum floor. The last 0.75 m of terrain gradually withholds the noise contribution so the edge stays level. The border is authored. It gives us a steady place to return to while comparing what changed.

**HEIGHT** changes the terrain. **ROUTE** switches the proposed line. **SAMPLE** follows one of five witnesses on the ground and section. **RESET** returns to height 0.25, route A and the first witness. The displayed ground and its collider rebuild together. HEIGHT and RESET wait while a player is on the patch.

The instrument's values come from the triangles actually underfoot. There are 81 × 81 vertices, ten centimetres apart. Querying the noise again between vertices can give a different height from interpolating the constructed surface. That small difference keeps the representation visible inside the result.

## What else could this crease permit?

A place that stops one body might hide another. Shelter would need another encounter: a body, an observer, a line of sight. Walking has opened the question without exhausting it.

Try to find an overhang. This heightfield gives each horizontal position one height. A cave needs room for both a floor and a roof at some of the same positions. The occupied volume of Noise Voxel remains available when this representation reaches its limit.

## Keep another time in the room

![The original dark orb on the raised east platform](noise-space-ten-orb.png)

The dark orb remains a second primary work. Its pulse continues while the terrain resets. Returning a multiplier to its starting value does not recover the time spent finding a way across.

## The restored hall

![Overhead view of the terrain and margin within the preserved museum grid](noise-space-ten-plan.png)

Both original artifacts remain. Every original structure cell remains, including the raised platforms. Two ramps connect the margin to the entrance and teleporter approach. The book already included this hall; the active museum had skipped it. It now follows Noise Inside Noise.

**36 rendered checks passed.** All four height states agree with the displayed vertices and collision faces. Physics rays meet the triangle-interpolated heights. The actual desktop pointer operates all four controls, both player groups prevent an occupied rebuild, and a separate unconfigured terrain keeps its original behaviour. The two ramps and museum route pass their checks.

Headset reach, legibility, comfort and Quest performance await the later headset session. The controls on this page inspect recorded Godot states, so the comparison is available remotely.

<!-- book -->

Next: **Noise Perlin Simplex**. Keep the body and question in view while changing the generator.

[Chapter](noise-space-ten-final.md) · [Tutorial](noise-space-ten-tutorial.md) · [Technical account](noise-space-ten-technical.md) · [Critical account](noise-space-ten-critical.md) · [Captured evidence](noise-space-ten-evidence.json) · [Run receipt](noise-space-ten-run.json)
