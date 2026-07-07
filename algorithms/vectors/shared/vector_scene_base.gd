extends Node3D

class_name VectorSceneBase

const VECTOR_SCENE := preload("res://commons/primitives/line/line.tscn")
const SLIDER_SCENE := preload("res://commons/interactables/slider_smooth.tscn")  # canonical (was slider_horizontal — jumpy)
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const LaserPointScript = preload("res://commons/primitives/point/laser_point.gd")
# RackPassiveElements has a class_name — reference it globally (no preload needed).
const SCENE_SCALE: float = 0.33

# Canonical screen palette (matches commons/ui/text_screen.gd) — one look for all
# vector-bench text. Static text is BAKED onto the panel; only live numbers are Label3D.
const SCREEN_BG := Color(0.08, 0.10, 0.14)
const SCREEN_TITLE := Color(0.55, 0.75, 1.0)
const SCREEN_BODY := Color(0.78, 0.90, 1.0)

# Size control.
# Default 1.0 reproduces the historical "compact" exhibition size (a 0.5 root
# scale, applied by subclasses via base_scale()). Larger values produce the
# walk-inside XL variants. Delivered through delegate_params -> apply_grid_config.
@export var scale_multiplier: float = 1.0

# When true, vector endpoints are LASER-DRAGGABLE points (moved with the VR
# FunctionPointer ray) instead of near-hand grab spheres — essential for the big
# XL benches where the tips are metres away. Auto-enabled past LASER_AUTO_SCALE.
@export var laser_endpoints: bool = false

# Above this scale_multiplier the tips are genuinely out of arm's reach, so
# laser drag turns on automatically even if laser_endpoints was left false.
# Set to 8.0 (vec tip ~2.5 m+) so the existing scale-5 "walk-inside" exhibits
# keep their near-hand grab; opt in explicitly with laser_endpoints below that.
const LASER_AUTO_SCALE: float = 8.0

# Base root scale that the compact presentation used. The effective root scale a
# subclass should apply is base_scale() == BASE_ROOT_SCALE * scale_multiplier.
const BASE_ROOT_SCALE: float = 0.5

# Set true once a subclass has built its scene, so apply_grid_config() knows it
# must tear down + rebuild rather than letting _ready() build for the first time.
var _scene_built: bool = false

# Shared Resources (Lazy Initialization)
static var _shared_cylinder_mesh: CylinderMesh
static var _shared_cone_mesh: CylinderMesh
static var _shared_sphere_mesh: SphereMesh
static var _shared_ball_mesh: SphereMesh
static var _shared_floor_mesh: PlaneMesh
static var _material_cache: Dictionary = {} # Color (as String) -> StandardMaterial3D

var environment_root: Node3D
var info_root: Node3D

func _ready() -> void:
	environment_root = Node3D.new()
	environment_root.name = "Environment"
	add_child(environment_root)
	info_root = Node3D.new()
	info_root.name = "Info"
	add_child(info_root)
	_init_shared_resources()
	_create_origin_marker()
	# Subclasses build their scene by overriding build_scene(). They still call
	# super._ready() first; the call below runs after that returns. We guard with
	# _scene_built so a subclass that builds inline (legacy) is not double-built.
	if not _scene_built:
		build_scene()
		_scene_built = true

func _init_shared_resources() -> void:
	if _shared_cylinder_mesh == null:
		_shared_cylinder_mesh = CylinderMesh.new()
		_shared_cylinder_mesh.height = 1.0 # Unit height for scaling
		_shared_cylinder_mesh.top_radius = 0.006  # Smaller for exhibition
		_shared_cylinder_mesh.bottom_radius = 0.006
		_shared_cylinder_mesh.radial_segments = 8

	if _shared_cone_mesh == null:
		_shared_cone_mesh = CylinderMesh.new()
		_shared_cone_mesh.height = 0.12  # Smaller arrowhead
		_shared_cone_mesh.bottom_radius = 0.025
		_shared_cone_mesh.top_radius = 0.0
		_shared_cone_mesh.radial_segments = 12

	if _shared_sphere_mesh == null:
		_shared_sphere_mesh = SphereMesh.new()
		_shared_sphere_mesh.radius = 0.5 # Diameter 1.0
		_shared_sphere_mesh.height = 1.0
		_shared_sphere_mesh.radial_segments = 18
		_shared_sphere_mesh.rings = 12

	if _shared_ball_mesh == null:
		_shared_ball_mesh = SphereMesh.new()
		_shared_ball_mesh.radius = 0.5
		_shared_ball_mesh.height = 1.0
		_shared_ball_mesh.radial_segments = 32
		_shared_ball_mesh.rings = 16

	if _shared_floor_mesh == null:
		_shared_floor_mesh = PlaneMesh.new()
		_shared_floor_mesh.size = Vector2(1.0, 1.0) # Scale to size

func _get_shared_material(color: Color, unlit: bool = false) -> StandardMaterial3D:
	var key = str(color) + ("_unlit" if unlit else "_lit")
	if _material_cache.has(key):
		return _material_cache[key]
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	if unlit:
		mat.emission_enabled = true
		mat.emission = color * 0.8
		mat.roughness = 0.2
		mat.metallic = 0.0
	else:
		mat.roughness = 1.0
		mat.metallic = 0.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	
	_material_cache[key] = mat
	return mat

func spawn_vector(origin: Vector3, vector: Vector3, color: Color, name: String, allow_grab: bool = true) -> Node3D:
	var arrow: Node3D = VECTOR_SCENE.instantiate()
	arrow.name = name.replace(" ", "_")
	arrow.position = origin * SCENE_SCALE
	var line_node = arrow.get_node("lineContainer")
	if line_node:
		line_node.set("vector_name", name)
		line_node.set("line_color", color)
	# Swap the near-hand grab spheres for laser-draggable points (same node
	# names, so line.gd and every subclass keep working) BEFORE the line enters
	# the tree, so line.gd's @onready GrabSphere refs resolve to the new nodes.
	if allow_grab and use_laser_endpoints():
		_install_laser_endpoints(line_node, color)
	var start_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere")
	var end_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere2")
	if start_node:
		start_node.position = Vector3.ZERO
	if end_node:
		end_node.position = vector * SCENE_SCALE
	if not allow_grab:
		_disable_grab_sphere(start_node)
		_disable_grab_sphere(end_node)
	elif not use_laser_endpoints():
		# Keep endpoints comfortably grabbable when the scene is enlarged.
		# The root node scale already grows the spheres in world space, but we
		# boost them a little extra so the hit target stays generous at XL size.
		_boost_grab_sphere(start_node)
		_boost_grab_sphere(end_node)
	add_child(arrow)
	return arrow


## Whether this bench should use laser-draggable endpoints — explicit flag, or
## auto-on once the scene is large enough that the tips are unreachable by hand.
func use_laser_endpoints() -> bool:
	return laser_endpoints or scale_multiplier >= LASER_AUTO_SCALE


## Replace a line's GrabSphere/GrabSphere2 with LaserPoint handles, keeping the
## names. The visible radius shrinks as the root scale grows so the world-space
## handle stays a sensible size; the collider stays generous for easy laser hits.
func _install_laser_endpoints(line_node: Node, color: Color) -> void:
	if line_node == null:
		return
	var root_scale: float = maxf(0.001, base_scale().x)
	# Target ~0.10 m visible / ~0.22 m hittable in world space, expressed local.
	var vis_r: float = clampf(0.10 / root_scale, 0.012, 0.06)
	var hit_r: float = clampf(0.22 / root_scale, 0.03, 0.14)
	for child_name in ["GrabSphere", "GrabSphere2"]:
		var old: Node = line_node.get_node_or_null(child_name)
		var keep_pos := Vector3.ZERO
		if old:
			if old is Node3D:
				keep_pos = (old as Node3D).position
			line_node.remove_child(old)
			old.queue_free()
		var lp: Node3D = LaserPointScript.new()
		lp.name = child_name
		lp.set("color", color)
		lp.set("radius", vis_r)
		lp.set("hit_radius", hit_r)
		lp.position = keep_pos
		line_node.add_child(lp)

## Enlarge a grab sphere's collision + visible mesh proportional to
## scale_multiplier so vector endpoints stay easy to grab when the scene is big.
## The local radius starts ~0.06; at scale_multiplier 5 the effective world
## radius is ~0.06 * 0.5 * 5 (root scale) * extra_boost -> well over 0.15 m.
func _boost_grab_sphere(grab_node: Node) -> void:
	if grab_node == null:
		return
	# Only boost beyond the default size; at scale_multiplier 1.0 leave as-is.
	var extra: float = max(1.0, scale_multiplier * 0.6)
	if extra <= 1.0001:
		return
	var collider: CollisionShape3D = grab_node.get_node_or_null("CollisionShape3D")
	if collider and collider.shape is SphereShape3D:
		var shape: SphereShape3D = collider.shape.duplicate()
		shape.radius = 0.06 * extra
		collider.shape = shape
	# Enlarge the visible marker mesh too (snap_point uses a Sphere child).
	var mesh_root := grab_node.get_node_or_null("MeshInstance3D")
	if mesh_root:
		mesh_root.scale = Vector3.ONE * extra

func update_vector(arrow: Node3D, vector: Vector3) -> void:
	if arrow == null:
		return
	var end_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere2")
	if end_node:
		end_node.position = vector * SCENE_SCALE
	var line_container = arrow.get_node_or_null("lineContainer")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()

func get_vector(arrow: Node) -> Vector3:
	if arrow == null:
		return Vector3.ZERO
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	var start_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere")
	var end_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere2")
	if start_node and end_node:
		return (end_node.global_position - start_node.global_position) / (SCENE_SCALE * scale.x)
	return Vector3.ZERO

func create_axes(length: float = 3.0) -> void:
	var axes = [
		{ "dir": Vector3.RIGHT, "color": Color(1.0, 0.2, 0.2, 1.0), "label": "X" },
		{ "dir": Vector3.UP, "color": Color(0.2, 1.0, 0.2, 1.0), "label": "Y" },
		{ "dir": Vector3.BACK, "color": Color(0.2, 0.6, 1.0, 1.0), "label": "Z" }
	]
	for axis_data in axes:
		var axis_root = Node3D.new()
		axis_root.name = "%s_axis" % axis_data.label
		environment_root.add_child(axis_root)
		
		var scaled_length = length * SCENE_SCALE
		
		# Cylinder
		var mesh = MeshInstance3D.new()
		mesh.mesh = _shared_cylinder_mesh
		mesh.material_override = _get_shared_material(axis_data.color, true)
		mesh.transform.basis = _basis_from_direction(axis_data.dir)
		# Scale height to length
		mesh.scale.y = scaled_length
		mesh.position = axis_data.dir * (scaled_length * 0.5)
		axis_root.add_child(mesh)
		
		# Tip
		var tip = MeshInstance3D.new()
		tip.mesh = _shared_cone_mesh
		tip.material_override = _get_shared_material(axis_data.color, true)
		tip.transform.basis = _basis_from_direction(axis_data.dir)
		tip.position = axis_data.dir * scaled_length
		axis_root.add_child(tip)
		
		var label = Label3D.new()
		label.text = axis_data.label
		label.font_size = 32
		label.modulate = axis_data.color
		label.position = axis_data.dir * (scaled_length + 0.25 * SCENE_SCALE)
		label.no_depth_test = true
		label.render_priority = 100
		environment_root.add_child(label)

func create_floor(size: float = 6.0, color: Color = Color(0.1, 0.1, 0.12, 1.0)):
	var floor = MeshInstance3D.new()
	floor.mesh = _shared_floor_mesh
	floor.material_override = _get_shared_material(color, false)
	floor.scale = Vector3(size, 1.0, size) * SCENE_SCALE
	floor.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	floor.position = Vector3(0.0, -0.05, 0.0) * SCENE_SCALE
	environment_root.add_child(floor)

## Creates a unified info canvas: title, hr, two-column table (data | formula).
## Positioned back and up. Returns the live data Label3D for per-frame updates.
func create_info_panel(title: String, position: Vector3, size: Vector2 = Vector2(2.2, 0.8), formula: String = "", description: String = "") -> Label:
	var sc := SCENE_SCALE
	var panel = Node3D.new()
	panel.name = "InfoPanel"
	panel.position = position * sc
	info_root.add_child(panel)

	var w := size.x * sc
	var h := size.y * sc
	var z_front := 0.008 * sc  # Label z-offset in front of backing
	var pad := 0.025 * sc      # Inner padding

	# ── BACKING ──
	var backing = MeshInstance3D.new()
	backing.name = "Backing"
	var box = BoxMesh.new()
	box.size = Vector3(w, h, 0.01 * sc)
	backing.mesh = box
	var back_mat = StandardMaterial3D.new()
	back_mat.albedo_color = Color(SCREEN_BG.r, SCREEN_BG.g, SCREEN_BG.b, 0.94)
	back_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	back_mat.metallic = 0.1
	back_mat.roughness = 0.6
	back_mat.render_priority = -10
	backing.material_override = back_mat
	panel.add_child(backing)
	_add_frame(panel, Vector2(w, h))

	# ── TITLE (baked band, not a floating Label3D) ──
	var title_y := h / 2.0 - pad
	var title_band_h := 0.11 * sc
	var title_mesh := BakedText.make_panel_mesh(
		title.to_upper(), SCREEN_BG.lightened(0.06), SCREEN_TITLE,
		Vector2(w * 0.92, title_band_h), 1400, true)
	if title_mesh:
		title_mesh.name = "TitleLabel"
		title_mesh.position = Vector3(0, title_y - title_band_h * 0.5, z_front)
		panel.add_child(title_mesh)

	# ── HORIZONTAL RULE (accent line below title) ──
	var hr_y := title_y - 0.14 * sc
	var accent = MeshInstance3D.new()
	var accent_box = BoxMesh.new()
	accent_box.size = Vector3(w * 0.85, 0.002 * sc, 0.005 * sc)
	accent.mesh = accent_box
	var accent_mat = StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.4, 0.7, 1.0)
	accent_mat.emission_enabled = true
	accent_mat.emission = Color(0.3, 0.5, 0.8)
	accent_mat.emission_energy_multiplier = 1.5
	accent.material_override = accent_mat
	accent.position = Vector3(0, hr_y, 0.003 * sc)
	panel.add_child(accent)

	# ── TWO-COLUMN TABLE AREA (below hr) ──
	var table_top := hr_y - 0.03 * sc
	var col_gap := 0.02 * sc
	var half_w := w / 2.0
	var left_x := -half_w + pad                  # Left column: data
	var right_x := col_gap                        # Right column: formula

	# Left column: LIVE DATA — a 2D-in-3D text panel (SubViewport 2D Label), so
	# all text in the instrument is 2D-in-3D. Transparent: glyphs over the backing.
	var data_w := (half_w - pad) * 0.96
	var data_h := (h * 0.5 + (hr_y)) - (-h * 0.5 + pad)   # from hr down to bottom pad
	data_h = maxf(0.1, table_top - (-h * 0.5 + pad))
	var data_node := Node3D.new()
	data_node.name = "DataPanel"
	data_node.position = Vector3(left_x + data_w * 0.5, table_top - data_h * 0.5, z_front)
	panel.add_child(data_node)
	var data_label: Label = RackPassiveElements.build_text_panel_2d(
		data_node, Vector2(data_w, data_h), "", Color.WHITE,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true, 0.05)
	data_label.name = "Label"

	# Right column: FORMULA + DESCRIPTION (static — baked, not floating)
	if formula != "" or description != "":
		var right_lines: Array = []
		if formula != "":
			right_lines.append(formula)
		if description != "":
			for dl in description.split("\n"):
				right_lines.append(dl)
		var col_w := half_w - col_gap - pad
		var line_h := 0.055 * sc
		var formula_block := BakedText.make_text_block(
			right_lines, SCREEN_BODY, line_h, col_w, line_h * 0.25, true)
		if formula_block:
			formula_block.name = "FormulaLabel"
			# make_text_block centres lines vertically around origin; nudge to table top.
			formula_block.position = Vector3(
				right_x + col_w * 0.5, table_top - line_h * right_lines.size() * 0.5, z_front)
			panel.add_child(formula_block)

	# Vertical divider between columns
	if formula != "" or description != "":
		var divider = MeshInstance3D.new()
		var div_mesh = BoxMesh.new()
		div_mesh.size = Vector3(0.002 * sc, (h - 0.1 * sc) * 0.6, 0.004 * sc)
		divider.mesh = div_mesh
		divider.material_override = accent_mat  # Reuse accent material
		divider.position = Vector3(col_gap - 0.01 * sc, table_top - (h * 0.15), 0.003 * sc)
		panel.add_child(divider)

	return data_label

func _add_frame(parent: Node3D, size: Vector2) -> void:
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.3, 0.35, 0.4)
	frame_mat.metallic = 0.5
	frame_mat.roughness = 0.4
	
	var thickness = 0.01 * SCENE_SCALE
	var depth = 0.015 * SCENE_SCALE
	var half_w = size.x / 2.0
	var half_h = size.y / 2.0
	
	# Top and bottom edges
	for y_mult in [-1.0, 1.0]:
		var edge = MeshInstance3D.new()
		var edge_box = BoxMesh.new()
		edge_box.size = Vector3(size.x + thickness * 2, thickness, depth)
		edge.mesh = edge_box
		edge.material_override = frame_mat
		edge.position = Vector3(0, half_h * y_mult, 0)
		parent.add_child(edge)
	
	# Left and right edges
	for x_mult in [-1.0, 1.0]:
		var edge = MeshInstance3D.new()
		var edge_box = BoxMesh.new()
		edge_box.size = Vector3(thickness, size.y, depth)
		edge.mesh = edge_box
		edge.material_override = frame_mat
		edge.position = Vector3(half_w * x_mult, 0, 0)
		parent.add_child(edge)

func create_ball(position: Vector3, radius: float = 0.18, mass: float = 1.0, color: Color = Color(0.9, 0.4, 0.8, 1.0)) -> RigidBody3D:
	# Physics-enabled ball with collider and visible mesh
	var body := RigidBody3D.new()
	body.name = "Ball"
	body.position = position * SCENE_SCALE
	body.mass = mass
	body.can_sleep = false
	body.contact_monitor = true
	body.max_contacts_reported = 8

	var scaled_radius = radius * SCENE_SCALE

	var collider := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = scaled_radius
	collider.shape = sphere_shape
	body.add_child(collider)

	var mesh := MeshInstance3D.new()
	mesh.mesh = _shared_ball_mesh
	# Scale mesh to match radius (shared mesh is dia=1, rad=0.5 -> scale=radius*2)
	var scale_factor = scaled_radius * 2.0
	mesh.scale = Vector3.ONE * scale_factor
	
	var material = _get_shared_material(color, false)
	# The original create_ball had emission enabled for the ball. 
	# We can create a custom unlit variant or reuse the lit one and add emission logic?
	# Original: emission enabled, emission = color * 0.3, roughness = 0.3
	# Let's create a custom one-off if it differs, or update _get_shared_material to support this.
	# For now, let's use unlit for ball to keep it glowing as before?
	# Original code: emission = color * 0.3 (dimmer than unlit * 0.8)
	# Let's stick to creating a new material for the ball to match exact style, 
	# or accept slight visual change.
	# Better: Cache it with a specific key suffix
	mesh.material_override = _get_shared_material_custom_emission(color, 0.3)
	
	body.add_child(mesh)

	add_child(body)
	return body

func _get_shared_material_custom_emission(color: Color, emission_mult: float) -> StandardMaterial3D:
	var key = str(color) + "_emit_" + str(emission_mult)
	if _material_cache.has(key):
		return _material_cache[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * emission_mult
	mat.roughness = 0.3
	mat.metallic = 0.0
	_material_cache[key] = mat
	return mat

func _disable_grab_sphere(grab_node: Node) -> void:
	if grab_node == null:
		return
	if grab_node.has_method("set_freeze_enabled"):
		grab_node.set_freeze_enabled(true)
	if grab_node.has_method("set_pickable"):
		grab_node.set_pickable(false)
	if grab_node.has_method("set_process"):
		grab_node.set_process(false)
	if grab_node.has_method("set_physics_process"):
		grab_node.set_physics_process(false)
	var collider: CollisionShape3D = grab_node.get_node_or_null("CollisionShape3D")
	if collider:
		collider.disabled = true
	var mesh = grab_node.get_node_or_null("MeshInstance3D")
	if mesh:
		mesh.visible = false
	var highlight = grab_node.get_node_or_null("HighlightRing")
	if highlight:
		highlight.visible = false
	var label = grab_node.get_node_or_null("Label3D")
	if label:
		label.visible = false

func _create_origin_marker() -> void:
	var mesh = MeshInstance3D.new()
	mesh.mesh = _shared_sphere_mesh
	# Shared sphere radius is 0.5 (dia 1). We want radius 0.05 (dia 0.1). Scale = 0.1.
	# Apply global scale to this too? Yes, likely.
	mesh.scale = Vector3.ONE * 0.1 * SCENE_SCALE
	
	var material = _get_shared_material_custom_emission(Color.WHITE, 0.5)
	mesh.material_override = material
	environment_root.add_child(mesh)

func _build_unlit_material(color: Color) -> StandardMaterial3D:
	# Kept for backward compatibility if needed, but delegating to shared
	return _get_shared_material(color, true)

func _basis_from_direction(direction: Vector3) -> Basis:
	var dir = direction.normalized()
	var up = Vector3.UP
	if abs(dir.dot(up)) > 0.999:
		up = Vector3.FORWARD
	var right = dir.cross(up).normalized()
	if right.length() <= 0.001:
		right = Vector3.RIGHT
		up = right.cross(dir).normalized()
	else:
		up = right.cross(dir).normalized()
	return Basis(right, dir, up)

func get_arrow_start_position(arrow: Node) -> Vector3:
	var node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere")
	if node:
		return node.global_position
	return arrow.global_position

func get_arrow_end_position(arrow: Node) -> Vector3:
	var node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere2")
	if node:
		return node.global_position
	return arrow.global_position

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## A numeric readout housed in a text DISPLAY — a dark bezel + screen (the Braun
## calculator panel from commons/interactables/interactable_demo, RackPassiveElements
## .build_text_display_static), with the live number on it instead of floating bare.
## Returns the Label3D so subclasses keep updating its text every frame.
func create_readout(logical_position: Vector3, color: Color = Color(0.85, 1.0, 0.9, 1.0)) -> Label3D:
	var display := Node3D.new()
	display.name = "ReadoutDisplay"
	display.position = logical_position * SCENE_SCALE
	info_root.add_child(display)

	# Sized for up to two lines of readout (e.g. "k = 1.00\n|k*v| = 1.48").
	var w := 0.60
	var h := 0.28

	# Dark bezel (same palette as the demo text display).
	var bezel := MeshInstance3D.new()
	bezel.name = "ReadoutBezel"
	var bbox := BoxMesh.new()
	bbox.size = Vector3(w + 0.02, h + 0.02, 0.012)
	bezel.mesh = bbox
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.20, 0.18, 0.16)
	bmat.metallic = 0.3
	bmat.roughness = 0.6
	bezel.material_override = bmat
	display.add_child(bezel)

	# Dark screen face.
	var screen := MeshInstance3D.new()
	screen.name = "ReadoutScreen"
	var sbox := BoxMesh.new()
	sbox.size = Vector3(w, h, 0.006)
	screen.mesh = sbox
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.04, 0.05, 0.06)
	smat.roughness = 0.4
	screen.material_override = smat
	screen.position.z = 0.008
	display.add_child(screen)

	# The live number, lit, centred on the screen.
	var label := Label3D.new()
	label.name = "Readout"
	label.text = ""
	label.font_size = 48
	label.modulate = color
	label.no_depth_test = true
	label.render_priority = 110
	label.line_spacing = 0.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.pixel_size = 0.0016
	label.position = Vector3(0, 0, 0.014)
	display.add_child(label)
	return label

## Spawn a horizontal magnitude slider at a logical position (pre-scale) and
## wire its range + label. Returns the slider Node3D (base-typed). The caller
## connects `slider_moved` and reads `get_normalized_value()`.
## param_name: the text under the handle. min_val/max_val: logical range shown.
func create_magnitude_slider(logical_position: Vector3, param_name: String, min_val: float, max_val: float, start_norm: float = 0.5) -> Node3D:
	var slider: Node3D = SLIDER_SCENE.instantiate()
	slider.name = "MagnitudeSlider_" + param_name.replace(" ", "_")
	slider.position = logical_position * SCENE_SCALE
	# slider_smooth is a vertical fader → +90° about Z lays it HORIZONTAL (drag
	# right = bigger), then -25° about X tilts it toward the player. Counter-rotate
	# the value label so the number stays upright (matches ControlPanel.add_slider).
	slider.rotation_degrees = Vector3(-25.0, 0.0, 90.0)
	var _vl := slider.get_node_or_null("Frame/Label3DValue") as Label3D
	if _vl:
		_vl.rotation_degrees.z = -90.0
	add_child(slider)
	# Use dynamic set/call so this works even though `slider` is base-typed and
	# the slider script is not a known class_name at compile time.
	if slider.has_method("set_range"):
		slider.call("set_range", min_val, max_val)
	if slider.has_method("set_param_name"):
		slider.call("set_param_name", param_name)
	if slider.has_method("set_normalized_value"):
		slider.call("set_normalized_value", start_norm)
	return slider

## Effective root scale a subclass should apply to its own `scale`.
## Replaces the old hardcoded Vector3(0.5, 0.5, 0.5).
func base_scale() -> Vector3:
	var s: float = BASE_ROOT_SCALE * scale_multiplier
	return Vector3(s, s, s)

## Subclasses override this to build their whole scene (vectors, gadgets,
## panels, etc). It is invoked from _ready() and re-invoked by rebuild() after a
## scale change. Subclasses should set self.scale = base_scale() at the top.
func build_scene() -> void:
	pass

## Tear down and rebuild the scene at the current scale_multiplier. Used when
## scale_multiplier arrives via apply_grid_config() after _ready() already ran.
func rebuild() -> void:
	# Free everything we created (vectors, gadgets, environment, info, labels).
	for child in get_children():
		# Only free the dynamic content; keep nothing persistent here since
		# environment_root / info_root are recreated in _ready of the base.
		child.queue_free()
	environment_root = null
	info_root = null
	# Re-create the base scaffolding that _ready() normally provides.
	environment_root = Node3D.new()
	environment_root.name = "Environment"
	add_child(environment_root)
	info_root = Node3D.new()
	info_root.name = "Info"
	add_child(info_root)
	_create_origin_marker()
	_scene_built = false
	build_scene()
	_scene_built = true


func apply_grid_config(config: Dictionary) -> void:
	if config == null:
		return
	if config.has("laser_endpoints"):
		laser_endpoints = bool(config["laser_endpoints"])
	if config.has("scale_multiplier"):
		var new_mult: float = float(config["scale_multiplier"])
		if new_mult > 0.0 and not is_equal_approx(new_mult, scale_multiplier):
			scale_multiplier = new_mult
			# If the scene already built at the old size, rebuild at the new one.
			if _scene_built:
				rebuild()
			else:
				scale = base_scale()
