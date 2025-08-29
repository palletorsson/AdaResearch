# ColoredLinesVR.gd
# A mesmerizing VR scene with dynamic, flowing colored lines weaving through 3D space
extends Node3D

@export var line_count: int = 25
@export var points_per_line: int = 100
@export var animation_speed: float = 1.0
@export var line_length: float = 15.0
@export var flow_speed: float = 2.0

var line_meshes: Array[MeshInstance3D] = []
var line_materials: Array[ShaderMaterial] = []
var line_paths: Array[Array] = []

# Custom line shader for flowing colors and effects
const LINE_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform float time_offset : hint_range(0.0, 10.0) = 0.0;
uniform float flow_speed : hint_range(0.5, 5.0) = 2.0;
uniform vec4 color_start : source_color = vec4(1.0, 0.0, 0.5, 1.0);
uniform vec4 color_end : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform float glow_intensity : hint_range(0.5, 3.0) = 1.5;
uniform float thickness_variation : hint_range(0.1, 2.0) = 0.8;
uniform float pulse_frequency : hint_range(0.5, 5.0) = 2.0;

varying float line_progress;
varying vec3 world_position;

void vertex() {
    // Use UV.x as line progress (0.0 to 1.0 along the line)
    line_progress = UV.x;
    
    // Add thickness variation along the line
    float thickness = 1.0 + sin(line_progress * 10.0 + TIME * pulse_frequency) * thickness_variation;
    VERTEX *= thickness;
    
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Create flowing color effect
    float flow_time = TIME * flow_speed + time_offset;
    float color_wave = sin(line_progress * 6.28 + flow_time) * 0.5 + 0.5;
    
    // Mix colors based on position and time
    vec3 flowing_color = mix(color_start.rgb, color_end.rgb, color_wave);
    
    // Add rainbow effect
    float hue_shift = line_progress + flow_time * 0.2;
    vec3 rainbow = vec3(
        sin(hue_shift * 6.28) * 0.5 + 0.5,
        sin(hue_shift * 6.28 + 2.09) * 0.5 + 0.5,
        sin(hue_shift * 6.28 + 4.18) * 0.5 + 0.5
    );
    
    // Combine flowing color and rainbow
    vec3 final_color = mix(flowing_color, rainbow, 0.3);
    
    // Create pulsing effect
    float pulse = sin(TIME * pulse_frequency + line_progress * 3.14) * 0.3 + 0.7;
    
    // Add glow based on distance from line center (UV.y goes from 0 to 1 across line width)
    float center_distance = abs(UV.y - 0.5) * 2.0; // 0 at center, 1 at edges
    float glow = 1.0 - pow(center_distance, 0.5);
    
    ALBEDO = final_color;
    EMISSION = final_color * glow_intensity * pulse * glow;
    ALPHA = color_start.a * glow;
}
"""

func _ready():
    setup_scene()
    generate_line_paths()
    create_line_meshes()
    start_line_animations()

func setup_scene():
    # Create atmospheric environment
    var env = Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.sky.sky_material = ProceduralSkyMaterial.new()
    
    # Dark space-like atmosphere
    var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
    sky_mat.sky_top_color = Color(0.02, 0.02, 0.1)
    sky_mat.sky_horizon_color = Color(0.05, 0.02, 0.15)
    sky_mat.ground_bottom_color = Color(0.01, 0.01, 0.05)
    
    env.ambient_light_energy = 0.1
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    
    # Add volumetric fog for neon glow
    env.volumetric_fog_enabled = true
    env.volumetric_fog_density = 0.02
    env.volumetric_fog_emission = Color(0.05, 0.1, 0.2)
    env.volumetric_fog_emission_energy = 0.5
    
    var camera_env = get_viewport().get_camera_3d()
    if camera_env:
        camera_env.environment = env

func generate_line_paths():
    # Create various path types for visual variety
    line_paths.clear()
    
    for i in range(line_count):
        var path: Array[Vector3] = []
        var path_type = i % 5  # 5 different path types
        
        match path_type:
            0:  # Spiral helix
                path = create_spiral_path(i)
            1:  # Sine wave
                path = create_wave_path(i)
            2:  # Random walk
                path = create_random_path(i)
            3:  # Circular orbit
                path = create_orbit_path(i)
            4:  # DNA double helix
                path = create_dna_path(i)
        
        line_paths.append(path)

func create_spiral_path(index: int) -> Array[Vector3]:
    var points: Array[Vector3] = []
    var radius = 3.0 + (index % 3) * 2.0
    var height_range = 8.0
    var turns = 3.0 + (index % 2)
    
    for i in range(points_per_line):
        var t = float(i) / float(points_per_line - 1)
        var angle = t * PI * 2.0 * turns + index * 0.5
        var height = (t - 0.5) * height_range + sin(index) * 3.0
        
        var point = Vector3(
            cos(angle) * radius,
            height,
            sin(angle) * radius
        )
        points.append(point)
    
    return points

func create_wave_path(index: int) -> Array[Vector3]:
    var points: Array[Vector3] = []
    var length = line_length
    var amplitude = 2.0 + (index % 3) * 1.0
    var frequency = 2.0 + (index % 4) * 0.5
    var direction = Vector3(1, 0, 0).rotated(Vector3.UP, index * 0.8)
    
    for i in range(points_per_line):
        var t = float(i) / float(points_per_line - 1) - 0.5
        var base_pos = direction * t * length
        
        # Add wave displacement
        var wave_y = sin(t * frequency * PI * 2 + index) * amplitude
        var wave_z = cos(t * frequency * PI * 1.5 + index * 0.7) * amplitude * 0.7
        
        var point = base_pos + Vector3(0, wave_y, wave_z)
        points.append(point)
    
    return points

func create_random_path(index: int) -> Array[Vector3]:
    var points: Array[Vector3] = []
    var noise = FastNoiseLite.new()
    noise.seed = index * 1000
    noise.frequency = 0.3
    
    var current_pos = Vector3(
        randf_range(-5.0, 5.0),
        randf_range(-3.0, 3.0),
        randf_range(-5.0, 5.0)
    )
    
    for i in range(points_per_line):
        var t = float(i) / float(points_per_line - 1)
        
        # Use 3D noise for smooth random movement
        var noise_offset = Vector3(
            noise.get_noise_3d(current_pos.x + t * 10, 0, 0),
            noise.get_noise_3d(0, current_pos.y + t * 10, 0),
            noise.get_noise_3d(0, 0, current_pos.z + t * 10)
        ) * 3.0
        
        current_pos += noise_offset * 0.3
        points.append(current_pos)
    
    return points

func create_orbit_path(index: int) -> Array[Vector3]:
    var points: Array[Vector3] = []
    var radius1 = 4.0 + (index % 3) * 1.5
    var radius2 = 2.0 + (index % 2) * 1.0
    var center = Vector3(sin(index) * 3.0, cos(index * 0.7) * 2.0, cos(index) * 3.0)
    
    for i in range(points_per_line):
        var t = float(i) / float(points_per_line - 1)
        var angle1 = t * PI * 2.0 * 2.0  # 2 full orbits
        var angle2 = t * PI * 2.0 * 3.0 + index  # 3 orbits, offset by index
        
        var point = center + Vector3(
            cos(angle1) * radius1 + cos(angle2) * radius2,
            sin(angle1) * 1.5,
            sin(angle1) * radius1 + sin(angle2) * radius2
        )
        points.append(point)
    
    return points

func create_dna_path(index: int) -> Array[Vector3]:
    var points: Array[Vector3] = []
    var radius = 3.0
    var height_range = 12.0
    var helix_offset = PI if index % 2 == 1 else 0.0  # Offset for double helix
    
    for i in range(points_per_line):
        var t = float(i) / float(points_per_line - 1)
        var angle = t * PI * 2.0 * 4.0 + helix_offset + index * 0.3
        var height = (t - 0.5) * height_range
        
        var point = Vector3(
            cos(angle) * radius,
            height,
            sin(angle) * radius
        )
        points.append(point)
    
    return points

func create_line_meshes():
    for i in range(line_count):
        if i >= line_paths.size():
            continue
            
        var line_mesh = create_line_mesh_from_path(line_paths[i])
        var mesh_instance = MeshInstance3D.new()
        mesh_instance.mesh = line_mesh
        mesh_instance.name = "ColoredLine_" + str(i)
        
        # Create unique material for each line
        var material = ShaderMaterial.new()
        var shader = Shader.new()
        shader.code = LINE_SHADER
        material.shader = shader
        
        # Set unique colors and properties
        var hue1 = (float(i) / float(line_count)) * 360.0
        var hue2 = (hue1 + 120.0)
        if hue2 > 360.0: hue2 -= 360.0
        
        var color1 = Color.from_hsv(hue1 / 360.0, 0.8, 1.0)
        var color2 = Color.from_hsv(hue2 / 360.0, 0.8, 1.0)
        
        material.set_shader_parameter("color_start", color1)
        material.set_shader_parameter("color_end", color2)
        material.set_shader_parameter("time_offset", randf() * 10.0)
        material.set_shader_parameter("flow_speed", flow_speed + randf_range(-0.5, 0.5))
        material.set_shader_parameter("glow_intensity", randf_range(1.0, 2.5))
        material.set_shader_parameter("thickness_variation", randf_range(0.3, 1.2))
        material.set_shader_parameter("pulse_frequency", randf_range(1.0, 4.0))
        
        mesh_instance.set_surface_override_material(0, material)
        
        add_child(mesh_instance)
        line_meshes.append(mesh_instance)
        line_materials.append(material)

func create_line_mesh_from_path(path: Array[Vector3]) -> ArrayMesh:
    if path.size() < 2:
        return ArrayMesh.new()
    
    var vertices = PackedVector3Array()
    var normals = PackedVector3Array()
    var uvs = PackedVector2Array()
    var indices = PackedInt32Array()
    
    var line_width = 0.05
    
    # Generate tube geometry along the path
    for i in range(path.size()):
        var current_point = path[i]
        var progress = float(i) / float(path.size() - 1)
        
        # Calculate direction for this segment
        var direction: Vector3
        if i == 0:
            direction = (path[i + 1] - current_point).normalized()
        elif i == path.size() - 1:
            direction = (current_point - path[i - 1]).normalized()
        else:
            direction = (path[i + 1] - path[i - 1]).normalized()
        
        # Create perpendicular vectors for tube cross-section
        var up = Vector3.UP
        if abs(direction.dot(up)) > 0.9:
            up = Vector3.RIGHT
        
        var right = direction.cross(up).normalized()
        var actual_up = right.cross(direction).normalized()
        
        # Create ring of vertices around the line
        var ring_segments = 8
        for j in range(ring_segments):
            var angle = float(j) / float(ring_segments) * PI * 2.0
            var offset = (right * cos(angle) + actual_up * sin(angle)) * line_width
            
            vertices.append(current_point + offset)
            normals.append(offset.normalized())
            uvs.append(Vector2(progress, float(j) / float(ring_segments)))
        
        # Create triangles between rings
        if i > 0:
            var prev_ring_start = (i - 1) * ring_segments
            var curr_ring_start = i * ring_segments
            
            for j in range(ring_segments):
                var next_j = (j + 1) % ring_segments
                
                # Two triangles per quad
                indices.append_array([
                    prev_ring_start + j, curr_ring_start + j, prev_ring_start + next_j,
                    prev_ring_start + next_j, curr_ring_start + j, curr_ring_start + next_j
                ])
    
    var mesh = ArrayMesh.new()
    var arrays = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices
    
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh

func start_line_animations():
    # Animate the line paths themselves
    animate_line_paths()
    
    # Animate shader properties
    animate_shader_properties()

func animate_line_paths():
    # Deform the line paths over time for organic movement
    var tween = create_tween()
    tween.set_loops()
    tween.tween_method(update_line_deformation, 0.0, PI * 2.0, 15.0 / animation_speed)

func update_line_deformation(time: float):
    # Gently deform line paths over time
    for i in range(line_meshes.size()):
        if i >= line_paths.size():
            continue
            
        var original_path = line_paths[i]
        var deformed_path: Array[Vector3] = []
        
        for j in range(original_path.size()):
            var original_point = original_path[j]
            var t = float(j) / float(original_path.size() - 1)
            
            # Add gentle wave deformation
            var deformation = Vector3(
                sin(time + i * 0.3 + t * 4.0) * 0.5,
                cos(time * 0.7 + i * 0.5 + t * 3.0) * 0.3,
                sin(time * 1.1 + i * 0.7 + t * 5.0) * 0.4
            )
            
            deformed_path.append(original_point + deformation)
        
        # Rebuild mesh with deformed path
        var new_mesh = create_line_mesh_from_path(deformed_path)
        line_meshes[i].mesh = new_mesh

func animate_shader_properties():
    # Animate shader uniforms for color flow effects
    for i in range(line_materials.size()):
        var material = line_materials[i]
        
        # Create individual tweens for each line's properties
        var flow_tween = create_tween()
        flow_tween.set_loops()
        flow_tween.tween_method(
            func(value): material.set_shader_parameter("flow_speed", value),
            flow_speed * 0.5,
            flow_speed * 2.0,
            randf_range(3.0, 8.0)
        )
        
        var glow_tween = create_tween()
        glow_tween.set_loops()
        glow_tween.tween_method(
            func(value): material.set_shader_parameter("glow_intensity", value),
            1.0,
            3.0,
            randf_range(2.0, 6.0)
        )

# Advanced path generators
func create_lissajous_curve(a: int, b: int, delta: float, scale: float = 5.0) -> Array[Vector3]:
    # Create beautiful Lissajous curves (mathematical art)
    var points: Array[Vector3] = []
    
    for i in range(points_per_line):
        var t = float(i) / float(points_per_line - 1) * PI * 2.0
        
        var x = sin(a * t + delta) * scale
        var y = sin(b * t) * scale * 0.7
        var z = cos(a * t + delta) * scale
        
        points.append(Vector3(x, y, z))
    
    return points

func create_torus_knot(p: int, q: int, scale: float = 4.0) -> Array[Vector3]:
    # Create torus knot curves
    var points: Array[Vector3] = []
    
    for i in range(points_per_line):
        var t = float(i) / float(points_per_line - 1) * PI * 2.0
        
        var r = cos(q * t) + 2.0
        var x = r * cos(p * t) * scale * 0.3
        var y = sin(q * t) * scale * 0.5
        var z = r * sin(p * t) * scale * 0.3
        
        points.append(Vector3(x, y, z))
    
    return points

func _process(_delta):
    # Update time-based effects
    update_time_uniforms()

func update_time_uniforms():
    # Update time-sensitive shader parameters
    for material in line_materials:
        # This lets the shader access current time for animations
        # The shader already uses TIME, but we can add custom time effects here
        pass

# Optional: Add more complex line types
func add_advanced_lines():
    # Add some mathematical art curves
    for i in range(5):
        # Lissajous curves
        var liss_path = create_lissajous_curve(3 + i, 2 + i, i * 0.5, 4.0)
        line_paths.append(liss_path)
        
        # Torus knots
        var knot_path = create_torus_knot(2 + i, 3, 3.0)
        line_paths.append(knot_path)
