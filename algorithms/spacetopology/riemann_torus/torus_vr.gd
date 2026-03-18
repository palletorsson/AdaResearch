@tool
extends Node3D

# ---------------- Parameters ----------------
@export var show_plane: bool = true
@export var show_tiles: bool = true
@export var tile_radius: int = 1        # how many tiles to show around origin in the plane view
@export var plane_cell: float = 0.1     # grid spacing for the floor helper
@export var torus_outer: float = 1.0
@export var torus_inner: float = 0.35
@export var stripe_density_u: float = 16.0
@export var stripe_density_v: float = 16.0
@export var animate_stripes: bool = true
@export var stripe_speed: float = 0.4

# 3-torus wrap demo (optional): when true, we wrap the player's Node3D child "PlayerRig"
@export var enable_3torus_wrap: bool = false
@export var wrap_box_half_extent: float = 1.5  # half-size of identification box

# ---------------- Nodes ----------------
var origin: Node3D
var omega1: Node3D
var omega2: Node3D
var tau_label: Label3D
var torus: MeshInstance3D
var mm_tiles: MultiMeshInstance3D
var edges: Array[MeshInstance3D]

# Materials
var torus_mat: ShaderMaterial

func _ready() -> void:
	origin = $Origin
	omega1 = $Omega1
	omega2 = $Omega2
	tau_label = $TauLabel
	torus = $Torus
	mm_tiles = $FundamentalGrid

	# Create edge lines programmatically
	for i in range(4):
		var edge = MeshInstance3D.new()
		edge.name = "Edge" + str(i)
		$Parallelogram.add_child(edge)
		edge.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self
		edges.append(edge)

	# Ensure torus mesh matches exports
	if torus.mesh is TorusMesh:
		torus.mesh.inner_radius = torus_inner
		torus.mesh.outer_radius = torus_outer

	# Make a floor grid so you can place the lattice vectors on XZ
	_make_floor_grid()

	# Shader that draws two stripe families along UV (u,v) = torus directions
	_setup_torus_shader()

	# Configure tiling in the plane to visualize the lattice
	_setup_multimesh_tiles()

	set_process(true)
	set_physics_process(true)


func _process(delta: float) -> void:
	# Lattice vectors from XZ plane (treat XZ as complex plane)
	var w1 = Vector2(omega1.global_transform.origin.x, omega1.global_transform.origin.z) - Vector2(origin.global_transform.origin.x, origin.global_transform.origin.z)
	var w2 = Vector2(omega2.global_transform.origin.x, omega2.global_transform.origin.z) - Vector2(origin.global_transform.origin.x, origin.global_transform.origin.z)

	# If collinear or near-zero, bail out gracefully
	var area = absf(w1.x * w2.y - w1.y * w2.x)
	if area < 1e-4:
		tau_label.text = "τ = ill-defined (vectors collinear)"
	else:
		var tau = _complex_div(w2, w1) # tau = w2 / w1
		tau_label.text = "τ = %.3f %+.3fi" % [tau.x, tau.y]

	_update_parallelogram_edges(w1, w2)
	_update_tiles(w1, w2)

	# Animate torus stripes to show double periodicity
	if animate_stripes and is_instance_valid(torus_mat):
		torus_mat.set_shader_parameter("time_phase", (torus_mat.get_shader_parameter("time_phase") as float) + stripe_speed * delta)


func _physics_process(_delta: float) -> void:
	if enable_3torus_wrap:
		_wrap_player_in_box()


# ---------------- Helpers ----------------

func _make_floor_grid() -> void:
	# Replace the placeholder mesh with a PlaneMesh + GridMaterial via immediate mesh for clarity
	# We'll just use a large GridMap-like helper using a SurfaceTool line mesh so it's cheap.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	var extent := 6.0
	for x in range(int(-extent / plane_cell), int(extent / plane_cell) + 1):
		var fx := float(x) * plane_cell
		st.add_vertex(Vector3(fx, 0.0, -extent))
		st.add_vertex(Vector3(fx, 0.0,  extent))
	for z in range(int(-extent / plane_cell), int(extent / plane_cell) + 1):
		var fz := float(z) * plane_cell
		st.add_vertex(Vector3(-extent, 0.0, fz))
		st.add_vertex(Vector3( extent, 0.0, fz))
	var line_mesh := st.commit()
	var grid := MeshInstance3D.new()
	grid.mesh = line_mesh
	grid.material_override = _simple_unshaded_color(Color(0.35, 0.35, 0.4, 0.9))
	grid.name = "FloorGrid"
	add_child(grid)
	if Engine.is_editor_hint():
		grid.owner = get_tree().edited_scene_root


func _simple_unshaded_color(c: Color) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = "
shader_type spatial;
render_mode unshaded, depth_draw_always;
uniform vec4 col: source_color;
void fragment(){ ALBEDO = col.rgb; ALPHA = col.a; }
"
	var sm := ShaderMaterial.new()
	sm.shader = sh
	sm.set_shader_parameter("col", c)
	return sm


func _setup_torus_shader() -> void:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;
uniform float stripe_density_u = 16.0;
uniform float stripe_density_v = 16.0;
uniform float time_phase = 0.0;
// Two orthogonal stripe families along UV to visualize double periodicity
void fragment(){
	vec2 uv = UV;
	float a = 0.5 + 0.5 * cos((uv.x + 0.05 * time_phase) * stripe_density_u * 6.28318530718);
	float b = 0.5 + 0.5 * cos((uv.y - 0.07 * time_phase) * stripe_density_v * 6.28318530718);
	float grid = clamp(0.6*a + 0.6*b, 0.0, 1.0);
	ALBEDO = vec3(0.15, 0.30, 0.65) * (0.45 + 0.55 * grid);
	METALLIC = 0.0;
	ROUGHNESS = 0.55;
}
"""
	torus_mat = ShaderMaterial.new()
	torus_mat.shader = sh
	torus_mat.set_shader_parameter("stripe_density_u", stripe_density_u)
	torus_mat.set_shader_parameter("stripe_density_v", stripe_density_v)
	torus_mat.set_shader_parameter("time_phase", 0.0)
	torus.material_override = torus_mat


func _setup_multimesh_tiles() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = false
	# A tiny quad as the tile marker; we'll build a simple plane with SurfaceTool
	var tile_mesh := _make_tile_quad(0.18, Color(0.9, 0.9, 0.95, 0.85))
	mm.mesh = tile_mesh
	mm.instance_count = 0  # Start with 0 instances to avoid rendering errors
	mm_tiles.multimesh = mm


func _make_tile_quad(size: float, tint: Color) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var s := size * 0.5
	var verts = [
		Vector3(-s, 0.001, -s),
		Vector3( s, 0.001, -s),
		Vector3( s, 0.001,  s),
		Vector3(-s, 0.001,  s)
	]
	var uvs = [Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(0,1)]
	st.set_color(tint)
	st.set_uv(uvs[0]); st.add_vertex(verts[0])
	st.set_uv(uvs[1]); st.add_vertex(verts[1])
	st.set_uv(uvs[2]); st.add_vertex(verts[2])
	st.set_uv(uvs[0]); st.add_vertex(verts[0])
	st.set_uv(uvs[2]); st.add_vertex(verts[2])
	st.set_uv(uvs[3]); st.add_vertex(verts[3])
	var m := st.commit()
	m.surface_set_material(0, _simple_unshaded_color(tint))
	return m


func _update_tiles(w1: Vector2, w2: Vector2) -> void:
	if not show_tiles:
		mm_tiles.visible = false
		return
	mm_tiles.visible = true

	var mm := mm_tiles.multimesh
	if mm == null or mm.mesh == null: return

	# Put a central "fundamental domain" tile at each lattice translate m*w1 + n*w2
	var count := (2 * tile_radius + 1) * (2 * tile_radius + 1)
	mm.instance_count = count

	var idx := 0
	for i in range(-tile_radius, tile_radius + 1):
		for j in range(-tile_radius, tile_radius + 1):
			var p := origin.global_transform.origin
			var shift := Vector3(
				i * w1.x + j * w2.x,
				0.0,
				i * w1.y + j * w2.y
			)
			var t := Transform3D.IDENTITY
			t.origin = p + shift
			mm.set_instance_transform(idx, t)
			idx += 1


func _update_parallelogram_edges(w1: Vector2, w2: Vector2) -> void:
	# Four corners in XZ plane
	var O := origin.global_transform.origin
	var A := O + Vector3(w1.x, 0.0, w1.y)
	var B := O + Vector3(w1.x + w2.x, 0.0, w1.y + w2.y)
	var C := O + Vector3(w2.x, 0.0, w2.y)

	# Draw the four edges as cylinders
	_set_edge(edges[0], O, A) # O -> A
	_set_edge(edges[1], A, B) # A -> B
	_set_edge(edges[2], B, C) # B -> C
	_set_edge(edges[3], C, O) # C -> O


func _set_edge(edge: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var direction := (b - a)
	var length := direction.length()
	if length < 1e-5:
		edge.visible = false
		return
	edge.visible = true

	direction = direction / length

	# Create or update cylinder mesh
	if edge.mesh == null or not (edge.mesh is CylinderMesh):
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.01
		cylinder.bottom_radius = 0.01
		cylinder.radial_segments = 8
		cylinder.rings = 0
		edge.mesh = cylinder

		# Create material
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.8, 0.3, 1.0)
		material.metallic = 0.7
		material.roughness = 0.2
		material.emission_enabled = true
		material.emission = Color(1.0, 0.8, 0.3, 0.5)
		edge.material_override = material

	# Update mesh height
	var cylinder := edge.mesh as CylinderMesh
	cylinder.height = length

	# Position at center
	edge.global_transform.origin = (a + b) / 2.0

	# Orient the cylinder along the direction
	var up := Vector3.UP
	var right := direction.cross(up).normalized()
	if right.length() < 0.001:  # If direction is parallel to UP
		right = Vector3.RIGHT
		up = right.cross(direction).normalized()
	else:
		up = right.cross(direction).normalized()

	edge.transform.basis = Basis(right, direction, up)


func _complex_div(a: Vector2, b: Vector2) -> Vector2:
	# (a.x + i a.y) / (b.x + i b.y)
	var denom := b.x*b.x + b.y*b.y
	if denom < 1e-12: return Vector2.ZERO
	return Vector2((a.x*b.x + a.y*b.y)/denom, (a.y*b.x - a.x*b.y)/denom)


# ---------------- 3-Torus Wrap Demo ----------------
func _wrap_player_in_box() -> void:
	var rig := get_node_or_null("PlayerRig")
	if rig == null: return
	if not (rig is Node3D): return
	var p := (rig as Node3D).global_transform.origin
	var he := wrap_box_half_extent
	var size := he * 2.0
	var changed := false

	if p.x >  he: p.x -= size; changed = true
	if p.x < -he: p.x += size; changed = true
	if p.y >  he: p.y -= size; changed = true
	if p.y < -he: p.y += size; changed = true
	if p.z >  he: p.z -= size; changed = true
	if p.z < -he: p.z += size; changed = true

	if changed:
		var t := (rig as Node3D).global_transform
		t.origin = p
		(rig as Node3D).global_transform = t

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
