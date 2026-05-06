<<<ADA_BUNDLE>>>
sequence: noise
file: tutorial.md
maps: 10
skipped_passing: 0
created: 2026-04-24T05:40:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: Random_Noise_Types>>>
# Random Noise Types

White noise. Blue noise. Each has a spectral signature.

Generate white noise.

```gdscript
func white_noise_grid(size: Vector2i) -> Array:
    var grid: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x:
            row.append(randf())
        grid.append(row)
    return grid
```

Each cell independent. No structure.

Generate blue noise via dart throwing.

```gdscript
func blue_noise_points(count: int, bounds: Rect2, min_distance: float) -> Array:
    var points: Array = []
    var attempts: int = 0
    while points.size() < count and attempts < count * 30:
        var candidate := Vector2(randf() * bounds.size.x, randf() * bounds.size.y) + bounds.position
        var valid: bool = true
        for p in points:
            if candidate.distance_to(p) < min_distance:
                valid = false
                break
        if valid:
            points.append(candidate)
        attempts += 1
    return points
```

Dart throwing with minimum-distance constraint. Rejects candidates that are too close to existing points.

Render noise as texture.

```gdscript
func noise_to_texture(grid: Array) -> ImageTexture:
    var height: int = grid.size()
    var width: int = grid[0].size()
    var image := Image.create(width, height, false, Image.FORMAT_L8)
    for y in height:
        for x in width:
            image.set_pixel(x, y, Color(grid[y][x], grid[y][x], grid[y][x]))
    return ImageTexture.create_from_image(image)
```

Grayscale intensity maps to noise value. Noisy textures for use in shaders.

Build an FFT to see the spectrum.

```gdscript
func spectral_power(grid: Array) -> Array:
    var fft_result := compute_2d_fft(grid)
    var power: Array = []
    for row in fft_result:
        var power_row: Array = []
        for c in row:
            power_row.append(c.real * c.real + c.imag * c.imag)
        power.append(power_row)
    return power
```

Fourier transform followed by magnitude. White noise has flat power; blue noise concentrates power at high frequencies.

Radial power spectrum.

```gdscript
func radial_spectrum(power: Array) -> Array:
    var centre_x: int = power[0].size() / 2
    var centre_y: int = power.size() / 2
    var bins: Array = []
    for _i in 30: bins.append(0.0)
    var counts: Array = []
    for _i in 30: counts.append(0)
    for y in power.size():
        for x in power[0].size():
            var r: float = Vector2(x - centre_x, y - centre_y).length()
            var bin: int = int(r / 2)
            if bin < bins.size():
                bins[bin] += power[y][x]
                counts[bin] += 1
    for i in bins.size():
        if counts[i] > 0: bins[i] /= counts[i]
    return bins
```

Average power at each radial frequency. The shape of this curve distinguishes noise types.

Classify by spectrum.

```gdscript
func classify_noise(radial_spec: Array) -> String:
    var low_power: float = 0.0
    var high_power: float = 0.0
    for i in radial_spec.size() / 2:
        low_power += radial_spec[i]
    for i in range(radial_spec.size() / 2, radial_spec.size()):
        high_power += radial_spec[i]
    if low_power > high_power * 1.5: return "red (low-frequency)"
    elif high_power > low_power * 1.5: return "blue (high-frequency)"
    return "white (flat)"
```

Heuristic from low-vs-high frequency content. Red noise has smooth ramps; blue noise has point-like structure.

You can now generate white and blue noise, render as textures, compute their power spectra, and classify them. Noise_Columns extends into 3D noise for terrain.

<<<MAP: Noise_Columns>>>
# Noise Columns

Classical columns reshape under coherent noise. Baroque emerges.

Create a noise-driven displacement.

```gdscript
var noise := FastNoiseLite.new()

func setup_noise(seed: int = 12345) -> void:
    noise.seed = seed
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    noise.frequency = 0.3
```

FastNoiseLite is Godot's built-in noise generator. Perlin is the classic choice.

Displace a cylinder's vertices.

```gdscript
func displace_column_vertices(mesh: ArrayMesh, strength: float) -> ArrayMesh:
    var arrays: Array = mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    for i in vertices.size():
        var v: Vector3 = vertices[i]
        var offset: float = noise.get_noise_3dv(v) * strength
        var radial: Vector3 = Vector3(v.x, 0, v.z).normalized()
        vertices[i] = v + radial * offset
    arrays[Mesh.ARRAY_VERTEX] = vertices
    var new_mesh := ArrayMesh.new()
    new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return new_mesh
```

Noise drives radial displacement. The column bulges and contracts along its length.

Build the base column mesh.

```gdscript
func build_column_mesh(height: float = 3.0, radius: float = 0.5, resolution: Vector2i = Vector2i(16, 32)) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for ring in range(resolution.y + 1):
        var t: float = float(ring) / resolution.y
        for side in range(resolution.x + 1):
            var angle: float = float(side) / resolution.x * TAU
            var v := Vector3(cos(angle) * radius, t * height, sin(angle) * radius)
            st.add_vertex(v)
    # triangle indices...
    return st.commit()
```

A parametric cylinder. Resolution balances smoothness against vertex count.

Animate the displacement.

```gdscript
@export var displacement_strength: float = 0.0
@export var target_strength: float = 0.5

func _process(delta: float) -> void:
    displacement_strength = lerp(displacement_strength, target_strength, delta * 0.5)
    mesh_instance.mesh = displace_column_vertices(base_mesh, displacement_strength)
```

Smooth transition from classical to baroque. The column morphs in real time.

Sample a terrain height field.

```gdscript
func terrain_height(x: float, z: float, frequency: float, amplitude: float) -> float:
    return noise.get_noise_2d(x * frequency, z * frequency) * amplitude
```

Samples a 2D noise field. Use this as the Y coordinate for terrain vertices.

Build a terrain mesh.

```gdscript
func build_terrain(size: Vector2i, world_size: Vector2, amplitude: float) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for z in size.y + 1:
        for x in size.x + 1:
            var world_x: float = x * world_size.x / size.x
            var world_z: float = z * world_size.y / size.y
            var world_y: float = terrain_height(world_x, world_z, 0.2, amplitude)
            st.add_vertex(Vector3(world_x, world_y, world_z))
    # triangle strip indices...
    st.generate_normals()
    return st.commit()
```

Each vertex sits at a noise-sampled height. The terrain rolls smoothly.

You can now build noise-displaced columns and height-field terrain via coherent noise. Noise_One extends into fBm (fractal Brownian motion).

<<<MAP: Noise_One>>>
# Noise One

Fractal Brownian motion. Stack octaves for rich detail.

Sample fBm.

```gdscript
@export var octaves: int = 4
@export var lacunarity: float = 2.0  # frequency multiplier per octave
@export var persistence: float = 0.5  # amplitude multiplier per octave

func fbm(p: Vector2) -> float:
    var total: float = 0.0
    var frequency: float = 1.0
    var amplitude: float = 1.0
    var max_value: float = 0.0
    for _i in octaves:
        total += noise.get_noise_2d(p.x * frequency, p.y * frequency) * amplitude
        max_value += amplitude
        frequency *= lacunarity
        amplitude *= persistence
    return total / max_value
```

Stack multiple octaves at increasing frequency and decreasing amplitude. Normalised to [-1, 1].

Build a torus surface.

```gdscript
func torus_mesh(R: float, r: float, resolution: Vector2i) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for major in resolution.x + 1:
        var u: float = major * TAU / resolution.x
        for minor in resolution.y + 1:
            var v: float = minor * TAU / resolution.y
            var x: float = (R + r * cos(v)) * cos(u)
            var y: float = r * sin(v)
            var z: float = (R + r * cos(v)) * sin(u)
            st.add_vertex(Vector3(x, y, z))
    # triangle indices
    return st.commit()
```

Two-radius parametric torus. R is the main radius; r is the tube radius.

Sample noise on the torus.

```gdscript
func torus_noise(u: float, v: float) -> float:
    return fbm(Vector2(u, v))
```

Evaluate fBm at (u, v) coordinates. The output is used to tint or displace the torus.

Wrap noise without seams.

```gdscript
func wrapped_torus_noise(u: float, v: float) -> float:
    var weight_u1: float = 1 - abs(u - 0.5) * 2
    var weight_u2: float = 1 - abs(u) * 2
    var weight_v1: float = 1 - abs(v - 0.5) * 2
    var weight_v2: float = 1 - abs(v) * 2
    return (
        fbm(Vector2(u, v)) * weight_u1 * weight_v1 +
        fbm(Vector2(u + 1, v)) * weight_u2 * weight_v1 +
        fbm(Vector2(u, v + 1)) * weight_u1 * weight_v2 +
        fbm(Vector2(u + 1, v + 1)) * weight_u2 * weight_v2
    )
```

Blend four noise samples at the torus's seam. Produces a continuous noise without visible seams.

Displace torus vertices.

```gdscript
func displace_torus(mesh: ArrayMesh, amplitude: float) -> ArrayMesh:
    var arrays := mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
    for i in vertices.size():
        var v: Vector3 = vertices[i]
        var u: float = atan2(v.z, v.x) / TAU + 0.5
        var v_coord: float = atan2(v.y, sqrt(v.x * v.x + v.z * v.z) - main_radius) / TAU + 0.5
        var offset: float = wrapped_torus_noise(u, v_coord) * amplitude
        vertices[i] = v + normals[i] * offset
    arrays[Mesh.ARRAY_VERTEX] = vertices
    var new_mesh := ArrayMesh.new()
    new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return new_mesh
```

Displace along the normal. The torus keeps its topology but gains organic texture.

Render octave layers.

```gdscript
func render_octaves_separately() -> void:
    for i in octaves:
        octaves = i + 1
        var mesh := displace_torus(base_mesh, 0.2)
        spawn_torus_at_offset(mesh, Vector3(i * 5, 0, 0))
```

Walk down the row and see how detail accumulates as octaves are added.

You can now compute fBm by stacking octaves, build parametric tori, wrap noise around them seamlessly, and render octave-by-octave. Noise_Voxel extends into 3D voxel displacement.

<<<MAP: Noise_Voxel>>>
# Noise Voxel

Sample 3D noise into a voxel grid. Carve solids from density.

Set up the voxel grid.

```gdscript
@export var grid_size: Vector3i = Vector3i(32, 32, 32)
@export var threshold: float = 0.5

var density: Array = []

func initialise() -> void:
    density.clear()
    for x in grid_size.x:
        density.append([])
        for y in grid_size.y:
            density[x].append([])
            for z in grid_size.z:
                var p := Vector3(x, y, z) * 0.1
                density[x][y].append(noise.get_noise_3dv(p))
```

Each voxel stores a noise value. The density field becomes the raw material.

Threshold to binary.

```gdscript
func is_solid(x: int, y: int, z: int) -> bool:
    return density[x][y][z] > threshold
```

Above threshold is solid; below is empty. The threshold decides what the world looks like.

Render solid voxels.

```gdscript
func render_voxels() -> void:
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = BoxMesh.new()
    var solid_voxels: Array = []
    for x in grid_size.x:
        for y in grid_size.y:
            for z in grid_size.z:
                if is_solid(x, y, z):
                    solid_voxels.append(Vector3i(x, y, z))
    multimesh.instance_count = solid_voxels.size()
    for i in solid_voxels.size():
        var t := Transform3D.IDENTITY
        t.origin = Vector3(solid_voxels[i])
        multimesh.set_instance_transform(i, t)
    var instance := MultiMeshInstance3D.new()
    instance.multimesh = multimesh
    add_child(instance)
```

MultiMesh is essential at these voxel counts. One draw call for the entire volume.

Cull interior voxels.

```gdscript
func is_visible(x: int, y: int, z: int) -> bool:
    for axis in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
        var neighbour: Vector3i = Vector3i(x, y, z) + axis
        if neighbour.x < 0 or neighbour.x >= grid_size.x: return true
        if neighbour.y < 0 or neighbour.y >= grid_size.y: return true
        if neighbour.z < 0 or neighbour.z >= grid_size.z: return true
        if not is_solid(neighbour.x, neighbour.y, neighbour.z): return true
    return false
```

A voxel is visible only if at least one neighbour is empty. Interior cubes are invisible and can be skipped.

Animate threshold.

```gdscript
func _process(delta: float) -> void:
    threshold = 0.3 + 0.4 * sin(Time.get_ticks_msec() / 1000.0 * 0.5)
    regenerate()
```

The threshold oscillates. The world morphs between sparse clouds and dense blocks.

Carve out a tunnel.

```gdscript
func carve_tunnel(start: Vector3i, end: Vector3i, radius: int) -> void:
    var steps: int = int(Vector3(start - end).length())
    for i in steps:
        var t: float = float(i) / steps
        var centre: Vector3 = lerp(Vector3(start), Vector3(end), t)
        for dx in range(-radius, radius + 1):
            for dy in range(-radius, radius + 1):
                for dz in range(-radius, radius + 1):
                    if Vector3(dx, dy, dz).length() < radius:
                        var voxel: Vector3i = Vector3i(centre) + Vector3i(dx, dy, dz)
                        density[voxel.x][voxel.y][voxel.z] = -1.0
```

Set density to a very negative value, ensuring the voxel is empty. A tunnel runs through the terrain.

You can now sample 3D noise into a density field, threshold to voxels, render via MultiMesh, cull interior voxels, animate threshold, and carve tunnels. Noise_6_Wall extends into shader-based fBm rendering.

<<<MAP: Noise_6_Wall>>>
# Noise 6-Wall

Six octaves of noise rendered per-pixel in a shader.

Write a fragment shader.

```gdscript
const SHADER_CODE: String = """
shader_type canvas_item;

uniform float time;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float smoothstep_val(float t) {
    return t * t * (3.0 - 2.0 * t);
}

float value_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = vec2(smoothstep_val(f.x), smoothstep_val(f.y));
    return mix(
        mix(hash(i), hash(i + vec2(1, 0)), f.x),
        mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x),
        f.y
    );
}

float fbm(vec2 p) {
    float total = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 6; i++) {
        total += value_noise(p) * amplitude;
        p *= 2.0;
        amplitude *= 0.5;
    }
    return total;
}

void fragment() {
    vec2 p = UV * 8.0 + vec2(time * 0.1, 0.0);
    float n = fbm(p);
    COLOR = vec4(n, n, n, 1.0);
}
"""
```

Six octaves stacked in a for loop. Each octave doubles the frequency and halves the amplitude.

Attach the shader.

```gdscript
func create_shader_material() -> ShaderMaterial:
    var shader := Shader.new()
    shader.code = SHADER_CODE
    var material := ShaderMaterial.new()
    material.shader = shader
    return material
```

Standard pipeline: create Shader, wrap in ShaderMaterial, apply to a node.

Apply to a wall.

```gdscript
func setup_wall() -> void:
    var wall := MeshInstance3D.new()
    wall.mesh = QuadMesh.new()
    wall.mesh.size = Vector2(6, 3)
    wall.material_override = create_shader_material()
    add_child(wall)
```

A flat quad takes the shader's output as its albedo. The wall flickers with noise.

Pass time as a uniform.

```gdscript
var wall_material: ShaderMaterial

func _process(_delta: float) -> void:
    wall_material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)
```

The shader reads the time; the noise scrolls accordingly.

Render as 3D fog.

```gdscript
const VOLUMETRIC_SHADER := """
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled;

uniform float density_scale = 1.0;

float fbm(vec3 p) {
    // same pattern as 2D but with 3D hash
    float total = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 6; i++) {
        total += value_noise_3d(p) * amplitude;
        p *= 2.0;
        amplitude *= 0.5;
    }
    return total;
}

void fragment() {
    float density = fbm(VERTEX * density_scale);
    ALPHA = density * 0.3;
    ALBEDO = vec3(1.0);
}
"""
```

A 3D noise shader on a transparent volume. The cloud appears as drifting fog.

Tune the frequencies.

```gdscript
@export_range(0.5, 4.0) var base_frequency: float = 1.0

func update_frequency() -> void:
    wall_material.set_shader_parameter("frequency", base_frequency)
```

Lower values produce broad patterns; higher values produce fine detail.

You can now write a fBm fragment shader, apply it to walls, scroll it over time, and extend to volumetric 3D rendering. Noise_Inside_Noise extends into domain warping.

<<<MAP: Noise_Inside_Noise>>>
# Noise Inside Noise

Domain warping. Noise drives the coordinates of other noise.

Simple warp.

```gdscript
func warped_noise(p: Vector2, warp_amount: float) -> float:
    var offset := Vector2(
        noise.get_noise_2d(p.x, p.y),
        noise.get_noise_2d(p.x + 100, p.y + 100)
    ) * warp_amount
    return noise.get_noise_2d(p.x + offset.x, p.y + offset.y)
```

First noise gives displacement; second noise is sampled at the displaced position. Produces turbulent flow patterns.

Recursive warp.

```gdscript
func recursive_warp(p: Vector2, depth: int) -> float:
    if depth == 0:
        return noise.get_noise_2d(p.x, p.y)
    var offset := Vector2(
        recursive_warp(p, depth - 1),
        recursive_warp(p + Vector2(100, 100), depth - 1)
    ) * 0.5
    return noise.get_noise_2d(p.x + offset.x, p.y + offset.y)
```

Each level warps the next. Produces increasingly chaotic patterns at each depth.

Render a warped field.

```gdscript
func render_warp_to_texture(resolution: Vector2i, warp_amount: float) -> ImageTexture:
    var image := Image.create(resolution.x, resolution.y, false, Image.FORMAT_RGBA8)
    for y in resolution.y:
        for x in resolution.x:
            var p := Vector2(x * 0.05, y * 0.05)
            var value: float = warped_noise(p, warp_amount)
            var color := Color(value * 0.5 + 0.5, value * 0.7 + 0.3, 1.0 - value * 0.3, 1.0)
            image.set_pixel(x, y, color)
    return ImageTexture.create_from_image(image)
```

Each pixel sampled and coloured. Higher warp amounts produce more marbled, fluid-like textures.

Animate the warp.

```gdscript
var warp_strength: float = 0.0

func _process(delta: float) -> void:
    warp_strength = fmod(warp_strength + delta * 0.5, 2.0)
    update_material(warp_strength)
```

Oscillating warp strength. The texture pulses between ordered and turbulent.

Use curl noise.

```gdscript
func curl_noise(p: Vector2) -> Vector2:
    var h: float = 0.01
    var dx_dy: float = (noise.get_noise_2d(p.x, p.y + h) - noise.get_noise_2d(p.x, p.y - h)) / (2 * h)
    var dy_dx: float = (noise.get_noise_2d(p.x + h, p.y) - noise.get_noise_2d(p.x - h, p.y)) / (2 * h)
    return Vector2(dx_dy, -dy_dx)
```

Divergence-free velocity field. Perfect for flow simulation; particles move without compressing.

Advect particles.

```gdscript
func advect_particles(particles: Array, delta: float) -> void:
    for i in particles.size():
        var flow: Vector2 = curl_noise(particles[i]) * 2.0
        particles[i] += flow * delta
```

Each particle samples the flow at its position and moves accordingly. Paths swirl without compression.

You can now warp noise with noise, apply recursive warping, animate warp strength, compute curl noise, and advect particles through the resulting flow. Noise_Space_10 extends into the 10D parameter space.

<<<MAP: Noise_Space_10>>>
# Noise Space 10

Ten parameters. The space of all possible noise.

Define the parameter space.

```gdscript
class_name NoiseParameters

var position: Vector3 = Vector3.ZERO
var time: float = 0.0
var octaves: int = 4
var persistence: float = 0.5
var lacunarity: float = 2.0
var frequency: float = 1.0
var amplitude: float = 1.0
var seed: int = 12345
```

Eight scalar parameters plus position (3D) and time. All controls exposed.

Configure a noise generator.

```gdscript
func apply_to(noise: FastNoiseLite, params: NoiseParameters) -> void:
    noise.seed = params.seed
    noise.fractal_octaves = params.octaves
    noise.fractal_gain = params.persistence
    noise.fractal_lacunarity = params.lacunarity
    noise.frequency = params.frequency
```

Map the parameter bag onto FastNoiseLite's fields. The generator's behaviour fully determined by these.

Sample at a position.

```gdscript
func sample(noise: FastNoiseLite, params: NoiseParameters) -> float:
    apply_to(noise, params)
    return noise.get_noise_3dv(params.position) * params.amplitude
```

One function; ten-dimensional input; scalar output.

Walk through parameter space.

```gdscript
var trajectory: Array = []

func step_through_space(param_name: String, target: float, duration: float) -> void:
    var start: float = current.get(param_name)
    var tween := create_tween()
    tween.tween_method(
        func(t): current.set(param_name, lerp(start, target, t)); record_trajectory(current); rerender()
    , 0.0, 1.0, duration)
```

Animate any single parameter while others stay fixed. The trajectory is a line in the 10D space.

Record a trajectory.

```gdscript
func record_trajectory(params: NoiseParameters) -> void:
    trajectory.append({
        "position": params.position,
        "octaves": params.octaves,
        "persistence": params.persistence,
        # ... other params
    })
```

Stores a snapshot of each step. Lets the learner replay the traversal.

Save preset.

```gdscript
func save_preset(name: String, params: NoiseParameters) -> void:
    var preset_data: Dictionary = {
        "octaves": params.octaves,
        "persistence": params.persistence,
        "lacunarity": params.lacunarity,
        "frequency": params.frequency,
        "amplitude": params.amplitude,
        "seed": params.seed,
    }
    presets[name] = preset_data
```

Named configurations. The learner builds a library of interesting points in the space.

Load preset.

```gdscript
func load_preset(name: String) -> NoiseParameters:
    var data := presets.get(name, {})
    var params := NoiseParameters.new()
    for key in data:
        params.set(key, data[key])
    return params
```

Reverse of save. The learner can jump to any saved point.

You can now define a noise parameter bag, apply it to a generator, walk through parameter space with tweens, record trajectories, and save/load presets. Noise_Perlin_Simplex extends into algorithm comparison.

<<<MAP: Noise_Perlin_Simplex>>>
# Noise Perlin / Simplex

Two algorithms, same family. Different grids.

Sample Perlin noise.

```gdscript
func perlin_noise(p: Vector2) -> float:
    var perlin := FastNoiseLite.new()
    perlin.noise_type = FastNoiseLite.TYPE_PERLIN
    return perlin.get_noise_2d(p.x, p.y)
```

Uses a hypercubic grid. Axis-aligned artifacts visible at the right angles.

Sample Simplex noise.

```gdscript
func simplex_noise(p: Vector2) -> float:
    var simplex := FastNoiseLite.new()
    simplex.noise_type = FastNoiseLite.TYPE_SIMPLEX
    return simplex.get_noise_2d(p.x, p.y)
```

Uses a simplicial grid (triangles in 2D). No axis-aligned artifacts.

Compare outputs side by side.

```gdscript
func render_comparison() -> void:
    var perlin_texture := render_noise_function(perlin_noise, Rect2(0, 0, 10, 10), Vector2i(256, 256))
    var simplex_texture := render_noise_function(simplex_noise, Rect2(0, 0, 10, 10), Vector2i(256, 256))
    spawn_texture_at(perlin_texture, Vector3(-2, 0, 0))
    spawn_texture_at(simplex_texture, Vector3(2, 0, 0))
```

Same seed, same frequency. Any visible difference is algorithmic.

Rotate to expose artifacts.

```gdscript
func render_rotated(rotation_deg: float) -> ImageTexture:
    var r: float = deg_to_rad(rotation_deg)
    var image := Image.create(256, 256, false, Image.FORMAT_L8)
    for py in 256:
        for px in 256:
            var p := Vector2(px - 128, py - 128)
            var rotated := p.rotated(r)
            var value: float = perlin_noise(rotated / 16.0)
            image.set_pixel(px, py, Color(value, value, value))
    return ImageTexture.create_from_image(image)
```

Rotate the sample coordinates before evaluation. Perlin's axis-aligned artifacts travel with the rotation; Simplex's don't.

Measure isotropy.

```gdscript
func measure_isotropy(noise_func: Callable, samples: int = 1000) -> float:
    var angle_bins: Array = []
    for _i in 16: angle_bins.append(0.0)
    for _i in samples:
        var p := Vector2(randf() * 100, randf() * 100)
        var h: float = 0.01
        var grad := Vector2(
            (noise_func.call(p + Vector2(h, 0)) - noise_func.call(p - Vector2(h, 0))) / (2 * h),
            (noise_func.call(p + Vector2(0, h)) - noise_func.call(p - Vector2(0, h))) / (2 * h)
        )
        var bin: int = int(grad.angle() / (TAU / 16) + 16) % 16
        angle_bins[bin] += 1
    # Compute variance across bins; lower is more isotropic
    var mean: float = float(samples) / 16
    var variance: float = 0.0
    for b in angle_bins: variance += (b - mean) * (b - mean)
    return variance / 16
```

Sample many gradient directions; bin by angle. Uniform bins mean isotropic; skewed bins mean axis bias.

Benchmark performance.

```gdscript
func benchmark(noise_func: Callable, samples: int) -> float:
    var start: int = Time.get_ticks_usec()
    for _i in samples:
        noise_func.call(Vector2(randf(), randf()))
    var elapsed: int = Time.get_ticks_usec() - start
    return float(elapsed) / samples
```

Microseconds per sample. Perlin is slightly faster in 2D; Simplex is faster in higher dimensions.

You can now sample Perlin and Simplex noise, compare them visually side by side, rotate to expose artifacts, measure isotropy, and benchmark performance. Lab_Path closes the sequence with the corridor template.

<<<MAP: Lab_Path>>>
# Lab Path

The corridor back. Shared template across every sequence.

Build the corridor.

```gdscript
class_name LabPath extends Node3D

@export var source_sequence: String = ""
@export var target_lab_state: String = ""

func _ready() -> void:
    build_corridor_geometry()
    place_ambient_sphere()
    place_teleporter()
    configure_lighting()
```

Four standard components. Every sequence's exit uses the same recipe.

Build corridor geometry.

```gdscript
func build_corridor_geometry() -> void:
    var floor := MeshInstance3D.new()
    floor.mesh = BoxMesh.new()
    floor.mesh.size = Vector3(5, 0.1, 5)
    floor.position = Vector3(2.5, -0.05, 2.5)
    add_child(floor)
    var ceiling := MeshInstance3D.new()
    ceiling.mesh = BoxMesh.new()
    ceiling.mesh.size = Vector3(5, 0.1, 5)
    ceiling.position = Vector3(2.5, 2.5, 2.5)
    add_child(ceiling)
```

5x5 floor and ceiling. Low-key; nothing draws attention.

Place the ambient sphere.

```gdscript
func place_ambient_sphere() -> void:
    var sphere := DARK_SPHERE_SCENE.instantiate()
    sphere.position = Vector3(2.5, 1.5, 2.5)
    add_child(sphere)
```

A slow-pulsing dark sphere at the centre. The only visual feature.

Place the teleporter.

```gdscript
func place_teleporter() -> void:
    var teleporter := TELEPORTER_SCENE.instantiate()
    teleporter.position = Vector3(2.5, 0, 4.5)
    teleporter.target = "res://commons/maps/Lab/map.tscn"
    teleporter.target_state = target_lab_state
    add_child(teleporter)
```

At the far end of the corridor. Entering returns the learner to the Lab.

Configure soft lighting.

```gdscript
func configure_lighting() -> void:
    var light := DirectionalLight3D.new()
    light.light_energy = 0.3
    light.rotation = Vector3(-0.5, 0.3, 0)
    add_child(light)
    var environment := WorldEnvironment.new()
    environment.environment = preload("res://commons/environments/lab_path.tres")
    add_child(environment)
```

Low-energy light, plus a shared environment resource. Consistent across every sequence's corridor.

Fade to black on exit.

```gdscript
func _on_teleporter_activated() -> void:
    var fade := ColorRect.new()
    fade.color = Color(0, 0, 0, 0)
    add_child(fade)
    var tween := create_tween()
    tween.tween_property(fade, "color:a", 1.0, 0.3)
    tween.tween_callback(func():
        get_tree().change_scene_to_file("res://commons/maps/Lab/map.tscn")
    )
```

Brief fade prevents cut-to-Lab. Eye-friendly transition.

Pass state to the Lab.

```gdscript
func prepare_handoff() -> void:
    GameState.last_sequence_completed = source_sequence
    GameState.lab_target_state = target_lab_state
```

The Lab reads the state to decide how to present itself. Different sequences complete differently.

You can now build the shared corridor, ambient sphere, teleporter with target state, soft lighting, and fade-to-black transition. Chamber_Noise extends into the chamber for the Noise sequence.

<<<MAP: Chamber_Noise>>>
# Chamber Noise

The only chamber without a creature. Sculpt terrain.

Build the parameter bench.

```gdscript
class_name NoiseParameterBench extends Node3D

@export var noise: FastNoiseLite

func expose_sliders() -> void:
    spawn_slider("frequency", 0.01, 1.0, noise.frequency)
    spawn_slider("amplitude", 0.1, 2.0, current_amplitude)
    spawn_slider("octaves", 1, 8, noise.fractal_octaves)
    spawn_slider("persistence", 0.1, 0.9, noise.fractal_gain)
    spawn_slider("displacement", 0.0, 2.0, current_displacement)
```

Five sliders for the most useful parameters. Each updates the terrain live.

Bind slider to parameter.

```gdscript
func _on_slider_changed(param_name: String, value: float) -> void:
    match param_name:
        "frequency": noise.frequency = value
        "amplitude": current_amplitude = value
        "octaves": noise.fractal_octaves = int(value)
        "persistence": noise.fractal_gain = value
        "displacement": current_displacement = value
    terrain.regenerate()
```

Slider callback updates the matching parameter; terrain regenerates.

Switch distributions.

```gdscript
enum Distribution { PERLIN, SIMPLEX, VALUE }

@export var distribution: Distribution = Distribution.PERLIN

func set_distribution(new_dist: Distribution) -> void:
    distribution = new_dist
    match distribution:
        Distribution.PERLIN: noise.noise_type = FastNoiseLite.TYPE_PERLIN
        Distribution.SIMPLEX: noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
        Distribution.VALUE: noise.noise_type = FastNoiseLite.TYPE_VALUE
    terrain.regenerate()
```

Three noise types. Each gives the ground a different grain.

Save a terrain.

```gdscript
var saved_terrains: Array = []

func save_current() -> void:
    var config: Dictionary = {
        "frequency": noise.frequency,
        "amplitude": current_amplitude,
        "octaves": noise.fractal_octaves,
        "persistence": noise.fractal_gain,
        "seed": noise.seed,
        "displacement": current_displacement,
        "distribution": distribution,
        "timestamp": Time.get_datetime_string_from_system(),
    }
    saved_terrains.append(config)
```

One entry per save. The gallery grows as the learner makes more terrains.

Load a terrain.

```gdscript
func load_terrain(index: int) -> void:
    var config: Dictionary = saved_terrains[index]
    noise.frequency = config.frequency
    noise.fractal_octaves = config.octaves
    noise.fractal_gain = config.persistence
    noise.seed = config.seed
    current_amplitude = config.amplitude
    current_displacement = config.displacement
    set_distribution(config.distribution)
    terrain.regenerate()
```

Sets every parameter from the saved config. The terrain instantly matches the saved shape.

Display science screen.

```gdscript
class_name NoiseScienceScreen extends Node3D

@export var bench: NoiseParameterBench

func update_display() -> void:
    render_2d_heatmap(bench.noise)
    render_heightmap_slice(bench.noise)
    render_parameter_list(bench.get_current_config())
```

Three views at once: 2D heatmap, 1D slice, parameter list. The terrain is readable as data.

You can now build a noise parameter bench with live sliders, switch distributions, save and load terrains, and display the results on a science screen. The Noise sequence hands the learner back to the Lab with the noise sculpting toolkit.
