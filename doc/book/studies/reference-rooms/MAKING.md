# Five small transfers

The learner has already completed Day Zero. Each room supplies an image and enough apparatus to make one change. The line of learning is: recognise an operation you know, change its use, see what that choice includes or leaves out.

## 1. A place still held — Array / Tutorial_3D

**Bring:** coordinates, a repeated scene, nested loops, spacing. **New transfer:** an array can retain positions while its contents differ.

In `suspension.gd`, three nested loops place 75 fragments. The corner offsets are supplied material-making code; they are not an undeclared prerequisite for the array lesson.

```gdscript
var at := site + Vector3(0, 0.75 + y * 1.28, 0)
mesh_at(fragment(x * 15 + z * 3 + y), at, stone)
```

Keep every address and change the slider. Then change the vertical spacing from `1.28` to `1.08`. Predict which relationships will survive. What does a perfectly ordered placement tell you about the objects it holds? What can it not tell you about where they came from?

The varied fragments use a seeded random generator, introduced later in the spine. Here it is borrowed apparatus, like the fragment mesh itself. A complete lesson in generating variation belongs to Randomness/Noise; this encounter can return there.

## 2. Who fits through? — Scale / Body

**Bring:** position, size, BoxMesh, collision. **New transfer:** measure clearance against a particular body.

```gdscript
var width := lerpf(0.48, 1.68, amount)
var side_width := (wall_width - width) * 0.5
```

Move the slider, then enter the opening. The capsule diameter remains 0.56 m and the opening's headroom remains 2.05 m. The wall's side pieces change together so that its outer width stays 5.2 m. The doorway is assembled from solid boxes; this is not Boolean subtraction.

Try a different visitor radius in `gallery.gd`, then cross the same opening again. A dimension becomes a restriction only in relation to something trying to pass. Code equality at the exact boundary is not a useful promise of passage: physics margins also need clearance.

## 3. A world from a cone — Colour / composition

**Bring:** primitives, translation, scale, loops, material colour. **New transfer:** a repeated primitive acquires a role through arrangement.

The trees use the same three cones. The height changes; their site selection and count do not. The site generator is supplied with a fixed seed, not silently taught here.

```gdscript
var height := lerpf(0.28, 1.85, amount) * random.randf_range(0.65, 1.15)
```

First change height using the slider. Then make every seventh tree use the green material instead of gold. Next exchange one cone for a sphere while keeping its address and scale. At what point do you stop seeing a tree? At what point do you start seeing a model of a world?

Tubes, smooth shading and the camera are supplied helpers. Building the arched tube mesh from vertices is an optional return after mesh construction, not the first task in Colour.

## 4. The pattern crosses over — Shader Patterns

**Bring:** coordinates, repetition, a shader's vertex and fragment stages, uniforms. **New transfer:** a shared spatial coordinate field can cross object boundaries.

```glsl
vec3 p = world_position * density + vec3(phase + clock * 0.13);
```

The same phase reaches four materials on the flowers and room. Change phase while the camera stays still. Pause the optional drift. Does a black patch describe the flower's edge, or has it merely arrived there?

Try `density = 1.0` instead of `2.0` in `pattern_garden.gd`. Explain the consequence before running it. The three-axis blending in `pattern.gdshader` is supplied at first; it prevents one flat projection from becoming a stretched streak on perpendicular surfaces. It is a separate, later close reading.

## 5. A body in the plural — Queer Rubber / Pink Extravaganza

**Bring:** hierarchy, transforms, interpolation and surface shading. **New transfer:** the relation between assembled parts and the category a viewer assigns them.

```gdscript
var head_at := Vector3(sign_value * lerpf(0.34, 0.85, amount), 3.25, 0.05)
```

Unfold the body. The same six arms and three heads remain present. Change one side's endpoint or surface without making the other side agree. The curved tube constructor is supplied; there is no hidden rigging or physics lesson.

Then look at `skin.gdshader`. Its rim depends on the direction of viewing. Orbit the object and distinguish that colour shift from a lamp highlight. A surface can suggest softness without yielding; a body can look unusual while its code still imposes strict symmetry. Those are observations to work on, not definitions of queerness.
