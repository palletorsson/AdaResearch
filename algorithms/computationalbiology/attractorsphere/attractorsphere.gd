# res://morphogenesis/AttractorSphere.gd
extends Node3D

@export var sphere_radius: float = 0.85      # was 1.0  → smaller blob
@export var sphere_rings := 128         # was 64
@export var sphere_radial_segments := 192  # was 96

@export var attractor_count: int = 8                  # how many grab spheres to place
@export var attractor_scene: PackedScene = preload("res://commons/primitives/point/grab_sphere_point_with_color.tscn")
@export var blob_color: Color = Color(0.85, 0.6, 0.95, 0.9) # RGBA, A<1 makes it transparent

@export var attractor_distance: float = 1.35 # was 1.15 → grab spheres sit further out
@export var pull_strength: float = 1.2       # was 0.6  → stronger lift
@export var pull_radius: float = 0.35        # was 0.5  → tighter, punchier bulges
@export var max_displace: float = 1.0        # was 0.7  → allow a bit more height

const MAX_ATTRACTORS := 64

var sphere_mesh_instance: MeshInstance3D
var shader_mat: ShaderMaterial
var attractors: Array[Node3D] = []

func _ready():
	_make_sphere()
	_make_shader()
	_spawn_attractors_fibonacci()
	_update_shader_static_params()

func _process(_delta: float) -> void:
	_push_attractor_positions_to_shader()

# -- sphere setup -------------------------------------------------------------
func _make_sphere():
	sphere_mesh_instance = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = sphere_radius
	sm.height = sphere_radius * 2.0
	sm.is_hemisphere = false
	sm.rings = sphere_rings
	sm.radial_segments = sphere_radial_segments
	sphere_mesh_instance.mesh = sm
	add_child(sphere_mesh_instance)

func _make_shader():
	var shader_code := """
shader_type spatial;


uniform int u_count = 0;
uniform vec3 u_points[64];
uniform float u_strength = 0.9;
uniform float u_radius  = 0.55;
uniform float u_max_displace = 1.0;
uniform vec4 u_color : source_color = vec4(0.85, 0.6, 0.95, 0.79);

/* carry displaced OBJECT-space position to the fragment */
varying vec3 v_obj_pos;

void vertex() {
	vec3 pos = VERTEX;
	vec3 nrm = normalize(NORMAL);
	float disp = 0.0;

	for (int i = 0; i < u_count; i++) {
		float d = distance(pos, u_points[i]);                 // points are in object space
		float w = exp(-(d*d) / (2.0 * u_radius * u_radius));  // Gaussian falloff
		disp += u_strength * w;
	}

	VERTEX   = pos + nrm * clamp(disp, -u_max_displace, u_max_displace);
	v_obj_pos = VERTEX;  // no WORLD/MODEL matrix needed
}

void fragment() {
	// Rebuild a smooth geometric normal from the displaced surface (object space)
	vec3 dx = dFdx(v_obj_pos);
	vec3 dy = dFdy(v_obj_pos);
	vec3 n_obj = normalize(cross(dx, dy));
	NORMAL = n_obj;   // works fine for lighting in practice

	ALBEDO = u_color.rgb;
	ALPHA  = u_color.a;
}


	"""

	var shader := Shader.new()
	shader.code = shader_code
	shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader
	sphere_mesh_instance.material_override = shader_mat

func _update_shader_static_params():
	shader_mat.set_shader_parameter("u_strength", pull_strength)
	shader_mat.set_shader_parameter("u_radius", pull_radius)
	shader_mat.set_shader_parameter("u_max_displace", max_displace)
	shader_mat.set_shader_parameter("u_color", blob_color)

# -- attractors ---------------------------------------------------------------
func _spawn_attractors_fibonacci():
	var n = min(attractor_count, MAX_ATTRACTORS)
	for i in range(n):
		var dir := _fibonacci_on_unit_sphere(i, n)
		var inst := attractor_scene.instantiate() as Node3D
		add_child(inst)
		inst.position = dir * (sphere_radius * attractor_distance)
		attractors.append(inst)

# Distribute points evenly on a sphere (Fibonacci lattice)
func _fibonacci_on_unit_sphere(i: int, n: int) -> Vector3:
	# Golden angle
	var ga := PI * (3.0 - sqrt(5.0))
	var y := 1.0 - (2.0 * float(i) + 1.0) / float(n)        # from 1 to -1
	var r := sqrt(max(0.0, 1.0 - y * y))
	var theta := ga * float(i)
	var x := r * cos(theta)
	var z := r * sin(theta)
	return Vector3(x, y, z).normalized()

func _push_attractor_positions_to_shader():
	# collect positions relative to sphere's local space (shader expects object space)
	var local_positions := PackedVector3Array()
	var count = min(attractors.size(), MAX_ATTRACTORS)
	local_positions.resize(count)
	for i in range(count):
		local_positions[i] = sphere_mesh_instance.to_local(attractors[i].global_position)

	shader_mat.set_shader_parameter("u_count", count)
	# If count < MAX_ATTRACTORS, Godot is fine with shorter arrays
	shader_mat.set_shader_parameter("u_points", local_positions)
