# Continuous noise hardens into blocks on a three-dimensional sampling lattice

Noise_One stacked octaves into composite fields. Noise_Perlin_Simplex compared the algorithms that generate those fields. Both maps treated noise as a continuous function — a value at every point, smooth gradients between neighbors, no hard edges. The output was always a float. This map introduces the operation that turns floats into worlds: thresholding. A single comparison — `noise(x, y, z) > T` — collapses the continuous gradient into a binary decision. Solid or void. Block or air. The voxel grid is the spatial container for that decision, repeated at every cell of a regular lattice. The result is architecture that no heightmap can produce: caves, overhangs, floating islands, interior volumes. Discretization is where noise stops being a texture and starts being a place.

## The Voxel Grid as Sampling Lattice

A voxel is a volume element — the three-dimensional analog of a pixel. Where a pixel samples a 2D image at a regular point, a voxel samples a 3D field at a regular cell. The grid is uniform: every cell is the same size, spaced at equal intervals along x, y, and z. The `perlin_terrain_sculptor` defines this lattice explicitly:

```gdscript
@export var grid_size: int = 24
@export var voxel_size: float = 0.04
```

A 24x24x24 grid. Each cell occupies 0.04 units on a side. The total volume: 13,824 cells, each one a yes-or-no answer to the question "is there solid here?" The grid does not know about noise. It does not know about terrain. It is a container of boolean decisions arranged in space. What fills those decisions is a separate concern.

The distinction matters. The grid is the resolution — how finely space gets carved. The noise function is the content — what pattern of solid and void fills the grid. Change the grid size without changing the noise, and the same terrain appears at different fidelity. Change the noise without changing the grid, and the same resolution captures different terrain. Resolution and content are independent. Confusing them is the first mistake of voxel generation.

The `voxelnoise` artifact scales this up dramatically:

```gdscript
@export var chunk_size: int = 32
@export var world_height: int = 64
@export var voxel_scale: float = 1.0
```

Thirty-two by sixty-four by thirty-two cells per chunk, each cell one unit wide. The lattice is coarser but the volume is vastly larger. The visual consequence: blocky terrain at human scale, the Minecraft aesthetic that makes discretization culturally legible. Block size is a design decision that determines the granularity of the world. Smaller voxels approach smoothness. Larger voxels announce their grid.

The grid also defines the coordinate system of the world. Voxel (5, 12, 8) refers to a specific cell in the lattice. Integer coordinates. No fractions, no ambiguity, no floating-point drift. The noise function operates in continuous coordinates. The grid snaps those coordinates to discrete addresses. The mapping from `Vector3(5.37, 12.01, 8.94)` to cell `[5][12][8]` is the floor function applied per axis — the first act of quantization, before the threshold even enters the picture.

## Evaluating Noise in Three Dimensions

Previous maps in the sequence evaluated noise in two dimensions — `get_noise_2d(x, z)` returning a height at each point on a plane. A heightmap. One value per column, no overhangs possible, no caves, no floating geometry. The constraint is topological: a 2D noise function maps each (x, z) coordinate to exactly one height, producing a surface that never folds back on itself.

Three-dimensional noise removes that constraint. `get_noise_3d(x, y, z)` returns a value at every point in a volume, not just on a surface. The noise field fills space the way temperature fills a room — varying in every direction, no privileged axis:

```gdscript
func _generate_terrain():
    var half = grid_size / 2.0
    for x in range(grid_size):
        for y in range(grid_size):
            for z in range(grid_size):
                var wx = (x - half) * voxel_size
                var wy = (y - half) * voxel_size
                var wz = (z - half) * voxel_size
                var n = _noise.get_noise_3d(wx * 10, wy * 10, wz * 10)
```

Three nested loops. Every cell in the grid gets a noise value. The coordinates are centered — `(x - half)` shifts the grid so the origin sits at the center rather than the corner. The `* 10` factor scales the coordinates fed to the noise function, controlling how quickly the noise varies across the grid. Larger scale factors compress more noise variation into the same physical space. Smaller factors stretch it out.

The triple loop is the computational cost of volumetric noise. A 24x24x24 grid requires 13,824 noise evaluations. A 32x64x32 grid requires 65,536. Double the grid size along each axis and the count grows by a factor of eight — cubic scaling. The third dimension is expensive. This is why voxel worlds use chunks, LOD, and deferred generation. The mathematics is simple. The budget is not.

## The Threshold: Continuous to Discrete

The threshold is a single floating-point number that cleaves the continuous noise field into binary territory:

```gdscript
@export var threshold: float = 0.0:
    set(value):
        threshold = clampf(value, -1.0, 1.0)
        _generate_terrain()
```

Perlin noise returns values in the range roughly [-1, 1]. The threshold sits somewhere in that range. Every cell where the noise value exceeds the threshold becomes solid. Every cell where it falls below becomes void:

```gdscript
_voxels[x][y][z] = n - height_bias > threshold
```

One comparison per cell. The continuous gradient — all its subtle variation, its smooth transitions, its organic curvature — collapses into a single bit. This is information destruction. The noise field at a given cell might be 0.003 above threshold or 0.8 above threshold, and the result is the same: solid. The magnitude of "how solid" vanishes. Only the side of the boundary survives.

Raise the threshold and more cells fall below it — the terrain hollows out, erodes, fragments into floating shards. Lower the threshold and more cells qualify as solid — caves fill in, gaps close, the volume densifies toward a solid cube. At threshold -1.0, everything is solid. At threshold 1.0, everything is void. Between those extremes, the threshold carves topology from the noise field like a water level carving coastline from elevation data.

The `perlin_terrain_sculptor` makes this interactive. VR sliders map normalized [0, 1] positions to the threshold range:

```gdscript
func _on_threshold_slider_moved(_position):
    if _threshold_slider and _threshold_slider.has_method("get_normalized_value"):
        var norm = _threshold_slider.get_normalized_value()
        threshold = norm * 2.0 - 1.0
```

Slide left: threshold drops, terrain fills. Slide right: threshold rises, terrain dissolves. The learner watches a single parameter reshape the world in real time. The noise field itself never changes — only the line drawn through it. Every threshold value produces a different world from the same underlying function. The terrain is not in the noise. It is in the cut.

## Height Bias: Breaking Isotropy

Pure 3D noise is isotropic — it has no preferred direction. Caves and tunnels form equally in x, y, and z. Floating islands appear at every elevation. The result looks interesting but not like terrain. Real terrain has gravity. The ground is down. The sky is up. Something must break the symmetry.

The `perlin_terrain_sculptor` introduces a height bias:

```gdscript
var height_bias = (float(y) / grid_size - 0.5) * 0.5
_voxels[x][y][z] = n - height_bias > threshold
```

The bias is a linear function of y. At the bottom of the grid (`y = 0`), the bias is -0.25 — it subtracts from the noise value, making it harder to exceed the threshold, which means... wait. The subtraction works the other way. Subtracting a negative bias _adds_ to the effective noise value, making lower cells more likely to be solid. At the top (`y = grid_size`), the bias is +0.25, subtracting from the noise, making upper cells more likely to be void.

The effect: a vertical density gradient. Dense below, sparse above. Ground at the bottom, air at the top, and a transition zone in the middle where noise still dominates — producing the caves, overhangs, and shelves that make voxel terrain interesting. The bias does not replace the noise. It tilts the playing field so the noise produces terrain-shaped results rather than isotropic foam.

This is the minimal intervention that converts a mathematical curiosity into a recognizable landscape. One line of arithmetic. The difference between "random 3D structure" and "something that feels like ground."

The bias is linear, which means the density gradient is uniform — the transition from solid to void happens at the same rate everywhere. A quadratic bias would create sharper ground boundaries and thinner sky boundaries. An exponential bias would concentrate nearly all solid matter at the very bottom. The linear choice is the simplest that works. More complex biases produce more specific terrain profiles, but the principle remains: multiply the noise by some function of height, and the isotropic field develops a horizon.

## MultiMesh: Rendering Thousands of Blocks

A 24x24x24 grid can produce up to 13,824 visible cubes. Creating a separate `MeshInstance3D` for each one would bury the renderer under draw calls. The `perlin_terrain_sculptor` uses Godot's `MultiMesh` — a single draw call that stamps the same mesh at thousands of positions:

```gdscript
func _create_multimesh():
    _multimesh = MultiMesh.new()
    _multimesh.transform_format = MultiMesh.TRANSFORM_3D
    _multimesh.use_colors = true

    var max_voxels = grid_size * grid_size * grid_size
    _multimesh.instance_count = max_voxels
    _multimesh.visible_instance_count = 0

    var box = BoxMesh.new()
    box.size = Vector3.ONE * voxel_size * 0.95
```

The instance count is preallocated to the maximum — every cell could be solid. The `visible_instance_count` starts at zero and gets set during terrain generation to the actual number of active voxels. The box size is 95% of the voxel size, leaving slim gaps between cubes — a visual decision that makes the grid legible. Without the gaps, adjacent cubes merge into featureless slabs. The 5% margin preserves the voxel identity of each cell.

Rebuilding the mesh packs active voxels into the MultiMesh sequentially:

```gdscript
func _rebuild_multimesh():
    var half = grid_size / 2.0
    var idx = 0
    for x in range(grid_size):
        for y in range(grid_size):
            for z in range(grid_size):
                if _voxels[x][y][z]:
                    var pos = Vector3(
                        (x - half + 0.5) * voxel_size,
                        (y - half + 0.5) * voxel_size,
                        (z - half + 0.5) * voxel_size
                    )
                    var transform = Transform3D()
                    transform.origin = pos
                    _multimesh.set_instance_transform(idx, transform)
```

The `+ 0.5` offset centers each cube within its grid cell rather than placing it at the cell corner. Every active voxel gets a transform (position in space) and a color. The color introduces a height gradient — lower voxels tint green, upper voxels shift toward pale blue:

```gdscript
if height_gradient:
    var t = float(y) / grid_size
    color = voxel_color.lerp(Color(0.8, 0.9, 1.0), t * 0.5)
```

The `t` parameter normalizes y to [0, 1]. The `lerp` blends between the base voxel color and a pale sky tone. The `* 0.5` caps the blend at 50%, so even the highest voxels retain some of the base color. The gradient is cosmetic — it encodes no data — but it reinforces the height bias visually. Denser ground reads dark. Sparse sky reads light. The color mirrors the structure.

## The SurfaceTool Path: Building Geometry from Scratch

The `voxelnoise` artifact takes a different approach. Instead of stamping premade boxes through MultiMesh, it constructs raw triangle geometry using `SurfaceTool`:

```gdscript
func _generate_chunk(chunk_pos: Vector3i):
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    for x in range(chunk_size):
        for y in range(1, world_height + 1):
            for z in range(chunk_size):
                var world_x = chunk_pos.x * chunk_size + x + generation_offset.x
                var world_y = y + generation_offset.y
                var world_z = chunk_pos.z * chunk_size + z + generation_offset.z

                var p = Vector3(world_x, world_y, world_z)
                var val = noise.get_noise_3d(p.x, p.y, p.z)

                if val > iso_level:
                    _add_cube(st, p * voxel_scale)
```

The `_add_cube` function writes twelve triangles (six faces, two triangles each) per voxel directly into the SurfaceTool buffer:

```gdscript
func _add_cube(st: SurfaceTool, pos: Vector3):
    var s = voxel_scale * 0.5
    var verts = [
        Vector3(-s, -s, -s), Vector3(s, -s, -s),
        Vector3(s,  s, -s), Vector3(-s,  s, -s),
        Vector3(-s, -s,  s), Vector3(s, -s,  s),
        Vector3(s,  s,  s), Vector3(-s,  s,  s)
    ]
```

Eight vertices define the cube corners. Thirty-six indices (twelve triangles) wire them into faces. This is the brute-force approach — no instancing, no shared geometry, every cube's vertices are unique in the mesh buffer. The advantage: a single committed `ArrayMesh` that can receive a custom shader. The disadvantage: enormous vertex counts. A 32x64x32 chunk with 50% fill rate produces roughly 32,000 cubes, each with 36 vertices — over a million vertices per chunk.

The shader applied to this mesh uses barycentric coordinates for wireframe-style edge detection:

```gdscript
void fragment() {
    vec3 d = fwidth(barycentric);
    vec3 a3 = smoothstep(vec3(0.0), d * outline_width, barycentric);
    float edge = 1.0 - min(min(a3.x, a3.y), a3.z);
    vec3 color = mix(glass_color.rgb, outline_color.rgb, edge);
```

The `fwidth` function measures how quickly the barycentric coordinates change across the fragment — screen-space derivatives that produce consistent-width edges regardless of distance. The `smoothstep` fades from edge to interior. The result: translucent blue faces with glowing pink wireframe edges, making the triangulation visible. The grid structure announces itself. Every cube displays its six faces, twelve triangles, twenty-four edges. The voxel is not hidden behind smooth shading. It is the aesthetic.

Two rendering strategies for the same data. MultiMesh optimizes draw calls at the cost of per-instance flexibility. SurfaceTool optimizes shader access at the cost of vertex count. The sculptor uses MultiMesh because interactive speed matters — threshold changes must feel immediate. The world uses SurfaceTool because visual richness matters — the wireframe shader demands per-triangle data. The choice is architectural, not incidental.

## Linking Artifacts: Sculptor Drives World

The two artifacts communicate. The `perlin_terrain_sculptor` — the small interactive model — broadcasts its parameters to the `voxelnoise` world-scale terrain:

```gdscript
func _broadcast_controls_to_voxelnoise() -> void:
    var payload: Dictionary = _build_voxelnoise_payload()
    terrain_controls_changed.emit(payload)
    if get_tree():
        get_tree().call_group("voxelnoise_receivers",
            "apply_perlin_terrain_controls", payload)
```

The payload contains threshold, scale, octave count, and seed. The `voxelnoise` artifact listens via group membership:

```gdscript
func _ready():
    add_to_group("voxelnoise_receivers")
```

When controls change on the sculptor, the world rebuilds. The sculptor is the control surface. The world is the consequence. Adjusting threshold on the small model and watching the large terrain reshape teaches something textbooks cannot: that the parameter space of voxel generation is navigable. The threshold is not a number to get right once. It is a dimension to explore continuously.

The frequency mapping between the two artifacts is not one-to-one:

```gdscript
var mapped_frequency: float = lerpf(linked_frequency_min, linked_frequency_max, scale_norm)
```

The sculptor's noise scale normalizes to [0, 1], then maps to the world's frequency range — from 0.005 to 0.18. The world needs different absolute frequencies because its coordinate space is different. The sculptor works in centimeter-scale voxels; the world works in meter-scale chunks. The parameter mapping bridges those scales while preserving perceptual correspondence. Turn the sculptor's scale up, and both terrains get noisier in tandem.

## What Discretization Destroys

Every voxel boundary is a lie. The noise field transitions smoothly from 0.49 to 0.51 across a cell boundary. The threshold at 0.5 places a hard edge exactly there — solid on one side, void on the other. But the actual noise gradient is gentle. The surface implied by the noise field is not blocky. It curves. The voxel grid forces that curve into right angles.

This is the information cost of discretization. The continuous field contains infinite resolution. The voxel grid samples it at finite intervals and throws away everything between samples. Marching Cubes — the algorithm that converts voxel fields into smooth meshes — recovers some of that lost curvature by interpolating along cell edges. This map does not use Marching Cubes. It uses raw voxels. The blockiness is the point. It makes the sampling lattice visible, the discretization tangible, the information loss undeniable.

The dark_sphere sits in this map as the unvoxelized constant — continuous geometry amid discretized space. Its surface is smooth. Its emission pulses along a continuous sine wave. It belongs to the world before the threshold, where every value between 0 and 1 still exists. The terrain surrounding it has been reduced to binary. The contrast is the lesson.

Thresholding is an act of decision. Where does solid end and void begin? The answer is arbitrary — a parameter on a slider — yet the resulting topology feels natural. Caves form where noise dips below the cut. Overhangs emerge where the bias tilts the field. Floating islands persist where isolated pockets of high noise survive above the threshold. None of these features are designed. They are the emergent consequence of a smooth function meeting a sharp boundary. Structured disorder producing spaces that appear inevitable despite depending entirely on a number someone chose. Noise_6_Wall takes this further — moving the threshold logic into shaders, where discretization happens per-pixel rather than per-voxel, and the lattice finally disappears.

## Possible Artifacts

**noise_cross_section** — A planar slice through the 3D noise field rendered as a color gradient, showing the continuous values before thresholding. The slice position adjustable along each axis. Overlays the threshold as a contour line, making visible exactly where the binary decision falls and how much gradient information the voxelization discards. Reveals the hidden smoothness beneath every sharp voxel edge — the continuous world that thresholding erases.

**density_histogram** — A real-time histogram of noise values across the entire grid, with the threshold marked as a vertical line. As the threshold slider moves, the learner sees what fraction of the volume is solid versus void, and how the distribution of noise values determines the sensitivity of terrain to small threshold changes. Flat distributions produce gradual transitions; peaked distributions produce sudden phase changes where a small slider movement flips thousands of voxels.

**resolution_comparator** — The same noise field sampled at three grid resolutions side by side — 8x8x8, 16x16x16, 32x32x32. Same noise parameters, same threshold, different lattice density. Demonstrates that resolution and content are independent and shows exactly where fine details appear and vanish as the sampling interval changes. The coarse grid misses narrow caves that the fine grid preserves. The noise field contains them all. Only the lattice decides which survive.
