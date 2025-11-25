extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Random Transformations[/b][/font_size][/center]
[center][i]Variation Through Geometry[/i][/center]

**100 identical trees look fake.** Randomize rotation, scale, color - suddenly unique.

**Transformations break uniformity** - same model, infinite variations.

[hr]

[b]Random Rotation[/b]

**Simplest transformation - just spin it:**

[color=yellow][b]Code: Y-Axis Rotation (Most Common)[/b][/color]
[code]
# Rotate around Y (up) axis - different facing direction
var tree = tree_scene.instantiate()
tree.position = spawn_position
tree.rotation.y = randf() * TAU  # Random 0-360 degrees

add_child(tree)

# Result: Tree faces random direction
# Breaks grid alignment, looks natural
[/code]

**Why Y-axis?** Objects usually upright - rotating X or Z would tip them over.

[color=yellow][b]Full 3D Rotation (Chaotic Objects)[/b][/color]
[code]
# Random rotation in all axes (debris, asteroids, floating items)
var debris = debris_scene.instantiate()
debris.position = spawn_position
debris.rotation = Vector3(
    randf() * TAU,
    randf() * TAU,
    randf() * TAU
)

add_child(debris)

# Result: Tumbling, no "up" direction
# Good for space debris, underwater objects
[/code]

[hr]

[b]Random Scale[/b]

**Make objects different sizes:**

[color=yellow][b]1. Uniform Scale (Keep Proportions)[/b][/color]
[code]
# Scale equally in all dimensions
var rock = rock_scene.instantiate()
rock.position = spawn_position

var scale_factor = randf_range(0.7, 1.5)  # 70% to 150% size
rock.scale = Vector3.ONE * scale_factor

add_child(rock)

# Result: Bigger/smaller, but same shape
[/code]

[color=yellow][b]2. Non-Uniform Scale (Squash/Stretch)[/b][/color]
[code]
# Scale differently per axis
var boulder = boulder_scene.instantiate()
boulder.position = spawn_position

boulder.scale = Vector3(
    randf_range(0.8, 1.2),  # X: width
    randf_range(0.9, 1.1),  # Y: height
    randf_range(0.8, 1.2)   # Z: depth
)

add_child(boulder)

# Result: Squashed, stretched, distorted
# More variation than uniform scale
[/code]

[color=yellow][b]3. Log-Normal Scale (Realistic Size Distribution)[/b][/color]
[code]
# Most small, few large (natural size distribution)
var tree = tree_scene.instantiate()
tree.position = spawn_position

var scale_factor = log_normal_random(0, 0.3)  # Mean 1.0, variation
scale_factor = clamp(scale_factor, 0.5, 2.0)
tree.scale = Vector3.ONE * scale_factor

add_child(tree)

# Result: Size varies like real trees (most medium, some huge)
[/code]

[hr]

[b]Random Color/Material[/b]

**Tint identical meshes for variety:**

[color=yellow][b]Code: Color Variation[/b][/color]
[code]
# Randomize hue while keeping saturation/value
var crystal = crystal_scene.instantiate()
crystal.position = spawn_position

var mesh_instance = crystal.get_node("MeshInstance3D")
var material = mesh_instance.get_surface_override_material(0).duplicate()

# Random hue, fixed saturation/value
var hue = randf()
var color = Color.from_hsv(hue, 0.8, 1.0)
material.albedo_color = color

mesh_instance.set_surface_override_material(0, material)
add_child(crystal)

# Result: Rainbow crystals from one model
[/code]

[color=yellow][b]Subtle Color Variation (Realistic)[/b][/color]
[code]
# Slight variation around base color
var base_color = Color(0.4, 0.6, 0.3)  # Green

var color_variation = Color(
    base_color.r + randf_range(-0.1, 0.1),
    base_color.g + randf_range(-0.1, 0.1),
    base_color.b + randf_range(-0.1, 0.1)
)

material.albedo_color = color_variation

# Result: Subtle greens, not identical
# Mimics natural color variation (leaves, rocks)
[/code]

[hr]

[b]Random UV Offset (Texture Variation)[/b]

**Same texture, different crops:**

[color=yellow][b]Code: UV Shifting[/b][/color]
[code]
shader_type spatial;

uniform sampler2D texture_albedo;
uniform vec2 uv_offset;  // Set randomly per instance

void fragment() {
    vec2 uv = UV + uv_offset;
    ALBEDO = texture(texture_albedo, uv).rgb;
}

# GDScript: Set random UV offset
var grass = grass_scene.instantiate()
var material = grass.get_node("MeshInstance3D").get_surface_override_material(0)

material.set_shader_parameter("uv_offset", Vector2(randf(), randf()))

add_child(grass)

# Result: Different part of texture visible
# Breaks tiling repetition
[/code]

[hr]

[b]Random Mesh Deformation[/b]

**Procedurally modify vertices:**

[color=yellow][b]Code: Vertex Noise[/b][/color]
[code]
# Deform mesh by adding noise to vertices
func randomize_mesh(mesh_instance: MeshInstance3D):
    var mesh = mesh_instance.mesh
    var arrays = mesh.surface_get_arrays(0)
    var vertices = arrays[Mesh.ARRAY_VERTEX]

    # Add noise to each vertex
    for i in range(vertices.size()):
        var vertex = vertices[i]
        var noise = Vector3(
            gaussian_random(0, 0.05),
            gaussian_random(0, 0.05),
            gaussian_random(0, 0.05)
        )
        vertices[i] = vertex + noise

    arrays[Mesh.ARRAY_VERTEX] = vertices

    # Create new mesh from modified arrays
    var new_mesh = ArrayMesh.new()
    new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    mesh_instance.mesh = new_mesh

# Result: Slightly warped, no two identical
# Good for organic shapes (rocks, plants)
[/code]

[hr]

[b]Random Shader Parameters[/b]

**Vary material properties procedurally:**

[color=yellow][b]Code: Randomized Shader Values[/b][/color]
[code]
# Different roughness, metallic, emission per object
var gem = gem_scene.instantiate()
var material = gem.get_node("MeshInstance3D").get_surface_override_material(0).duplicate()

# Randomize material properties
material.roughness = randf_range(0.1, 0.5)
material.metallic = randf_range(0.7, 1.0)

# Random emission (some gems glow)
if randf() < 0.2:  # 20% chance to glow
    material.emission_enabled = true
    material.emission = Color(randf(), randf(), randf())
    material.emission_energy = randf_range(1.0, 3.0)

gem.get_node("MeshInstance3D").set_surface_override_material(0, material)
add_child(gem)

# Result: Varied gems - some shiny, some glowing
[/code]

[hr]

[b]Random Animation Offset[/b]

**Desynchronize looping animations:**

[color=yellow][b]Code: Animation Time Offset[/b][/color]
[code]
# Start animation at random point in loop
var grass = animated_grass_scene.instantiate()
grass.position = spawn_position

var animation_player = grass.get_node("AnimationPlayer")
animation_player.play("sway")

# Seek to random time in animation
var animation_length = animation_player.get_animation("sway").length
animation_player.seek(randf() * animation_length)

add_child(grass)

# Result: Grass blades sway out of sync
# Breaks uniform wave motion
[/code]

[hr]

[b]Random Submodel Selection[/b]

**Hide/show parts of model randomly:**

[color=yellow][b]Code: Part Visibility[/b][/color]
[code]
# Model has multiple optional parts (branches, leaves, flowers)
var tree = tree_scene.instantiate()

# Randomly enable/disable branches
for i in range(tree.get_node("Branches").get_child_count()):
    var branch = tree.get_node("Branches").get_child(i)
    branch.visible = randf() < 0.7  # 70% chance each branch visible

# Randomly add flowers (20% chance)
if randf() < 0.2:
    tree.get_node("Flowers").visible = true

add_child(tree)

# Result: Same tree model, different configurations
# More variety than swapping entire models
[/code]

[hr]

[b]Breakable Object Randomization[/b]

**Pre-fractured debris with random breaks:**

[color=yellow][b]Code: Fracture Variation[/b][/color]
[code]
# When object breaks, spawn random debris
func spawn_debris(position: Vector3):
    var debris_count = randi_range(5, 15)

    for i in range(debris_count):
        var piece = debris_piece_scene.instantiate()
        piece.position = position

        # Random offset
        var offset = Vector3(
            randf_range(-1, 1),
            randf_range(0, 2),
            randf_range(-1, 1)
        )
        piece.position += offset

        # Random velocity (explosion)
        var velocity = offset.normalized() * randf_range(3, 8)
        piece.linear_velocity = velocity

        # Random angular velocity (tumbling)
        piece.angular_velocity = Vector3(
            randf_range(-10, 10),
            randf_range(-10, 10),
            randf_range(-10, 10)
        )

        # Random scale
        piece.scale = Vector3.ONE * randf_range(0.3, 1.0)

        add_child(piece)

# Result: Chaotic explosion, no two the same
[/code]

[hr]

[b]Weighted Variant Selection[/b]

**Choose from preset variations:**

[color=yellow][b]Code: Variant Pool[/b][/color]
[code]
var enemy_variants = [
    {"scene": enemy_basic, "weight": 50},
    {"scene": enemy_armored, "weight": 30},
    {"scene": enemy_fast, "weight": 15},
    {"scene": enemy_boss, "weight": 5},
]

func spawn_random_enemy(pos: Vector3):
    var total_weight = 0
    for variant in enemy_variants:
        total_weight += variant.weight

    var rand = randf() * total_weight
    var cumulative = 0.0

    for variant in enemy_variants:
        cumulative += variant.weight
        if rand < cumulative:
            var enemy = variant.scene.instantiate()
            enemy.position = pos

            # Still randomize transform
            enemy.rotation.y = randf() * TAU
            enemy.scale = Vector3.ONE * randf_range(0.9, 1.1)

            add_child(enemy)
            return

# Result: 50% basic, 30% armored, 15% fast, 5% boss
[/code]

[hr]

[b]Noise-Based Deformation[/b]

**Use 3D noise for organic warping:**

[color=yellow][b]Code: Perlin Vertex Displacement[/b][/color]
[code]
func deform_mesh_with_noise(mesh_instance: MeshInstance3D, strength: float):
    var mesh = mesh_instance.mesh
    var arrays = mesh.surface_get_arrays(0)
    var vertices = arrays[Mesh.ARRAY_VERTEX]
    var normals = arrays[Mesh.ARRAY_NORMAL]

    for i in range(vertices.size()):
        var vertex = vertices[i]
        var normal = normals[i]

        # Sample 3D Perlin noise at vertex position
        var noise = perlin_noise_3d(
            vertex.x * 2.0,
            vertex.y * 2.0,
            vertex.z * 2.0
        )

        # Displace along normal
        vertices[i] = vertex + normal * noise * strength

    arrays[Mesh.ARRAY_VERTEX] = vertices
    # Recalculate normals...
    var new_mesh = ArrayMesh.new()
    new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    mesh_instance.mesh = new_mesh

# Result: Organic bulges/dents
# Each instance uniquely deformed
[/code]

[hr]

[b]Combining Transformations[/b]

**Stack multiple randomizations:**

[color=yellow][b]Code: Full Randomization Pipeline[/b][/color]
[code]
func spawn_fully_random_object(scene: PackedScene, pos: Vector3):
    var obj = scene.instantiate()

    # Position (with slight offset)
    obj.position = pos + Vector3(
        randf_range(-0.5, 0.5),
        0,
        randf_range(-0.5, 0.5)
    )

    # Rotation (Y-axis only for upright objects)
    obj.rotation.y = randf() * TAU

    # Scale (log-normal distribution)
    var scale = log_normal_random(0, 0.2)
    scale = clamp(scale, 0.7, 1.4)
    obj.scale = Vector3.ONE * scale

    # Color (subtle variation)
    var material = obj.get_node("MeshInstance3D").get_surface_override_material(0).duplicate()
    var hue_shift = randf_range(-0.05, 0.05)
    var base_hue = 0.3  # Green
    material.albedo_color = Color.from_hsv(base_hue + hue_shift, 0.6, 0.8)

    obj.get_node("MeshInstance3D").set_surface_override_material(0, material)

    # Animation offset (if has AnimationPlayer)
    if obj.has_node("AnimationPlayer"):
        var anim = obj.get_node("AnimationPlayer")
        anim.seek(randf() * anim.get_animation(anim.assigned_animation).length)

    add_child(obj)

# Result: Maximum variation from single scene
[/code]

[hr]

[b]What Random Transformations Reveal[/b]

Random transformations show us:

1. **Rotation breaks alignment** - Y-axis for upright, full 3D for chaos
2. **Scale creates size hierarchy** - Log-normal mimics nature
3. **Color adds personality** - Hue shift or full random
4. **UV offset breaks tiling** - Same texture, different crop
5. **Mesh deformation is powerful** - Vertex noise = organic variation
6. **Shader params are cheap** - Roughness, metallic, emission
7. **Animation desync essential** - Offset prevents uniform motion
8. **Combine transformations** - Stack multiple for maximum variety
9. **Weighted selection** - Presets + randomization

**Transformations multiply content** - 1 model → 1000 unique instances.

**Randomness as anti-uniformity** - breaks monotony, creates naturalism.

[hr]

[color=cyan][b]Summary:[/b][/color]
Random transformations create variety from identical models. Rotation (Y-axis for upright, full 3D for tumbling). Scale (uniform/non-uniform/log-normal). Color tinting (hue shift, HSV variation). UV offset breaks texture repetition. Mesh deformation via vertex noise. Shader parameter randomization (roughness, metallic, emission). Animation time offset prevents sync. Submodel visibility (show/hide parts). Combine multiple transformations for maximum variation. Weighted variant selection from preset pool.

[hr]

[color=orange][b]Next:[/b] Glitch Aesthetics[/color]
If transformations create controlled variation, glitches embrace error - digital artifacts as artistic choice, corruption as texture, failure as feature.

'''
