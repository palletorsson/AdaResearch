# Classical columns dissolve under coherent displacement, revealing that noise sculpts geometry the way a chisel sculpts marble — by remembering where it has already cut

Noise_Perlin_Simplex established two algorithms as competing lattice geometries — hypercubes versus simplices, axis-aligned artifacts versus isotropic output. That map compared noise functions in isolation: raw outputs, side-by-side terrains, diagnostic contrast. The noise remained flat. A texture. A color on a plane.

This map applies noise to form. A column stands in space — perfect cylindrical geometry, vertices arranged in regular rings, normals pointing radially outward. Then a 3D Perlin noise field displaces every vertex, and the column melts. Not shatters. Not explodes. Melts. Adjacent vertices receive similar displacements because the noise is coherent — the field varies smoothly through space, and nearby points in space sample nearby values in the field. The column's geometry deforms continuously, preserving topology while destroying symmetry.

Reverse the field, and the column reconstitutes. No information was lost. The noise was not destruction. It was sculpture.

The transition from comparing algorithms to applying them is the transition from understanding a tool to using it. Random_Noise_Types introduced the spectrum. Noise_Perlin_Simplex opened the algorithmic box. Noise_Columns puts the tool in the learner's hand.

## Vertex Displacement: Noise as Force

Every mesh in Godot is a collection of vertices — points in 3D space connected by edges into triangles. A cylinder mesh has vertices arranged in rings stacked along an axis. Each vertex has a position and a normal — the position says where the vertex sits, the normal says which direction the surface faces at that point.

Vertex displacement moves each vertex along some direction by some amount. The simplest version: displace along the normal.

```gdscript
# Displace a single vertex along its normal by a noise-derived amount
func displace_vertex(pos: Vector3, normal: Vector3,
                     noise: FastNoiseLite, strength: float) -> Vector3:
    var noise_value := noise.get_noise_3d(pos.x, pos.y, pos.z)
    return pos + normal * noise_value * strength
```

The noise function takes three coordinates and returns a scalar in the range [-1, 1]. Multiply by the normal to get a direction. Multiply by strength to control amplitude. Add to the original position. The vertex moves outward (positive noise) or inward (negative noise) along the surface direction.

This operation happens per vertex. Every vertex samples the noise field at its own position, receives its own displacement value, moves its own distance. The mesh deforms as a whole because the displacements are spatially coherent — the noise field ensures that neighboring vertices get similar values.

```gdscript
# Apply displacement to an entire mesh
func apply_noise_displacement(mesh_data: MeshDataTool,
                              noise: FastNoiseLite,
                              strength: float) -> void:
    for i in range(mesh_data.get_vertex_count()):
        var pos := mesh_data.get_vertex(i)
        var normal := mesh_data.get_vertex_normal(i)
        var displaced := displace_vertex(pos, normal, noise, strength)
        mesh_data.set_vertex(i, displaced)
```

The loop is the entire operation. No branching, no special cases. Every vertex undergoes the same transformation: sample, scale, offset. The MeltingBerniniScene artifact wraps this loop in an animation system that interpolates the strength parameter from 0.0 (pristine column) to 1.0 (full dissolution) and back.

## Coherent Fields: Why It Melts Instead of Shatters

The word "coherent" carries the full weight of the difference between noise as sculpture and noise as destruction.

White noise — the kind Random_Noise_Types introduced as the null condition — assigns independent values to each sample point. Applied as vertex displacement, white noise moves each vertex by an unrelated amount. The mesh shatters into a cloud of disconnected spikes. Triangles stretch to absurd aspect ratios. The surface ceases to be a surface.

Perlin noise assigns correlated values. Two vertices one unit apart in space receive noise values that differ by at most some bounded amount determined by the frequency parameter. The lower the frequency, the more slowly the noise varies, the more similar nearby vertices' displacements become.

At very low frequency the entire column shifts uniformly — displacement without deformation. At very high frequency the correlation distance shrinks below the vertex spacing and the result approaches white noise again.

The useful range sits between these extremes. The frequency where coherent deformation produces organic-looking distortion — where the column appears to soften and flow rather than crumble — depends on the mesh resolution and the physical scale of the geometry.

```gdscript
# Configure the noise field for sculptural displacement
var noise := FastNoiseLite.new()
noise.noise_type = FastNoiseLite.TYPE_PERLIN
noise.seed = 42
noise.frequency = 0.8  # Controls the spatial scale of deformation
```

The frequency parameter is the inverse of feature size. A frequency of 0.8 means features repeat roughly every 1.25 units. On a column two meters tall with 32 vertical rings of vertices, this produces several lobes of inward and outward displacement along the height — enough variation to read as organic distortion, not enough to dissolve the form into incoherence.

The F term in QFEP maps here: frequency is a fixed structural parameter that determines the character of the deformation before any randomness enters. Change the frequency and the sculpture changes genre — low frequency produces gentle undulation, high frequency produces aggressive texturing, very high frequency produces noise-floor static.

The same noise seed, the same algorithm, radically different aesthetics, governed by one scalar.

## The Noise Field as 3D Volume

A critical conceptual shift happens in this map. Previous encounters with noise treated it as a 2D function — sample at (x, z), receive a height value, extrude vertically. The blurb describes this: noise extruded into columns, terrain as a height field, walking through the function.

The MeltingBerniniScene requires 3D noise. The column exists in three-dimensional space. Its vertices have x, y, and z coordinates, and the displacement must vary in all three directions.

A vertex at the top of the column and a vertex at the bottom occupy different positions in the noise field even if they share the same x and z. The noise value at (2.0, 0.0, 3.0) differs from the noise value at (2.0, 5.0, 3.0) — the y coordinate matters.

```gdscript
# 2D noise: height field (previous maps)
var height := noise.get_noise_2d(world_x, world_z)

# 3D noise: volumetric displacement (this map)
var displacement := noise.get_noise_3d(pos.x, pos.y, pos.z)
```

The difference is dimensional. The 2D function maps a plane to a scalar — every point on the ground gets one value, and that value becomes height. The 3D function maps a volume to a scalar — every point in space gets one value, and that value becomes displacement magnitude.

The 2D function cannot vary along the vertical axis. The 3D function can. This is why the column develops different distortion patterns at different heights, why the melting looks organic rather than extruded.

The jump from `get_noise_2d` to `get_noise_3d` adds one coordinate and one lattice dimension. For Perlin noise this doubles the corner evaluations per sample — from 4 to 8. For Simplex it adds one — from 3 to 4. The computational cost increase is real but the expressive gain is larger. Three-dimensional noise fields encode volumetric variation that no height map can represent.

## Reversibility: Entropy That Remembers

The melting animation runs forward and backward. The column dissolves, then reconstitutes. This is not a visual trick or a keyframe animation — the reconstitution works because the noise field is deterministic. Given the same seed, the same frequency, the same coordinates, `get_noise_3d` returns the same value every time. The displacement is a pure function of position and parameters.

```gdscript
# Animate dissolution and reconstitution
func _process(delta: float) -> void:
    _time += delta * animation_speed
    var t := (sin(_time) + 1.0) * 0.5  # Oscillates 0 to 1
    var current_strength := t * max_displacement
    apply_noise_displacement(_mesh_data, _noise, current_strength)
    _commit_mesh()
```

At `t = 0`, strength is zero. Every vertex sits at its original position. The column is perfect. At `t = 1`, strength is maximal. Every vertex has been displaced by its full noise-derived offset. The column is maximally deformed.

At every intermediate value, the column exists in a state between order and dissolution — partially melted, partially intact. The sine function drives t smoothly through this range, and the column breathes.

The reversibility demonstrates a property of coherent noise that white noise lacks: bijectivity under smooth deformation. The noise-based displacement is a continuous mapping from the original mesh to the deformed mesh. Continuous mappings that don't fold the surface onto itself are invertible — subtract the displacement to return to the origin.

White noise displacement can fold surfaces by moving adjacent vertices past each other, creating self-intersections that destroy the topology. Coherent noise at appropriate frequency preserves the mesh structure because the displacement field varies slowly enough that no vertex crosses its neighbor's path.

The E term in QFEP measures the entropy introduced by the noise field. But this entropy is structured — it has spatial correlation, bounded variation, and deterministic repeatability. The deformation looks random but is fully recoverable. The column's memory of its original form is encoded in the noise seed and the reversibility of the displacement operation.

## Normal-Aligned Versus Directional Displacement

Displacing along normals is the default sculptural approach, but not the only one. The normal-aligned method pushes vertices perpendicular to the surface — outward or inward. This preserves the overall silhouette proportions while adding surface texture. A column stays roughly cylindrical but gains bumps and dents.

An alternative: displace along a fixed world-space direction.

```gdscript
# Displacement along world Y axis instead of normals
func displace_vertical(pos: Vector3, noise: FastNoiseLite,
                       strength: float) -> Vector3:
    var noise_value := noise.get_noise_3d(pos.x, pos.y, pos.z)
    return pos + Vector3.UP * noise_value * strength
```

Vertical displacement stretches and compresses the column along its height. Vertices shift up or down without moving laterally. The result looks like the column is being squeezed by invisible hands — compression zones alternate with expansion zones along the height.

A third option: displace along a vector derived from the noise field itself. Sample the noise three times at offset positions to construct a displacement vector.

```gdscript
# Vector-valued displacement from three noise samples
func displace_vector_field(pos: Vector3, noise: FastNoiseLite,
                           strength: float) -> Vector3:
    var dx := noise.get_noise_3d(pos.x, pos.y, pos.z)
    var dy := noise.get_noise_3d(pos.x + 100.0, pos.y + 100.0, pos.z)
    var dz := noise.get_noise_3d(pos.x, pos.y + 100.0, pos.z + 100.0)
    return pos + Vector3(dx, dy, dz) * strength
```

The offsets (100.0) ensure the three samples come from uncorrelated regions of the same noise field — distant enough that their values bear no spatial relationship. Each axis of displacement is independently determined.

The result is a fully three-dimensional deformation: the column twists, bends, and warps in all directions simultaneously.

The MeltingBerniniScene uses normal-aligned displacement as its primary mode. The Bernini reference is deliberate — marble sculpture reveals form by removing material along the surface direction. The noise does the same: it carves inward and pushes outward along the surface, sculpting the cylinder the way a chisel follows the grain of stone.

## Mesh Resolution and Displacement Fidelity

Vertex displacement can only deform geometry at the resolution of the mesh. A cylinder with 8 radial segments and 4 height rings has 32 vertices — the noise can create at most 32 distinct displacements. Fine noise detail below the vertex spacing is invisible.

The mesh acts as a spatial sampling grid, and the Nyquist limit applies: noise features smaller than twice the vertex spacing alias into lower-frequency artifacts or vanish entirely.

```gdscript
# Column mesh construction with configurable resolution
func create_column(radius: float, height: float,
                   radial_segments: int, rings: int) -> ArrayMesh:
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius
    cylinder.height = height
    cylinder.radial_segments = radial_segments
    cylinder.rings = rings
    return cylinder.get_mesh()
```

Increase `radial_segments` and `rings` to capture finer noise detail. A column with 64 radial segments and 128 rings has 8,192 vertices — enough to represent noise features down to roughly 1.5 centimeters on a 2-meter column.

The cost is proportional: more vertices mean more noise evaluations per frame during animation.

The phi term in QFEP quantifies this tradeoff. Increasing mesh resolution costs energy — computation time, memory, draw calls. The return is higher-fidelity deformation. At some point the added vertices capture noise detail finer than the eye can resolve at the expected viewing distance, and additional resolution wastes energy without improving perceived quality.

The optimal resolution depends on the noise frequency, the viewing distance, and the target framerate. No universal answer exists. The designer tunes the parameters.

## Caching Original Positions: The Memory Pattern

Real-time deformation requires a discipline that static displacement does not. Each animation frame must compute displacement from the original vertex positions, not from the already-displaced positions of the previous frame. Without this invariant, displacements accumulate — each frame pushing vertices further from their origins, the mesh drifting into collapse.

```gdscript
var _original_positions: PackedVector3Array = []

func _store_original_positions() -> void:
    _original_positions.clear()
    for i in range(_mesh_data.get_vertex_count()):
        _original_positions.append(_mesh_data.get_vertex(i))
```

The `_original_positions` array is the mesh's memory. It records every vertex's birthplace before any noise touches it.

The array is written once, during `_ready`, and read every frame during `_process`.

```gdscript
func _apply_displacement(strength: float) -> void:
    for i in range(_mesh_data.get_vertex_count()):
        var original := _original_positions[i]
        var normal := _mesh_data.get_vertex_normal(i)
        var displaced := displace_vertex(original, normal, _noise, strength)
        _mesh_data.set_vertex(i, displaced)
```

The pattern — cache, restore, transform — recurs throughout real-time mesh deformation. It separates the base geometry (the Q of the original form) from the deformation (the E of the noise field). The base geometry encodes design intent. The deformation encodes procedural variation.

Keeping them separate means either can change independently: swap the mesh and keep the noise, or swap the noise and keep the mesh.

The full initialization pipeline connects these pieces:

```gdscript
func _ready() -> void:
    _mesh = create_column(0.4, 3.0, 48, 96)
    _mesh_data = MeshDataTool.new()
    _mesh_data.create_from_surface(_mesh, 0)
    _store_original_positions()

    _noise = FastNoiseLite.new()
    _noise.noise_type = FastNoiseLite.TYPE_PERLIN
    _noise.seed = randi()
    _noise.frequency = 0.8
```

A column 0.4 meters in radius, 3 meters tall, with 48 radial segments and 96 height rings. A Perlin noise field with a random seed and a frequency tuned to the column's scale.

The seed is random — each session produces a different sculpture. The frequency is fixed — the character of the deformation stays consistent. The P term in QFEP is the learner's path through these variations: same structure, different entropy, recognizing the invariant under surface change.

## From Flat Noise to Volumetric Sculpture

The progression across noise maps follows a dimensional ladder. Random_Noise_Types introduced noise as 1D signals — waveforms with spectral color. Noise_Perlin_Simplex compared algorithms using 2D noise as flat textures and height fields. This map crosses into 3D: noise as a volumetric field that deforms solid geometry.

The column itself embodies the extrusion metaphor from the blurb. A cylinder is a circle extruded along an axis — 2D cross-section lifted into 3D form. The noise displacement takes that 3D form and sculpts it using a 3D function. The input is spatial. The output is spatial. The noise lives in the same dimensional space as the geometry it deforms.

The dark_sphere sits untouched in the map space while the columns melt around it. Its geometry is pristine — no noise displacement, no deformation, no dissolution. It is the control surface. The constant against which the variable (the melting column) is measured.

The sphere proves that the noise field is selective: applied to the column's vertices, not to all geometry indiscriminately. The sculptor chooses what to carve.

The Bernini reference carries technical weight beyond metaphor. Bernini did not shatter marble. He carved along continuous surfaces, following the logic of flesh and fabric through a rigid medium. The coherent noise field displaces along continuous surfaces, following the logic of the noise function through a rigid mesh.

Both preserve topology. Both create the impression of softness from hard structure. Both are reversible in principle — the marble that became Daphne's fingers was never destroyed, only relocated.

What follows in the sequence is Noise_One, where octave layering stacks multiple noise passes at different frequencies and amplitudes. This map demonstrates what a single noise field does to geometry — one frequency, one amplitude sweep, one displacement direction. Noise_One asks what happens when several fields combine. The answer requires understanding the single field first, and understanding it means watching marble melt.

## Possible Artifacts

**coherence_comparator** — Two identical columns side by side, one displaced by white noise, the other by Perlin noise at the same amplitude. The white-noise column shatters into a spiky mess of inverted triangles and stretched faces. The Perlin column melts smoothly, surface continuous, silhouette readable. A slider controls displacement strength from zero to maximum; at zero both columns are identical, at maximum the structural difference between incoherent and coherent noise is visceral. Directly addresses the gap identified in the intent — crystallizing why coherence matters as the difference between destruction and sculpture.

**frequency_sculptor** — A single column with a real-time frequency slider on the noise field. At frequency 0.1 the column gently bows and tilts as a whole — features larger than the mesh. At 0.5 broad lobes appear, pushing the column into an organic undulating form. At 2.0 the surface develops fine pockmarks and ridges. At 8.0 the displacement approaches per-vertex independence and the surface roughens toward noise-floor static. The slider makes the relationship between frequency and deformation character kinetic rather than conceptual — the learner feels the parameter.

**displacement_mode_selector** — Toggles the displacement direction between normal-aligned, vertical, and vector-field modes on the same column with the same noise seed. Normal displacement produces Bernini-style surface sculpting. Vertical displacement produces compression-and-stretch bands. Vector-field displacement produces full 3D warping and twisting. The same noise, the same mesh, three radically different deformations — demonstrating that the displacement direction is as consequential as the noise function itself.
