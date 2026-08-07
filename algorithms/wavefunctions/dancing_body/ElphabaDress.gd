# ElphabaDress - Mathematical wave dress that follows a rigged skeleton
# Inspired by Elphaba from Wicked - a flowing dress made of sine waves
# Attaches to skeleton bones and generates parametric fabric
#
# Performance: Mesh is built ONCE in _ready(). Animation updates vertex positions
# directly via ArrayMesh surface arrays — no SurfaceTool per frame.

extends Node3D


# @identity
# essence: r(u,v) = waist + (hem-waist)*u, modulated by sin(v*TAU + wave*u)
# desire: Watch fabric ripple as sine waves propagate through a procedural dress mesh
# critical_parameter: wearer — what the garment hangs on. A dress is the one artifact in
#   this registry that argues about a BODY, and the shipped build argues by omission: the
#   dress floats empty, worn by nobody, mathematics wearing itself. The axis makes that
#   omission one member of a family of four answers to "what is inside this?".
# triggers: set_wave_intensity() deforms the parametric surface in real-time; _ready reads
#   #wearer: and stages the wearer; apply_grid_config({wearer}).
# emerges: cloth-like motion from pure trigonometric displacement of vertices
# needs: VR sliders for wave parameters [missing], skeleton attachment [has]
# relationships: depends on SurfaceTool mesh generation; contrasts with ruth_asawa_sculpture (fabric vs wire); unlocks wearable wave visualization
# truth: Fabric is a surface that remembers every wave that passes through it.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-06). Every export on this costume was a dial on the
# CLOTH — radii, wave amplitudes, three greens. You could make the skirt wider, wavier
# or greener and in every case you got the identical epistemic object: an empty garment,
# presented as a surface. What a garment ARGUES is the body wearing it, and this one has
# never had one.
#
# The word is `wearer` — adopted, not invented: ten promoted artifacts already carry it
# for "what holds this thing up" (pollock_painting_in_3d: floor|table|easel|wall;
# double_helix_scene in this registry: monument|bench|vitrine|terrace). The values are
# the garment trade's own:
#
#   none     THE LEGACY LINEAGE, byte for byte — the dress floats empty. Worn by nobody,
#            held by nothing: the claim that the wave needs no wearer.
#   hanger   a wooden hanger and a rail above. The wardrobe: a costume between
#            performances, the body merely expected.
#   form     a tailor's dress form — canvas bust above the waist, pole through the hem,
#            round base below. The atelier: a stand-in body, headless, armless, exactly
#            as much body as the cloth requires and no more.
#   figure   a green-skinned wearer — head, neck, shoulders, arms, and the pointed hat.
#            The performance: Elphaba inside her own mathematics, the costume worn.
#
# The dress mesh itself is IDENTICAL in all four — same vertices, same shader, same
# animation. R5: the wave is the curriculum and no value repaints it. All wearer
# geometry is appended LAST inside one host node, so "none" is the untouched scene tree.
#
# R2 note: wave_amplitude / flutter_intensity / animation_speed were the tempting axes
# and all three are motion — a still photographs the same dress at one phase regardless.
# ─────────────────────────────────────────────────────────────────────────────

## AXIS — what the garment hangs on: nothing, the wardrobe, the atelier, or the wearer.
@export_enum("none", "hanger", "form", "figure") var wearer: String = "none"
const WEARERS: PackedStringArray = ["none", "hanger", "form", "figure"]

@export_group("Dress Shape")
@export var waist_radius: float = 0.15
@export var hem_radius: float = 0.4  # Bottom of dress
@export var dress_length: float = 0.8
@export var u_steps: int = 48  # Vertical resolution
@export var v_steps: int = 32  # Circular resolution

@export_group("Wave Parameters")
@export var wave_amplitude: float = 0.03
@export var wave_frequency: float = 5.0
@export var vertical_waves: float = 3.0
@export var animation_speed: float = 2.0
@export var flutter_intensity: float = 0.02

@export_group("Colors - Elphaba Style")
@export var primary_color: Color = Color(0.0, 0.3, 0.1)  # Dark emerald green
@export var secondary_color: Color = Color(0.0, 0.5, 0.2)  # Bright green
@export var wireframe_color: Color = Color(0.0, 1.0, 0.4)  # Glowing green wireframe
@export var emission_strength: float = 1.5

@export_group("Skeleton Binding")
@export var follow_skeleton: bool = true
@export var spine_bone_name: String = "spine"
@export var hip_bone_name: String = "hips"

var mesh_instance: MeshInstance3D
var _time: float = 0.0
var _skeleton: Skeleton3D
var _spine_bone_idx: int = -1
var _hip_bone_idx: int = -1
var _base_vertices: Array = []  # 2D array [row][col] for animation math (indexes by row/column)
var _initialized: bool = false  # Prevent animation before mesh is ready

# Cached surface arrays from the initial mesh build — reused every frame
var _cached_surface_arrays: Array = []
# Base vertex positions (PackedVector3Array) — the unanimated positions
var _base_vertices_packed: PackedVector3Array
# Precomputed per-vertex animation parameters to avoid recalculating each frame
var _vertex_u: PackedFloat32Array       # u parameter (0..1, top to bottom)
var _vertex_angle: PackedFloat32Array   # angle around the circle
var _vertex_cos_angle: PackedFloat32Array
var _vertex_sin_angle: PackedFloat32Array

func _ready() -> void:
	call_deferred("_initialize")

func _initialize() -> void:
	# Try to find skeleton in parent hierarchy
	if follow_skeleton:
		_find_skeleton()

	create_dress_mesh()

	# DNA, LAST: the wearer is staged after the dress exists, so nothing about the
	# legacy build shifts. "none" builds nothing at all.
	_read_meta_overrides()
	_build_wearer()

func _find_skeleton() -> void:
	var parent = get_parent()
	while parent:
		_skeleton = _find_skeleton_recursive(parent)
		if _skeleton:
			break
		parent = parent.get_parent()

	if _skeleton:
		_spine_bone_idx = _skeleton.find_bone(spine_bone_name)
		_hip_bone_idx = _skeleton.find_bone(hip_bone_name)

		# Try alternative bone names
		if _spine_bone_idx < 0:
			_spine_bone_idx = _skeleton.find_bone("Spine")
		if _hip_bone_idx < 0:
			_hip_bone_idx = _skeleton.find_bone("Hips")

		print("ElphabaDress: Found skeleton, spine=%d, hip=%d" % [_spine_bone_idx, _hip_bone_idx])

func _find_skeleton_recursive(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = _find_skeleton_recursive(child)
		if result:
			return result
	return null

func create_dress_mesh() -> void:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	_base_vertices.clear()

	# Generate dress as a flared cone with wave modulation
	for i in range(u_steps + 1):
		var row = []
		var u = float(i) / float(u_steps)  # 0 to 1, top to bottom

		for j in range(v_steps + 1):
			var v = float(j) / float(v_steps)  # 0 to 1, around circle
			var angle = v * TAU

			# Radius expands from waist to hem (flared skirt shape)
			var flare = ease(u, 0.7)  # Ease function for natural flare
			var radius = lerp(waist_radius, hem_radius, flare)

			# Add wave modulation for fabric ripples
			var wave_u = sin(u * vertical_waves * TAU) * wave_amplitude * u
			var wave_v = sin(angle * wave_frequency) * wave_amplitude * (0.5 + u * 0.5)
			radius += wave_u + wave_v

			# Additional flowing waves (Dini-like surface influence)
			var flow_wave = sin(angle * 3.0 + u * TAU) * wave_amplitude * 0.5 * u
			radius += flow_wave

			# Calculate position
			var x = radius * cos(angle)
			var z = radius * sin(angle)
			var y = -u * dress_length  # Negative Y = downward

			# Add slight vertical wave for flowing effect
			y += sin(angle * wave_frequency * 0.5) * wave_amplitude * 0.3 * u

			row.append(Vector3(x, y, z))
		_base_vertices.append(row)

	# Create faces
	_build_mesh_faces(surface_tool, _base_vertices)

	# Generate and apply mesh
	surface_tool.generate_normals()
	var generated_mesh: ArrayMesh = surface_tool.commit()

	if mesh_instance:
		mesh_instance.queue_free()

	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = generated_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mesh_instance)

	apply_material()

	# Cache the surface arrays for per-frame animation (avoids SurfaceTool rebuild)
	_cached_surface_arrays = generated_mesh.surface_get_arrays(0)
	_base_vertices_packed = PackedVector3Array(_cached_surface_arrays[Mesh.ARRAY_VERTEX])

	# Precompute per-vertex animation parameters
	_precompute_vertex_params()

	_initialized = true
	print("ElphabaDress: Mesh created with %d vertex rows, %d packed verts" % [_base_vertices.size(), _base_vertices_packed.size()])

func _precompute_vertex_params() -> void:
	# For each vertex in the packed array, figure out which (i, j) grid cell it came from
	# and store the u/angle values so we don't recompute them every frame.
	#
	# The mesh was built by _build_mesh_faces which emits 6 vertices per quad (2 triangles).
	# Quad (i, j) emits vertices in order: v0, v1, v2, v0, v2, v3
	# where v0 = [i][j], v1 = [i+1][j], v2 = [i+1][j+1], v3 = [i][j+1]
	#
	# We need the u and angle for each vertex to apply the wave animation.

	var vert_count = _base_vertices_packed.size()
	_vertex_u = PackedFloat32Array()
	_vertex_angle = PackedFloat32Array()
	_vertex_cos_angle = PackedFloat32Array()
	_vertex_sin_angle = PackedFloat32Array()
	_vertex_u.resize(vert_count)
	_vertex_angle.resize(vert_count)
	_vertex_cos_angle.resize(vert_count)
	_vertex_sin_angle.resize(vert_count)

	var idx := 0
	for i in range(u_steps):
		for j in range(v_steps):
			# The 4 corner grid coordinates for this quad
			var corners_i = [i, i + 1, i + 1, i, i + 1, i]       # v0,v1,v2, v0,v2,v3
			var corners_j = [j, j, j + 1, j, j + 1, j + 1]

			for k in range(6):
				var ci = corners_i[k]
				var cj = corners_j[k]
				var u = float(ci) / float(u_steps)
				var v = float(cj) / float(v_steps)
				var angle = v * TAU

				_vertex_u[idx] = u
				_vertex_angle[idx] = angle
				_vertex_cos_angle[idx] = cos(angle)
				_vertex_sin_angle[idx] = sin(angle)
				idx += 1

func _build_mesh_faces(surface_tool: SurfaceTool, vertices: Array) -> void:
	for i in range(u_steps):
		for j in range(v_steps):
			var v0 = vertices[i][j]
			var v1 = vertices[i + 1][j]
			var v2 = vertices[i + 1][j + 1]
			var v3 = vertices[i][j + 1]

			# Calculate normal
			var edge1 = v1 - v0
			var edge2 = v3 - v0
			var normal = edge1.cross(edge2).normalized()

			# UV coordinates for potential texture mapping
			var uv0 = Vector2(float(j) / v_steps, float(i) / u_steps)
			var uv1 = Vector2(float(j) / v_steps, float(i + 1) / u_steps)
			var uv2 = Vector2(float(j + 1) / v_steps, float(i + 1) / u_steps)
			var uv3 = Vector2(float(j + 1) / v_steps, float(i) / u_steps)

			# First triangle
			surface_tool.set_normal(normal)
			surface_tool.set_uv(uv0)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(normal)
			surface_tool.set_uv(uv1)
			surface_tool.add_vertex(v1)
			surface_tool.set_normal(normal)
			surface_tool.set_uv(uv2)
			surface_tool.add_vertex(v2)

			# Second triangle
			surface_tool.set_normal(normal)
			surface_tool.set_uv(uv0)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(normal)
			surface_tool.set_uv(uv2)
			surface_tool.add_vertex(v2)
			surface_tool.set_normal(normal)
			surface_tool.set_uv(uv3)
			surface_tool.add_vertex(v3)

func apply_material() -> void:
	if not mesh_instance:
		return

	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")

	if shader:
		material.shader = shader
		material.set_shader_parameter("modelColor", primary_color)
		material.set_shader_parameter("wireframeColor", wireframe_color)
		material.set_shader_parameter("emissionColor", secondary_color)
		material.set_shader_parameter("width", 1.5)
		material.set_shader_parameter("emission_strength", emission_strength)
		mesh_instance.material_override = material
	else:
		# Fallback material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = primary_color
		standard_material.emission_enabled = true
		standard_material.emission = secondary_color
		standard_material.emission_energy_multiplier = emission_strength
		standard_material.metallic = 0.3
		standard_material.roughness = 0.6
		standard_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Double-sided
		mesh_instance.mesh.surface_set_material(0, standard_material)

func _process(delta: float) -> void:
	_time += delta * animation_speed

	# Animate the dress with flowing waves
	_animate_dress()

	# Follow skeleton if available
	if follow_skeleton and _skeleton and mesh_instance:
		_follow_skeleton_position()

func _animate_dress() -> void:
	# Safety checks
	if not _initialized:
		return
	if _base_vertices_packed.is_empty() or not mesh_instance:
		return
	if _cached_surface_arrays.is_empty():
		return

	var vert_count := _base_vertices_packed.size()

	# Create a new PackedVector3Array with animated positions
	var animated_positions := PackedVector3Array()
	animated_positions.resize(vert_count)

	# Cache frequently accessed values to local variables
	var time := _time
	var wf := wave_frequency
	var fi := flutter_intensity

	# Precomputed trig for sway (constant across all vertices this frame)
	var sway_base := sin(time * 0.5) * fi * 2.0
	var time_07 := time * 0.7

	for idx in range(vert_count):
		var base_pos := _base_vertices_packed[idx]
		var u := _vertex_u[idx]
		var angle := _vertex_angle[idx]
		var cos_a := _vertex_cos_angle[idx]
		var sin_a := _vertex_sin_angle[idx]

		# Animated wave offset — exact same math as original
		var time_wave := sin(time + angle * wf + u * TAU) * fi * u
		var secondary_wave := cos(time_07 + angle * 3.0) * fi * 0.5 * u

		# Apply animation
		var ax := base_pos.x + time_wave * cos_a
		var ay := base_pos.y + secondary_wave * 0.3
		var az := base_pos.z + time_wave * sin_a

		# Swaying motion (like wind)
		ax += sway_base * u

		animated_positions[idx] = Vector3(ax, ay, az)

	# Update the mesh in-place: swap vertex array, clear surface, re-add
	# This avoids SurfaceTool entirely — just array manipulation on ArrayMesh
	var arrays := _cached_surface_arrays.duplicate()
	arrays[Mesh.ARRAY_VERTEX] = animated_positions
	# Skip normal recalculation — SimpleGrid.gdshader is a wireframe shader
	# that doesn't use normals for lighting. Keep the original normals.

	var arr_mesh: ArrayMesh = mesh_instance.mesh
	arr_mesh.clear_surfaces()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

func _follow_skeleton_position() -> void:
	if not _skeleton:
		return

	# Get attachment point from skeleton
	var attach_transform = Transform3D.IDENTITY

	if _hip_bone_idx >= 0:
		var bone_pose = _skeleton.get_bone_global_pose(_hip_bone_idx)
		attach_transform = _skeleton.global_transform * bone_pose
	elif _spine_bone_idx >= 0:
		var bone_pose = _skeleton.get_bone_global_pose(_spine_bone_idx)
		attach_transform = _skeleton.global_transform * bone_pose

	# Position dress at waist/hip level
	global_position = attach_transform.origin

	# Optionally rotate with the skeleton
	# global_rotation = attach_transform.basis.get_euler()

# Public API to change dress appearance at runtime
func set_colors(primary: Color, secondary: Color, wireframe: Color = Color.WHITE) -> void:
	primary_color = primary
	secondary_color = secondary
	wireframe_color = wireframe
	apply_material()

func set_wave_intensity(amplitude: float, flutter: float) -> void:
	wave_amplitude = amplitude
	flutter_intensity = flutter
	create_dress_mesh()  # Regenerate with new parameters

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## LATENT BUG, FIXED HERE. This method existed as `pass`: the artifact advertised a
## configuration hook and silently discarded every key handed to it. It now stores the
## config as metadata in the family's shape and re-reads. No shipped placement carries
## any config on this token, so the change is off the default path either way.
func apply_grid_config(config: Dictionary) -> void:
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	var was: String = wearer
	_read_meta_overrides()
	# Rebuild only when the word actually changed AND the deferred _initialize has
	# already built once — otherwise _initialize picks the new value up on its own pass.
	if _initialized and wearer != was:
		_teardown_wearer()
		_build_wearer()


func _read_meta_overrides() -> void:
	if has_meta("config_wearer"):
		var s: String = str(get_meta("config_wearer")).strip_edges().to_lower()
		wearer = s if WEARERS.has(s) else wearer


# ── wearer: what the garment hangs on ───────────────────────────────────────
# One host node, appended last; the dress mesh is never touched. All geometry is sized
# from the same exports the dress reads (waist_radius, hem_radius, dress_length), so a
# resized costume keeps a fitted wearer. Deterministic — no randf anywhere in this file.

const WEARER_HOST := "WearerStage"

# The wearer's palette: canvas for the atelier, skin-green and hat-black for the figure,
# warm wood and steel for the wardrobe.
const CANVAS := Color(0.78, 0.72, 0.62)
const SKIN_GREEN := Color(0.30, 0.55, 0.30)
const HAT_BLACK := Color(0.05, 0.05, 0.07)
const WOOD := Color(0.45, 0.30, 0.18)
const STEEL := Color(0.55, 0.57, 0.60)

var _wearer_host: Node3D


func _build_wearer() -> void:
	if wearer == "none" or not WEARERS.has(wearer):
		return                        # the legacy lineage builds nothing at all
	_wearer_host = Node3D.new()
	_wearer_host.name = WEARER_HOST
	add_child(_wearer_host)
	match wearer:
		"hanger":
			_wearer_hanger()
		"form":
			_wearer_form()
		"figure":
			_wearer_figure()
		_:
			pass


func _teardown_wearer() -> void:
	var old: Node = get_node_or_null(WEARER_HOST)
	if old != null:
		remove_child(old)
		old.queue_free()
	_wearer_host = null


## HANGER — the wardrobe. A wooden hanger's two sloped arms carry the waist, a steel
## hook loops over a rail, and the rail's drop rods rise out of the top of the frame:
## a costume between performances, the body merely expected.
func _wearer_hanger() -> void:
	var wood_mat := _support_mat(WOOD, 0.75, 0.0, 0.0)
	var steel_mat := _support_mat(STEEL, 0.35, 0.85, 0.0)
	var arm_len: float = maxf(waist_radius * 1.9, 0.24)
	for sx in [-1.0, 1.0]:
		var f: float = float(sx)
		var arm := BoxMesh.new()
		arm.size = Vector3(arm_len, 0.035, 0.022)
		var mi := MeshInstance3D.new()
		mi.mesh = arm
		mi.material_override = wood_mat
		mi.position = Vector3(f * arm_len * 0.46, 0.055, 0)
		mi.rotation_degrees = Vector3(0, 0, f * -12.0)
		_wearer_host.add_child(mi)
	# The hook: a short riser and an open steel loop above it.
	_support_cylinder(steel_mat, 0.008, 0.10, Vector3(0, 0.14, 0), Vector3.ZERO)
	var loop := TorusMesh.new()
	loop.inner_radius = 0.030
	loop.outer_radius = 0.048
	var hook := MeshInstance3D.new()
	hook.mesh = loop
	hook.material_override = steel_mat
	hook.position = Vector3(0, 0.23, 0)
	# Default torus lies flat with its hole along Y; rolled about Z the hole runs
	# along X, so the rail threads the loop.
	hook.rotation_degrees = Vector3(0, 0, 90)
	_wearer_host.add_child(hook)
	# The rail the hook hangs from, with drop rods rising out of frame.
	_support_cylinder(steel_mat, 0.018, 1.2, Vector3(0, 0.27, 0), Vector3(0, 0, 90))
	for rx in [-0.55, 0.55]:
		_support_cylinder(steel_mat, 0.012, 0.62, Vector3(rx, 0.58, 0), Vector3.ZERO)


## FORM — the atelier. A canvas bust above the waist, exactly as much body as the cloth
## requires; a steel pole through the hem to a round base below it.
func _wearer_form() -> void:
	var canvas_mat := _support_mat(CANVAS, 0.92, 0.0, 0.0)
	var steel_mat := _support_mat(STEEL, 0.4, 0.8, 0.0)
	var wood_mat := _support_mat(WOOD, 0.7, 0.0, 0.0)
	var torso_r: float = maxf(waist_radius * 0.78, 0.08)
	# The bust: a capsule torso, a neck, a wooden neck button.
	var torso := CapsuleMesh.new()
	torso.radius = torso_r
	torso.height = torso_r * 2.0 + 0.22
	var tmi := MeshInstance3D.new()
	tmi.mesh = torso
	tmi.material_override = canvas_mat
	tmi.position = Vector3(0, 0.16, 0)
	_wearer_host.add_child(tmi)
	_support_cylinder(canvas_mat, torso_r * 0.38, 0.10, Vector3(0, 0.37, 0), Vector3.ZERO)
	_support_cylinder(wood_mat, torso_r * 0.46, 0.035, Vector3(0, 0.435, 0), Vector3.ZERO)
	# The pole, from inside the skirt down past the hem to the base.
	var hem_y: float = -dress_length
	_support_cylinder(steel_mat, 0.014, dress_length * 0.55 + 0.38, Vector3(0, hem_y * 0.72 - 0.19, 0), Vector3.ZERO)
	_support_cylinder(steel_mat, hem_radius * 0.62, 0.024, Vector3(0, hem_y - 0.40, 0), Vector3.ZERO)


## FIGURE — the performance. Green skin, black pointed hat: a head, neck, shoulders,
## and two arms held just clear of the skirt. Elphaba inside her own mathematics.
func _wearer_figure() -> void:
	var skin := _support_mat(SKIN_GREEN, 0.6, 0.0, 0.18)
	var hat := _support_mat(HAT_BLACK, 0.55, 0.1, 0.0)
	# Head and neck.
	_support_sphere(skin, 0.085, Vector3(0, 0.34, 0), Vector3.ONE)
	_support_cylinder(skin, 0.034, 0.09, Vector3(0, 0.245, 0), Vector3.ZERO)
	# Shoulders: a flattened sphere bridging into the waistline.
	_support_sphere(skin, 0.16, Vector3(0, 0.175, 0), Vector3(1.0, 0.45, 0.62))
	# Arms and hands, angled outward past the skirt's silhouette.
	for sx in [-1.0, 1.0]:
		var f: float = float(sx)
		var arm := CapsuleMesh.new()
		arm.radius = 0.032
		arm.height = 0.40
		var ami := MeshInstance3D.new()
		ami.mesh = arm
		ami.material_override = skin
		ami.position = Vector3(f * 0.235, 0.01, 0)
		ami.rotation_degrees = Vector3(0, 0, f * -24.0)
		_wearer_host.add_child(ami)
		_support_sphere(skin, 0.040, Vector3(f * 0.315, -0.165, 0), Vector3.ONE)
	# The pointed hat: brim disc and cone.
	_support_cylinder(hat, 0.165, 0.016, Vector3(0, 0.402, 0), Vector3.ZERO)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.10
	cone.height = 0.26
	var cmi := MeshInstance3D.new()
	cmi.mesh = cone
	cmi.material_override = hat
	cmi.position = Vector3(0, 0.53, 0)
	cmi.rotation_degrees = Vector3(0, 0, -6.0)
	_wearer_host.add_child(cmi)


# ── wearer helpers ──────────────────────────────────────────────────────────

func _support_mat(c: Color, rough: float, metal: float, glow: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
	return m


func _support_sphere(mat: Material, r: float, pos: Vector3, scl: Vector3) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	_wearer_host.add_child(mi)


func _support_cylinder(mat: Material, r: float, h: float, pos: Vector3, rot_deg: Vector3) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = h
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	_wearer_host.add_child(mi)
