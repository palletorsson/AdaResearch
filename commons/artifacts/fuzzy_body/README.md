# Two rooms claim one body

Installed in the actual **Endless Museum → Shaders → Patterns**, left side of the rear model gallery. Open `museum.tscn` to start the real museum at this hall. Map cell `[8,40]`, rotation 180; registry key `fuzzy_body`. The six previous artifacts and the onward passage remain.

Move the familiar black PointBody left and right. VR: grip and release. Desktop: right-click to carry and right-click to release; LEFT/CENTRE/RIGHT also place it. The instrument reads its horizontal position, clamped to ±0.88m, and multiplies that by 1.7 to place the larger sphere's centre. Height and depth are not input variables. Release parks the small point on its guide. Position buttons ignore an object currently held.

## Three readings of one source

- **FIELDS:** the undeformed sphere coloured by two independently graded fields and their overlap.
- **RULES:** LEFT lifts; RIGHT folds; BOTH twists. Output positions are a normalized blend of those consequents and a fixed neutral contribution. STRENGTH interpolates between source and result.
- **CUT:** draw a whole source triangle when `min(left, right)` at its centroid is at least THRESHOLD. The visible open band has discretized edges. This is a selection of a sphere's surface, not a filled or watertight solid.

WIDTH sets the transition half-width (0.15–1.8m). THRESHOLD applies only in CUT. STRENGTH applies only in RULES. The three meters report membership at the sphere's centre; per-vertex values vary over the surface. The three thin circles preserve the original sphere outline in RULES/CUT. The coloured frames name the fields; they do not depict exact membership contours.

## Actual operations

For sample position x, width w:

```text
left  = 1 - smoothstep(-w, w, x - 0.30)
right =     smoothstep(-w, w, x + 0.30)
both  = min(left, right)
target = (0.2*source + left*lift + right*fold + both*twist)
         / (0.2 + left + right + both)
result = lerp(source, target, strength)
```

These are graded memberships and authored vector-valued transformation rules. Membership is not probability. The implementation includes no randomness, delayed feedback, rigid-body simulation of the deformed surface, or invented engine fault. Every view reads the retained SphereMesh triangle samples. Changing a view never overwrites that record.

The form has 2,304 nondegenerate source triangles. It regenerates only when controls change or the hand changes horizontal position; hand sampling is capped at 20Hz. The moving surface has no collider. The plinth and console have fixed colliders; museum floor remains fixed. One local light belongs to the installed artifact.

This extends the earlier PointBody grip class and shared native dials/rectangular buttons. It is research in the existing museum, not a replacement student tutorial. No canonical tutorial.md/final.md or spine order is changed.

## Verification

Run `python tools/run_encounter_probe.py Shader_05_Patterns --sequence shaders --render --no-bridges --output-tag fuzzy-body --probe tools/probes/fuzzy_body_museum.gd` from the project root. The probe first repeats the existing precision/time/feedback installation checks, then checks memberships, independent lift arithmetic, retained source, threshold monotonicity, finite bounds, pointer buttons, desktop carry, synthetic XRTools grip/dials/release and supported access. Images are native Godot captures from this loaded hall. Physical headset comfort and Quest performance are not verified.
