extends Node3D

# --------- Tweakables (show in Inspector at runtime too) ---------
@export var base_color: Color = Color(1.0, 0.76, 0.86)
@export var base_block_count: int = 6
@export var base_block_size: Vector3 = Vector3(0.35, 0.28, 0.4)
@export var base_step_drop: float = 0.06

@export var post_height: float = 1.15
@export var post_radius: float = 0.03
@export var post_spacing: float = 0.38
@export var post_color: Color = Color(0.95, 0.9, 0.92)
@export var post_metallic: float = 0.9
@export var post_roughness: float = 0.08

@export var torus_major: float = 0.28
@export var torus_minor: float = 0.10
@export var torus_rings: int = 64
@export var torus_sides: int = 32
@export var torus_wave_amp: float = 0.035
@export var torus_wave_freq: float = 6.0
@export var torus_pink: Color = Color(1.0, 0.62, 0.78)
@export var torus_dark: Color = Color(0.09, 0.09, 0.1)

@export var rope_radius: float = 0.045
@export var rope_segments: int = 16
@export var rope_samples: int = 22
@export var rope_color: Color = Color(0.05, 0.05, 0.06)
@export var rope_sag: float = 0.18

@export var bulbs_per_side: int = 18
@export var bulb_radius: float = 0.01
@export var bulb_emission: Color = Color(1.0, 0.9, 0.6) * 5.0

# ---------- Node names ----------
const N_BASE := "Base"
const N_POSTS := "Posts"
const N_TORUS := "TopTorus"
const N_ROPE_L := "RopeLeft"
const N_ROPE_R := "RopeRight"
const N_LIGHTS := "FairyLights"

func _ready() -> void:
	# Build once at runtime
	_rebuild_scene()

# ---------- Build ----------
func _rebuild_scene() -> void:
	# Clear any previous run
	for c in get_children():
		if c is MeshInstance3D or c.name in [N_BASE, N_POSTS, N_TORUS, N_ROPE_L, N_ROPE_R, N_LIGHTS]:
			remove_child(c)
			c.queue_free()

	_build_base()
	_build_posts()
	_build_torus()
	_build_ropes()
	_build_fairy_lights()

# ---------- Materials ----------
func _make_standard(color: Color, metallic := 0.0, rough := 0.5, emissive := Color(0,0,0)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = rough
	if emissive.a > 0.0 or (emissive.r + emissive.g + emissive.b) > 0.0:
		m.emission_enabled = true
		m.emission = emissive
	return m

# ---------- Base ----------
func _build_base() -> void:
	var base := Node3D.new()
	base.name = N_BASE
	add_child(base)

	var mat := _make_standard(base_color, 0.0, 0.5)
	var start_x := -float(base_block_count - 1) * 0.5 * base_block_size.x
	for i in range(base_block_count):
		var mi := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = base_block_size
		mi.mesh = bx
		mi.material_override = mat
		var drop := floori(i / 2) * base_step_drop
		mi.transform = Transform3D(Basis.IDENTITY, Vector3(start_x + i * base_block_size.x, base_block_size.y * 0.5 - drop, 0.0))
		base.add_child(mi)

# ---------- Posts ----------
func _build_posts() -> void:
	var posts := Node3D.new()
	posts.name = N_POSTS
	add_child(posts)

	var mat := _make_standard(post_color, post_metallic, post_roughness)
	var xs := [-post_spacing, 0.0, post_spacing]
	for x in xs:
		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = post_radius
		cyl.bottom_radius = post_radius
		cyl.height = post_height
		cyl.radial_segments = 32
		mi.mesh = cyl
		mi.material_override = mat
		mi.position = Vector3(x, base_block_size.y - 0.001, 0.0)
		posts.add_child(mi)

# ---------- Torus (rippling shader) ----------
func _build_torus() -> void:
	var torus := MeshInstance3D.new()
	torus.name = N_TORUS
	add_child(torus)

	var t := TorusMesh.new()
	t.rings = torus_rings
	#t.radial_segments = torus_sides
	t.inner_radius = torus_minor
	t.outer_radius = torus_major
	torus.mesh = t
	torus.position = Vector3(0.0, base_block_size.y + post_height - 0.02, 0.0)

	var sh := Shader.new()
	sh.code = _torus_shader_code()
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("col_a", torus_pink)
	mat.set_shader_parameter("col_b", torus_dark)
	mat.set_shader_parameter("wave_amp", torus_wave_amp)
	mat.set_shader_parameter("wave_freq", torus_wave_freq)
	torus.material_override = mat

# ---------- Ropes ----------
func _build_ropes() -> void:
	var y_top := base_block_size.y + post_height - 0.02
	var y_bottom := base_block_size.y + 0.12
	var x_side := torus_major + torus_minor * 0.6

	var left_pts := [
		Vector3(-x_side, y_top,  0.0),
		Vector3(-x_side * 0.95, lerp(y_top, y_bottom, 0.35) - rope_sag, 0.02),
		Vector3(-x_side * 0.70, y_bottom,  0.0)
	]
	var right_pts := [
		Vector3(x_side, y_top,  0.0),
		Vector3(x_side * 0.95, lerp(y_top, y_bottom, 0.35) - rope_sag, -0.02),
		Vector3(x_side * 0.70, y_bottom,  0.0)
	]

	var rope_mat := _make_standard(rope_color, 0.0, 0.8)

	var ropeL := MeshInstance3D.new()
	ropeL.name = N_ROPE_L
	ropeL.mesh = _generate_tube_mesh(left_pts, rope_radius, rope_segments, rope_samples)
	ropeL.material_override = rope_mat
	add_child(ropeL)

	var ropeR := MeshInstance3D.new()
	ropeR.name = N_ROPE_R
	ropeR.mesh = _generate_tube_mesh(right_pts, rope_radius, rope_segments, rope_samples)
	ropeR.material_override = rope_mat
	add_child(ropeR)

# ---------- Fairy lights ----------
func _build_fairy_lights() -> void:
	var node := Node3D.new()
	node.name = N_LIGHTS
	add_child(node)

	var y_top := base_block_size.y + post_height * 0.66
	var y_mid := y_top - 0.16
	var x_span := post_spacing * 1.4
	var pts := [
		Vector3(-x_span, y_top,  0.0),
		Vector3(0.0,     y_mid,  0.0),
		Vector3(x_span,  y_top,  0.0)
	]

	var bulb_mesh := SphereMesh.new()
	bulb_mesh.radius = bulb_radius
	bulb_mesh.radial_segments = 14
	bulb_mesh.rings = 8

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bulb_mesh
	mm.instance_count = bulbs_per_side * 2

	var bulb_mat := _make_standard(Color(1,1,1,0.8), 0.0, 0.3, bulb_emission)

	var holder := MeshInstance3D.new()
	holder.mesh = bulb_mesh
	holder.visible = false
	holder.material_override = bulb_mat
	node.add_child(holder)

	var idx := 0
	for side in [-1, 1]:
		for i in range(bulbs_per_side):
			var t := float(i) / float(max(1, bulbs_per_side - 1))
			var p := _bezier3(pts[0] * side, pts[1] * side, pts[2] * side, t)
			var xform := Transform3D(Basis.IDENTITY, p)
			mm.set_instance_transform(idx, xform)
			idx += 1

	var mm_inst := MultiMeshInstance3D.new()
	mm_inst.multimesh = mm
	mm_inst.material_override = bulb_mat
	node.add_child(mm_inst)

# ---------- Geometry helpers ----------
func _bezier3(a: Vector3, b: Vector3, c: Vector3, t: float) -> Vector3:
	var u := 1.0 - t
	return u * u * a + 2.0 * u * t * b + t * t * c

func _generate_tube_mesh(ctrl_pts: Array, radius: float, radial_segs: int, samples: int) -> ArrayMesh:
	assert(ctrl_pts.size() == 3)
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	var last_ring_start := 0
	var prev_p := _bezier3(ctrl_pts[0], ctrl_pts[1], ctrl_pts[2], 0.0)
	var prev_tangent := Vector3.FORWARD

	for s in range(samples):
		var t := float(s) / float(samples - 1)
		var p := _bezier3(ctrl_pts[0], ctrl_pts[1], ctrl_pts[2], t)

		var eps := 1.0 / float(samples - 1)
		var p2 := _bezier3(ctrl_pts[0], ctrl_pts[1], ctrl_pts[2], clamp(t + eps, 0.0, 1.0))
		var tangent := (p2 - p).normalized()
		if tangent.length() < 0.001:
			tangent = prev_tangent

		var ref := Vector3.UP
		if abs(ref.dot(tangent)) > 0.9:
			ref = Vector3.RIGHT
		var bin := tangent.cross(ref).normalized()
		var nor := bin.cross(tangent).normalized()

		var ring_start := verts.size()
		for r in range(radial_segs):
			var ang := TAU * float(r) / float(radial_segs)
			var dir := nor * cos(ang) + bin * sin(ang)
			verts.push_back(p + dir * radius)
			norms.push_back(dir)
			uvs.push_back(Vector2(float(r) / float(radial_segs), t))

		if s > 0:
			for r in range(radial_segs):
				var a := last_ring_start + r
				var b := last_ring_start + ((r + 1) % radial_segs)
				var c := ring_start + r
				var d := ring_start + ((r + 1) % radial_segs)
				indices.push_back(a); indices.push_back(c); indices.push_back(b)
				indices.push_back(b); indices.push_back(c); indices.push_back(d)
		last_ring_start = ring_start
		prev_tangent = tangent
		prev_p = p

	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = indices

	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m

# ---------- Torus shader ----------
func _torus_shader_code() -> String:
	return """
shader_type spatial;
render_mode cull_back, specular_schlick_ggx, shadows_disabled;

uniform vec4 col_a : source_color;
uniform vec4 col_b : source_color;
uniform float wave_amp = 0.03;
uniform float wave_freq = 6.0;

void vertex() {
	float w = sin(UV.x * 6.28318 * wave_freq) * wave_amp;
	VERTEX += NORMAL * w;
}

float stripe(vec2 uv) {
	float v = sin(uv.x * 8.0) * 0.5 + 0.5;
	v += sin((uv.x + uv.y*0.6) * 16.0) * 0.25;
	return clamp(v, 0.0, 1.0);
}

void fragment() {
	float s = stripe(UV);
	vec3 albedo = mix(col_b.rgb, col_a.rgb, s);
	ALBEDO = albedo;
	METALLIC = 0.0;
	ROUGHNESS = 0.35;
}
"""
