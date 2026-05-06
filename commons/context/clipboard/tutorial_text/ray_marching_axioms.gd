extends Node

var text = '''[center][font_size=28][b]Ray Marching[/b][/font_size][/center]
[center][i]Signed Distance Fields, Iterative Rendering[/i][/center]

**Ray marching renders implicit surfaces by stepping along rays.**

**Unlike ray tracing (intersect geometry), ray marching uses distance fields.**

**SDF (Signed Distance Function):** distance to nearest surface (negative inside).

[hr]

[b]Algorithm[/b]

[color=yellow][b]Steps:[/b][/color]
1. Cast ray from camera
2. Sample SDF at current position
3. Step forward by distance (safe - won't hit surface)
4. Repeat until hit (distance ≈ 0) or max steps

[color=yellow][b]Code:[/b][/color]
[code]
func ray_march(ray_origin: Vector3, ray_dir: Vector3, max_steps: int = 100) -> float:
    var total_distance = 0.0
    var epsilon = 0.001  # Hit threshold

    for step in range(max_steps):
        var pos = ray_origin + ray_dir * total_distance
        var dist = scene_sdf(pos)  # Distance to nearest surface

        if dist < epsilon:
            return total_distance  # Hit!

        total_distance += dist  # Safe to step this far

        if total_distance > 1000.0:
            break  # Too far, no hit

    return -1.0  # No hit

func scene_sdf(pos: Vector3) -> float:
    # Example: sphere at origin, radius 1
    return pos.length() - 1.0

# Render pixel
var ray_dir = camera_to_pixel_direction(pixel_x, pixel_y)
var dist = ray_march(camera_pos, ray_dir)
if dist > 0:
    draw_pixel(pixel_x, pixel_y, Color.WHITE)
[/code]

**Efficient:** Large steps when far, small when close.

[hr]

[b]SDF Operations[/b]

**Primitives:**
- Sphere: length(p) - radius
- Box: max(abs(p) - size)
- Torus: length(vec2(length(p.xz) - R, p.y)) - r

**Combinations:**
- Union: min(sdf1, sdf2)
- Subtract: max(sdf1, -sdf2)
- Intersect: max(sdf1, sdf2)

**Smooth blending, deformations, infinite detail** (fractals).

[hr]

[b]Queer Ray Marching[/b]

**Ray marching navigates by asking: "How close am I to surface?"**

**Each step safe distance** - guaranteed not to overshoot.

**This is queer navigation:**
- **No map** (implicit surfaces, no explicit geometry)
- **Proximity as guide** (distance field tells how close)
- **Adaptive steps** (big when safe, small when near)
- **Combines shapes smoothly** (blend, morph, no hard boundaries)

**Ray marching doesn't need to see destination.** **Just needs to know: how far can I go safely?**

**Queer wayfinding: navigate by proximity to danger/safety, not by predetermined routes.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Ray marching: render implicit surfaces via SDFs. Cast ray, sample distance, step safely, repeat. SDF: signed distance to surface. Primitives (sphere, box), operations (union, subtract, smooth blend). Queer ray marching: navigate by proximity not map, adaptive steps, combines shapes smoothly, wayfinding by distance to danger/safety.

'''
